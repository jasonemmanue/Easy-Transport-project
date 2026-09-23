from fastapi import APIRouter

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/dashboard")
def dashboard():
    return {
        "active_rides": 126,
        "online_drivers": 412,
        "active_passengers": 2148,
        "daily_revenue_xaf": 1_240_000,
    }


@router.get("/disputes")
def list_disputes():
    return [
        {"id": 4519, "kind": "pause_arret", "status": "open"},
        {"id": 4521, "kind": "pause_arret", "status": "passenger_contest"},
    ]


@router.post("/disputes/{dispute_id}/resolve")
def resolve_dispute(dispute_id: int, valid: bool):
    return {"dispute_id": dispute_id, "valid": valid, "resolved": True}


@router.post("/pricing")
def update_pricing(commission_rate: float | None = None, stop_supplement_xaf: int | None = None):
    return {"commission_rate": commission_rate, "stop_supplement_xaf": stop_supplement_xaf, "updated": True}
