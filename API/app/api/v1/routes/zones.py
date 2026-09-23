from fastapi import APIRouter

router = APIRouter(prefix="/zones", tags=["zones"])

_MOCK_ZONES = [
    {"id": 1, "name": "Akwa - Rue Joss", "district": "Akwa", "lat": 4.052, "lng": 9.702, "capacity": 8},
    {"id": 2, "name": "Bonapriso - Boulevard", "district": "Bonapriso", "lat": 4.037, "lng": 9.687, "capacity": 6},
]


@router.get("/")
def list_zones():
    return _MOCK_ZONES


@router.get("/nearest")
def nearest(lat: float, lng: float):
    return _MOCK_ZONES[:1]
