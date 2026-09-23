from datetime import datetime
from enum import Enum

from sqlalchemy import String, Integer, Float, Boolean, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base


class UserRole(str, Enum):
    passenger = "passenger"
    drivers = "drivers"
    copilote = "copilote"
    admin = "admin"


class EasyMode(str, Enum):
    flexible = "flexible"
    taxi = "taxi"


class ServiceClass(str, Enum):
    eco = "eco"
    serenity = "serenity"
    prestige = "prestige"


class RideStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    in_progress = "in_progress"
    completed = "completed"
    cancelled = "cancelled"


class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(primary_key=True)
    full_name: Mapped[str] = mapped_column(String(120))
    phone: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    email: Mapped[str | None] = mapped_column(String(120), nullable=True, unique=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    role: Mapped[UserRole] = mapped_column(SAEnum(UserRole))
    wallet_balance_xaf: Mapped[int] = mapped_column(Integer, default=0)
    home_address: Mapped[str | None] = mapped_column(String(255), nullable=True)
    home_lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    home_lng: Mapped[float | None] = mapped_column(Float, nullable=True)
    rating_avg: Mapped[float] = mapped_column(Float, default=5.0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Driver(Base):
    __tablename__ = "drivers"
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), unique=True)
    mode: Mapped[EasyMode] = mapped_column(SAEnum(EasyMode))
    service_class: Mapped[ServiceClass | None] = mapped_column(SAEnum(ServiceClass), nullable=True)
    vehicle_brand: Mapped[str] = mapped_column(String(80))
    vehicle_model: Mapped[str] = mapped_column(String(80))
    vehicle_plate: Mapped[str] = mapped_column(String(20), unique=True)
    documents_validated: Mapped[bool] = mapped_column(Boolean, default=False)
    points: Mapped[int] = mapped_column(Integer, default=80)
    weekly_goal: Mapped[int] = mapped_column(Integer, default=50)
    weekly_progress: Mapped[int] = mapped_column(Integer, default=0)
    online: Mapped[bool] = mapped_column(Boolean, default=False)
    company_type: Mapped[str | None] = mapped_column(String(80), nullable=True)  # copilote
    subscription_active_until: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    user: Mapped[User] = relationship("User")


class Zone(Base):
    __tablename__ = "zones"
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(120))
    district: Mapped[str] = mapped_column(String(120))
    lat: Mapped[float] = mapped_column(Float)
    lng: Mapped[float] = mapped_column(Float)
    capacity: Mapped[int] = mapped_column(Integer, default=6)


class DegradedRoad(Base):
    __tablename__ = "degraded_roads"
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(160))
    district: Mapped[str] = mapped_column(String(120))
    severity_percent: Mapped[int] = mapped_column(Integer, default=5)  # 5, 10, 15
    validated: Mapped[bool] = mapped_column(Boolean, default=False)


class Ride(Base):
    __tablename__ = "rides"
    id: Mapped[int] = mapped_column(primary_key=True)
    passenger_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    driver_id: Mapped[int | None] = mapped_column(ForeignKey("drivers.id"), nullable=True)
    mode: Mapped[EasyMode] = mapped_column(SAEnum(EasyMode))
    service_class: Mapped[ServiceClass | None] = mapped_column(SAEnum(ServiceClass), nullable=True)
    status: Mapped[RideStatus] = mapped_column(SAEnum(RideStatus), default=RideStatus.pending)
    places: Mapped[int] = mapped_column(Integer, default=1)
    origin_lat: Mapped[float] = mapped_column(Float)
    origin_lng: Mapped[float] = mapped_column(Float)
    destination_lat: Mapped[float] = mapped_column(Float)
    destination_lng: Mapped[float] = mapped_column(Float)
    base_price_xaf: Mapped[int] = mapped_column(Integer, default=0)
    stop_supplement_xaf: Mapped[int] = mapped_column(Integer, default=0)
    degraded_supplement_xaf: Mapped[int] = mapped_column(Integer, default=0)
    traffic_supplement_xaf: Mapped[int] = mapped_column(Integer, default=0)
    pause_supplement_xaf: Mapped[int] = mapped_column(Integer, default=0)
    total_xaf: Mapped[int] = mapped_column(Integer, default=0)
    commission_xaf: Mapped[int] = mapped_column(Integer, default=0)
    payment_mode: Mapped[str] = mapped_column(String(30), default="wallet")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class RideStop(Base):
    __tablename__ = "ride_stops"
    id: Mapped[int] = mapped_column(primary_key=True)
    ride_id: Mapped[int] = mapped_column(ForeignKey("rides.id"))
    order_index: Mapped[int] = mapped_column(Integer)
    lat: Mapped[float] = mapped_column(Float)
    lng: Mapped[float] = mapped_column(Float)
    label: Mapped[str | None] = mapped_column(String(160), nullable=True)
    is_impromptu: Mapped[bool] = mapped_column(Boolean, default=False)  # Pause Arret


class WalletTx(Base):
    __tablename__ = "wallet_txs"
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    amount_xaf: Mapped[int] = mapped_column(Integer)
    kind: Mapped[str] = mapped_column(String(30))  # topup / ride / refund / commission
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Dispute(Base):
    __tablename__ = "disputes"
    id: Mapped[int] = mapped_column(primary_key=True)
    ride_id: Mapped[int] = mapped_column(ForeignKey("rides.id"))
    kind: Mapped[str] = mapped_column(String(60))  # pause_arret / route / rating
    status: Mapped[str] = mapped_column(String(30), default="open")
    detail: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
