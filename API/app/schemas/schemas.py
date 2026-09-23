from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel


class UserCreate(BaseModel):
    full_name: str
    phone: str
    email: Optional[str] = None
    password: str
    role: str  # passenger / drivers / copilote


class UserOut(BaseModel):
    id: int
    full_name: str
    phone: str
    role: str
    wallet_balance_xaf: int
    class Config:
        from_attributes = True


class LoginPayload(BaseModel):
    phone: str
    password: str


class TokenOut(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserOut


class DriverCreate(BaseModel):
    mode: str          # flexible / taxi
    service_class: Optional[str] = None
    company_type: Optional[str] = None  # copilote only
    vehicle_brand: str
    vehicle_model: str
    vehicle_plate: str


class DriverOut(BaseModel):
    id: int
    mode: str
    service_class: Optional[str]
    company_type: Optional[str]
    vehicle_plate: str
    points: int
    online: bool
    class Config:
        from_attributes = True


class StopIn(BaseModel):
    lat: float
    lng: float
    label: Optional[str] = None


class RideEstimateIn(BaseModel):
    mode: str
    service_class: Optional[str] = None
    origin_lat: float
    origin_lng: float
    destination_lat: float
    destination_lng: float
    places: int = 1
    stops: List[StopIn] = []
    degraded_route: bool = False


class RideEstimateOut(BaseModel):
    base_xaf: int
    stop_supplement_xaf: int
    degraded_supplement_xaf: int
    traffic_supplement_estimate_xaf: int
    total_estimate_xaf: int


class RideCreateOut(BaseModel):
    id: int
    status: str
    total_xaf: int


class WalletTopupIn(BaseModel):
    amount_xaf: int
    channel: str  # orange / mtn / wallet


class DisputeIn(BaseModel):
    ride_id: int
    kind: str
    detail: Optional[str] = None
