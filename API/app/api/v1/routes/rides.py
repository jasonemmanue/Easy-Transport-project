from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.schemas import RideEstimateIn, RideEstimateOut
from app.services.pricing import estimate_ride_price

router = APIRouter(prefix="/rides", tags=["rides"])


@router.post("/estimate", response_model=RideEstimateOut)
def estimate(payload: RideEstimateIn):
    result = estimate_ride_price(
        mode=payload.mode,
        service_class=payload.service_class,
        origin=(payload.origin_lat, payload.origin_lng),
        destination=(payload.destination_lat, payload.destination_lng),
        stops=[(s.lat, s.lng) for s in payload.stops],
        places=payload.places,
        degraded_route=payload.degraded_route,
    )
    return RideEstimateOut(**result)


@router.post("/{ride_id}/accept")
def accept_ride(ride_id: int, db: Session = Depends(get_db)):
    # TODO : verifier chauffeur, updater status, notifier via websocket
    return {"ride_id": ride_id, "status": "accepted"}


@router.post("/{ride_id}/pause-arret")
def declare_pause_arret(ride_id: int, lat: float, lng: float):
    return {"ride_id": ride_id, "declared_at_lat": lat, "declared_at_lng": lng, "chronometer_started": True}


@router.post("/{ride_id}/pause-arret/resume")
def resume_pause_arret(ride_id: int, duration_seconds: int):
    supplement = duration_seconds * 5  # 5 XAF / seconde exemple
    return {"ride_id": ride_id, "supplement_xaf": supplement}


@router.post("/{ride_id}/traffic")
def declare_traffic(ride_id: int, minutes: int):
    return {"ride_id": ride_id, "traffic_supplement_xaf": minutes * 60}


@router.post("/{ride_id}/complete")
def complete_ride(ride_id: int, total_xaf: int):
    from app.services.pricing import compute_commission
    return {"ride_id": ride_id, "total_xaf": total_xaf, "commission_xaf": compute_commission(total_xaf)}
