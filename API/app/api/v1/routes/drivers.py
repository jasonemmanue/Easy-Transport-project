from fastapi import APIRouter

router = APIRouter(prefix="/drivers", tags=["drivers"])


@router.post("/register")
def register_driver(mode: str, vehicle_plate: str):
    return {"mode": mode, "vehicle_plate": vehicle_plate, "status": "pending_validation"}


@router.post("/{driver_id}/online")
def set_online(driver_id: int, online: bool):
    return {"driver_id": driver_id, "online": online}


@router.post("/{driver_id}/routes")
def save_route(driver_id: int, slot: int, name: str):
    if slot not in (1, 2, 3):
        return {"error": "Only 3 daily route slots allowed"}
    return {"driver_id": driver_id, "slot": slot, "name": name}


@router.get("/{driver_id}/points")
def get_points(driver_id: int):
    return {"driver_id": driver_id, "points": 82, "max": 100}
