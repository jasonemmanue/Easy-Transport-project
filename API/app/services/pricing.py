"""Moteur de tarification Carlinq v1.2.

Prix = base (distance x tarif/km x coefficient de classe, plancher par mode)
     + places supplementaires + supplement par arret + route degradee (Flexible)
     + embouteillage + Pause Arret (calcules pendant la course).
Commission : pourcentage de la configuration (8 %) sur le total.
Tous les montants sont des entiers XAF.
"""
from dataclasses import dataclass
from math import asin, ceil, cos, radians, sin, sqrt

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import DegradedRoad
from app.services.settings import PricingConfig

Point = tuple[float, float]


def haversine_km(a: Point, b: Point) -> float:
    lat1, lng1, lat2, lng2 = map(radians, [a[0], a[1], b[0], b[1]])
    h = sin((lat2 - lat1) / 2) ** 2 + cos(lat1) * cos(lat2) * sin((lng2 - lng1) / 2) ** 2
    return 2 * 6371.0 * asin(sqrt(h))


def route_points(pickup: Point, stops: list[Point], destination: Point) -> list[Point]:
    return [pickup, *stops, destination]


def route_distance_km(points: list[Point]) -> float:
    return sum(haversine_km(points[i], points[i + 1]) for i in range(len(points) - 1))


def validated_roads(db: Session) -> list[dict]:
    """Routes degradees validees (cache Redis, invalide a chaque modification admin)."""
    from app.core import cache

    def load():
        rows = db.execute(select(DegradedRoad).where(DegradedRoad.validated.is_(True))
                          .order_by(DegradedRoad.district)).scalars().all()
        return [{"id": r.id, "name": r.name, "district": r.district, "lat": r.lat, "lng": r.lng,
                 "radius_m": r.radius_m, "severity_percent": r.severity_percent, "validated": r.validated}
                for r in rows]

    return cache.get_or_set("roads:validated", load)


def degraded_percent_for(db: Session, points: list[Point]) -> int:
    """Plus forte severite des troncons degrades valides traverses (echantillonnage)."""
    roads = validated_roads(db)
    if not roads:
        return 0
    samples: list[Point] = []
    for i in range(len(points) - 1):
        a, b = points[i], points[i + 1]
        for k in range(11):  # 10 segments par troncon d'itineraire
            t = k / 10
            samples.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
    worst = 0
    for road in roads:
        if any(haversine_km(p, (road["lat"], road["lng"])) * 1000 <= road["radius_m"] for p in samples):
            worst = max(worst, road["severity_percent"])
    return worst


@dataclass
class Quote:
    distance_km: float
    base_xaf: int
    places_supplement_xaf: int
    stop_supplement_per_stop_xaf: int
    stop_supplement_xaf: int
    degraded_percent: int
    degraded_supplement_xaf: int
    total_xaf: int
    commission_xaf: int


def quote(cfg: PricingConfig, *, mode: str, service_class: str | None, distance_km: float,
          stops_count: int, places: int, degraded_percent: int) -> Quote:
    coef = cfg.class_coefficients.get(service_class or "eco", 1.0) if mode == "flexible" else 1.0
    base = max(round(distance_km * cfg.rate_per_km_xaf[mode] * coef), cfg.min_fare_xaf[mode])
    places_sup = (max(places, 1) - 1) * (base * cfg.extra_place_percent // 100)
    per_stop = cfg.stop_supplement_xaf[mode]
    stop_sup = per_stop * stops_count
    # Route degradee : automatique en Carlinq Flexible uniquement.
    degraded = degraded_percent if mode == "flexible" else 0
    degraded_sup = base * degraded // 100
    total = base + places_sup + stop_sup + degraded_sup
    return Quote(
        distance_km=round(distance_km, 2),
        base_xaf=base,
        places_supplement_xaf=places_sup,
        stop_supplement_per_stop_xaf=per_stop,
        stop_supplement_xaf=stop_sup,
        degraded_percent=degraded,
        degraded_supplement_xaf=degraded_sup,
        total_xaf=total,
        commission_xaf=commission(cfg, total),
    )


def commission(cfg: PricingConfig, total_xaf: int) -> int:
    return total_xaf * cfg.commission_percent // 100


def per_minute_supplement(seconds: int, rate_per_minute: int, tolerance_seconds: int = 0) -> int:
    """Supplement a la minute entamee, au-dela d'une tolerance gratuite."""
    billable = seconds - tolerance_seconds
    return 0 if billable <= 0 else ceil(billable / 60) * rate_per_minute
