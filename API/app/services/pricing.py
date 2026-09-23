"""Pricing engine EasyTransport v1.2.

Prix total = tarif de base + supplement arrets + supplement route degradee
             + supplement embouteillage + supplement Pause Arret
Commission 8% preleveee sur le total (v1.2 sect. 3.1).
"""
from math import radians, sin, cos, asin, sqrt

from app.core.config import settings

CLASS_COEF = {"eco": 1.0, "serenity": 1.3, "prestige": 1.7}
RATE_PER_KM_XAF = {"flexible": 350, "taxi": 250}
STOP_SUPPLEMENT_XAF = 300
IMPROMPTU_SUPPLEMENT_XAF = 500
TRAFFIC_RATE_PER_MINUTE_XAF = 60


def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371.0
    lat1, lng1, lat2, lng2 = map(radians, [lat1, lng1, lat2, lng2])
    dlat = lat2 - lat1
    dlng = lng2 - lng1
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlng / 2) ** 2
    return 2 * r * asin(sqrt(a))


def estimate_ride_price(
    mode: str,
    service_class: str | None,
    origin: tuple[float, float],
    destination: tuple[float, float],
    stops: list[tuple[float, float]],
    places: int,
    degraded_route: bool,
) -> dict:
    distance_km = haversine_km(*origin, *destination)
    for i in range(len(stops)):
        prev = origin if i == 0 else stops[i - 1]
        distance_km += haversine_km(*prev, *stops[i])
    if stops:
        distance_km += haversine_km(*stops[-1], *destination)

    base_rate = RATE_PER_KM_XAF.get(mode, 350)
    coef = CLASS_COEF.get(service_class or "eco", 1.0) if mode == "flexible" else 1.0
    base_xaf = int(distance_km * base_rate * coef)

    stop_supplement_xaf = STOP_SUPPLEMENT_XAF * len(stops)
    degraded_supplement_xaf = int(base_xaf * 0.10) if degraded_route else 0
    traffic_estimate_xaf = int(3 * TRAFFIC_RATE_PER_MINUTE_XAF)  # 3 min average

    total = (base_xaf + stop_supplement_xaf + degraded_supplement_xaf) * max(places, 1)
    return {
        "base_xaf": base_xaf,
        "stop_supplement_xaf": stop_supplement_xaf,
        "degraded_supplement_xaf": degraded_supplement_xaf,
        "traffic_supplement_estimate_xaf": traffic_estimate_xaf,
        "total_estimate_xaf": total,
    }


def compute_commission(total_xaf: int) -> int:
    return int(total_xaf * settings.COMMISSION_RATE)
