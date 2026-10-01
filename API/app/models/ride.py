from datetime import datetime

from sqlalchemy import (
    JSON, CheckConstraint, DateTime, Float, ForeignKey, Integer, String, UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base
from app.models.base import TimestampMixin, pg_enum
from app.models.enums import CarlinqMode, PaymentMethod, RideStatus, ServiceClass


class Ride(TimestampMixin, Base):
    __tablename__ = "rides"
    __table_args__ = (CheckConstraint("places BETWEEN 1 AND 4", name="ck_ride_places"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    passenger_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    driver_id: Mapped[int | None] = mapped_column(ForeignKey("drivers.id"), nullable=True, index=True)

    mode: Mapped[CarlinqMode] = mapped_column(pg_enum(CarlinqMode, "carlinq_mode"))
    service_class: Mapped[ServiceClass | None] = mapped_column(
        pg_enum(ServiceClass, "service_class"), nullable=True
    )
    status: Mapped[RideStatus] = mapped_column(
        pg_enum(RideStatus, "ride_status"), default=RideStatus.pending, index=True
    )
    places: Mapped[int] = mapped_column(Integer, default=1)
    taxi_zone_id: Mapped[int | None] = mapped_column(ForeignKey("zones.id"), nullable=True)

    pickup_label: Mapped[str | None] = mapped_column(String(200), nullable=True)
    pickup_lat: Mapped[float] = mapped_column(Float)
    pickup_lng: Mapped[float] = mapped_column(Float)
    destination_label: Mapped[str | None] = mapped_column(String(200), nullable=True)
    destination_lat: Mapped[float] = mapped_column(Float)
    destination_lng: Mapped[float] = mapped_column(Float)
    distance_km: Mapped[float] = mapped_column(Float, default=0)

    # Detail du prix (entiers XAF)
    base_xaf: Mapped[int] = mapped_column(Integer, default=0)
    places_supplement_xaf: Mapped[int] = mapped_column(Integer, default=0)
    stop_supplement_xaf: Mapped[int] = mapped_column(Integer, default=0)
    degraded_percent: Mapped[int] = mapped_column(Integer, default=0)
    degraded_supplement_xaf: Mapped[int] = mapped_column(Integer, default=0)
    traffic_supplement_xaf: Mapped[int] = mapped_column(Integer, default=0)
    pause_supplement_xaf: Mapped[int] = mapped_column(Integer, default=0)
    total_xaf: Mapped[int] = mapped_column(Integer, default=0)
    commission_xaf: Mapped[int] = mapped_column(Integer, default=0)
    driver_earning_xaf: Mapped[int] = mapped_column(Integer, default=0)
    cancellation_fee_xaf: Mapped[int] = mapped_column(Integer, default=0)

    payment_method: Mapped[PaymentMethod] = mapped_column(pg_enum(PaymentMethod, "payment_method"))
    payment_status: Mapped[str] = mapped_column(String(20), default="pending")  # pending/paid/declared

    eta_seconds: Mapped[int | None] = mapped_column(Integer, nullable=True)
    accepted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    cancelled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    cancelled_by: Mapped[str | None] = mapped_column(String(20), nullable=True)  # passenger/driver/admin
    cancel_reason: Mapped[str | None] = mapped_column(String(300), nullable=True)

    stops = relationship("RideStop", order_by="RideStop.order_index", cascade="all, delete-orphan")
    pauses = relationship("RidePause", order_by="RidePause.id")
    traffic_events = relationship("TrafficEvent", order_by="TrafficEvent.id")
    driver = relationship("Driver")
    passenger = relationship("User")

    # Resume des participants (fiche chauffeur cote passager, et inversement).
    @property
    def driver_name(self) -> str | None:
        return self.driver.user.full_name if self.driver else None

    @property
    def driver_rating(self) -> float | None:
        return self.driver.user.rating_avg if self.driver else None

    @property
    def vehicle(self) -> str | None:
        if not self.driver:
            return None
        d = self.driver
        return " ".join(x for x in (d.vehicle_brand, d.vehicle_model, d.vehicle_color) if x)

    @property
    def vehicle_plate(self) -> str | None:
        return self.driver.vehicle_plate if self.driver else None

    @property
    def passenger_name(self) -> str:
        return self.passenger.full_name

    @property
    def passenger_rating(self) -> float:
        return self.passenger.rating_avg


class RideStop(Base):
    __tablename__ = "ride_stops"

    id: Mapped[int] = mapped_column(primary_key=True)
    ride_id: Mapped[int] = mapped_column(ForeignKey("rides.id", ondelete="CASCADE"), index=True)
    order_index: Mapped[int] = mapped_column(Integer)
    label: Mapped[str | None] = mapped_column(String(200), nullable=True)
    lat: Mapped[float] = mapped_column(Float)
    lng: Mapped[float] = mapped_column(Float)
    supplement_xaf: Mapped[int] = mapped_column(Integer, default=0)
    passed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class RidePause(Base):
    """Pause Arret : chronometre serveur, conserve indefiniment (arbitrage)."""

    __tablename__ = "ride_pauses"

    id: Mapped[int] = mapped_column(primary_key=True)
    ride_id: Mapped[int] = mapped_column(ForeignKey("rides.id"), index=True)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    lat: Mapped[float] = mapped_column(Float)
    lng: Mapped[float] = mapped_column(Float)
    supplement_xaf: Mapped[int] = mapped_column(Integer, default=0)


class TrafficEvent(Base):
    __tablename__ = "traffic_events"

    id: Mapped[int] = mapped_column(primary_key=True)
    ride_id: Mapped[int] = mapped_column(ForeignKey("rides.id"), index=True)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    source: Mapped[str] = mapped_column(String(10), default="manual")  # manual / auto
    supplement_xaf: Mapped[int] = mapped_column(Integer, default=0)


class RideGpsPoint(Base):
    """Trace GPS horodatee : preuve d'arbitrage, jamais supprimee."""

    __tablename__ = "ride_gps_points"

    id: Mapped[int] = mapped_column(primary_key=True)
    ride_id: Mapped[int] = mapped_column(ForeignKey("rides.id"), index=True)
    lat: Mapped[float] = mapped_column(Float)
    lng: Mapped[float] = mapped_column(Float)
    speed_kmh: Mapped[float | None] = mapped_column(Float, nullable=True)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class RideStatusLog(TimestampMixin, Base):
    """Audit de chaque transition d'etat d'une course."""

    __tablename__ = "ride_status_logs"

    id: Mapped[int] = mapped_column(primary_key=True)
    ride_id: Mapped[int] = mapped_column(ForeignKey("rides.id"), index=True)
    from_status: Mapped[str | None] = mapped_column(String(20), nullable=True)
    to_status: Mapped[str] = mapped_column(String(20))
    actor_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    note: Mapped[str | None] = mapped_column(String(300), nullable=True)


class RideRefusal(TimestampMixin, Base):
    __tablename__ = "ride_refusals"
    __table_args__ = (UniqueConstraint("ride_id", "driver_id", name="uq_refusal_ride_driver"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    ride_id: Mapped[int] = mapped_column(ForeignKey("rides.id"), index=True)
    driver_id: Mapped[int] = mapped_column(ForeignKey("drivers.id"), index=True)
    penalized: Mapped[bool] = mapped_column(default=False)


class RideMessage(TimestampMixin, Base):
    __tablename__ = "ride_messages"

    id: Mapped[int] = mapped_column(primary_key=True)
    ride_id: Mapped[int] = mapped_column(ForeignKey("rides.id"), index=True)
    sender_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    text: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    photo_url: Mapped[str | None] = mapped_column(String(500), nullable=True)


class RideRating(TimestampMixin, Base):
    __tablename__ = "ride_ratings"
    __table_args__ = (
        UniqueConstraint("ride_id", "rater_id", name="uq_rating_ride_rater"),
        CheckConstraint("stars BETWEEN 1 AND 5", name="ck_rating_stars"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    ride_id: Mapped[int] = mapped_column(ForeignKey("rides.id"), index=True)
    rater_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    ratee_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    stars: Mapped[int] = mapped_column(Integer)
    tags: Mapped[list] = mapped_column(JSON, default=list)
    comment: Mapped[str | None] = mapped_column(String(1000), nullable=True)
