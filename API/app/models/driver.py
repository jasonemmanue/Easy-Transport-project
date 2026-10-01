from datetime import date, datetime

from sqlalchemy import (
    JSON, Boolean, Date, DateTime, Float, ForeignKey, Integer, String, UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base
from app.models.base import TimestampMixin, pg_enum
from app.models.enums import CarlinqMode, DocumentStatus, DriverValidation, ServiceClass


class Driver(TimestampMixin, Base):
    """Profil chauffeur (Drivers ou Copilote) rattache a un utilisateur."""

    __tablename__ = "drivers"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True)

    mode: Mapped[CarlinqMode] = mapped_column(pg_enum(CarlinqMode, "carlinq_mode"))
    service_class: Mapped[ServiceClass | None] = mapped_column(
        pg_enum(ServiceClass, "service_class"), nullable=True
    )
    validation_status: Mapped[DriverValidation] = mapped_column(
        pg_enum(DriverValidation, "driver_validation"), default=DriverValidation.pending, index=True
    )

    vehicle_brand: Mapped[str] = mapped_column(String(80))
    vehicle_model: Mapped[str] = mapped_column(String(80))
    vehicle_color: Mapped[str | None] = mapped_column(String(40), nullable=True)
    vehicle_plate: Mapped[str] = mapped_column(String(20), unique=True)
    company_type: Mapped[str | None] = mapped_column(String(80), nullable=True)  # copilote

    points: Mapped[int] = mapped_column(Integer, default=80)
    completed_rides: Mapped[int] = mapped_column(Integer, default=0)

    online: Mapped[bool] = mapped_column(Boolean, default=False)
    lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    lng: Mapped[float | None] = mapped_column(Float, nullable=True)
    location_updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Fenetre de refus quotidienne (remise a zero chaque jour, heure de Douala).
    refusal_day: Mapped[date | None] = mapped_column(Date, nullable=True)
    refusal_seconds_used: Mapped[int] = mapped_column(Integer, default=0)

    premium_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    user = relationship("User", back_populates="driver")


class DriverDocument(TimestampMixin, Base):
    __tablename__ = "driver_documents"

    id: Mapped[int] = mapped_column(primary_key=True)
    driver_id: Mapped[int] = mapped_column(ForeignKey("drivers.id", ondelete="CASCADE"), index=True)
    doc_type: Mapped[str] = mapped_column(String(40))  # cni / permis / carte_grise / assurance
    file_url: Mapped[str] = mapped_column(String(500))
    status: Mapped[DocumentStatus] = mapped_column(
        pg_enum(DocumentStatus, "document_status"), default=DocumentStatus.pending
    )
    rejection_reason: Mapped[str | None] = mapped_column(String(500), nullable=True)
    reviewed_by: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class PointEvent(TimestampMixin, Base):
    """Historique des points chauffeur (source du score, jamais modifie)."""

    __tablename__ = "point_events"

    id: Mapped[int] = mapped_column(primary_key=True)
    driver_id: Mapped[int] = mapped_column(ForeignKey("drivers.id", ondelete="CASCADE"), index=True)
    delta: Mapped[int] = mapped_column(Integer)
    kind: Mapped[str] = mapped_column(String(40))  # ride_completed / goal_achieved / refusal / ...
    reason: Mapped[str | None] = mapped_column(String(300), nullable=True)
    ride_id: Mapped[int | None] = mapped_column(ForeignKey("rides.id"), nullable=True)
    balance_after: Mapped[int] = mapped_column(Integer)


class DriverRoute(TimestampMixin, Base):
    """Itineraire personnalise : 3 slots par jour, valables le jour meme."""

    __tablename__ = "driver_routes"
    __table_args__ = (UniqueConstraint("driver_id", "day", "slot", name="uq_driver_route_slot"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    driver_id: Mapped[int] = mapped_column(ForeignKey("drivers.id", ondelete="CASCADE"), index=True)
    day: Mapped[date] = mapped_column(Date)
    slot: Mapped[int] = mapped_column(Integer)
    origin: Mapped[str] = mapped_column(String(160))
    waypoints: Mapped[list] = mapped_column(JSON, default=list)
    destination: Mapped[str] = mapped_column(String(160))
    avoid_traffic: Mapped[bool] = mapped_column(Boolean, default=True)
    avoid_degraded: Mapped[bool] = mapped_column(Boolean, default=True)
