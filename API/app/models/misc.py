"""Portefeuille, zones, routes degradees, litiges, configuration, audit, notifications."""
from datetime import datetime

from sqlalchemy import JSON, Boolean, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.session import Base
from app.models.base import TimestampMixin, pg_enum
from app.models.enums import DisputeStatus, ReportStatus


class WalletTx(TimestampMixin, Base):
    """Ecriture du portefeuille (grand livre) : jamais modifiee ni supprimee."""

    __tablename__ = "wallet_txs"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    amount_xaf: Mapped[int] = mapped_column(Integer)  # signe : + credit, - debit
    balance_after_xaf: Mapped[int] = mapped_column(Integer)
    # topup / withdrawal / ride_payment / ride_earning / commission /
    # cancellation_fee / refund / goal_bonus / goal_share / premium / adjustment
    kind: Mapped[str] = mapped_column(String(30), index=True)
    label: Mapped[str | None] = mapped_column(String(200), nullable=True)
    channel: Mapped[str | None] = mapped_column(String(20), nullable=True)  # orange_money / mtn_momo
    ride_id: Mapped[int | None] = mapped_column(ForeignKey("rides.id"), nullable=True)
    goal_settlement_id: Mapped[int | None] = mapped_column(ForeignKey("goal_settlements.id"), nullable=True)


class Zone(TimestampMixin, Base):
    """Zone de stationnement Carlinq Taxi (bordure de route)."""

    __tablename__ = "zones"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(120))
    district: Mapped[str] = mapped_column(String(120), index=True)
    city: Mapped[str] = mapped_column(String(80), default="Douala")
    lat: Mapped[float] = mapped_column(Float)
    lng: Mapped[float] = mapped_column(Float)
    capacity: Mapped[int] = mapped_column(Integer, default=6)
    opening_hours: Mapped[str] = mapped_column(String(40), default="24h/24")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class DegradedRoad(TimestampMixin, Base):
    """Troncon de route degradee (supplement +5/+10/+15% en Carlinq Flexible)."""

    __tablename__ = "degraded_roads"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(160))
    district: Mapped[str] = mapped_column(String(120))
    lat: Mapped[float] = mapped_column(Float)
    lng: Mapped[float] = mapped_column(Float)
    radius_m: Mapped[int] = mapped_column(Integer, default=300)
    severity_percent: Mapped[int] = mapped_column(Integer, default=5)  # 5 / 10 / 15
    validated: Mapped[bool] = mapped_column(Boolean, default=True)


class RoadReport(TimestampMixin, Base):
    """Signalement de route degradee par un chauffeur (valide par un admin)."""

    __tablename__ = "road_reports"

    id: Mapped[int] = mapped_column(primary_key=True)
    driver_id: Mapped[int] = mapped_column(ForeignKey("drivers.id"), index=True)
    district: Mapped[str | None] = mapped_column(String(120), nullable=True)
    lat: Mapped[float] = mapped_column(Float)
    lng: Mapped[float] = mapped_column(Float)
    suggested_percent: Mapped[int] = mapped_column(Integer)
    status: Mapped[ReportStatus] = mapped_column(pg_enum(ReportStatus, "report_status"), default=ReportStatus.pending)
    degraded_road_id: Mapped[int | None] = mapped_column(ForeignKey("degraded_roads.id"), nullable=True)
    reviewed_by: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)


class Dispute(TimestampMixin, Base):
    __tablename__ = "disputes"

    id: Mapped[int] = mapped_column(primary_key=True)
    ride_id: Mapped[int] = mapped_column(ForeignKey("rides.id"), index=True)
    kind: Mapped[str] = mapped_column(String(40))  # pause_arret / price / behaviour / other
    opened_by: Mapped[int] = mapped_column(ForeignKey("users.id"))
    description: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    status: Mapped[DisputeStatus] = mapped_column(pg_enum(DisputeStatus, "dispute_status"), default=DisputeStatus.open, index=True)
    refund_xaf: Mapped[int] = mapped_column(Integer, default=0)
    points_penalty: Mapped[int] = mapped_column(Integer, default=0)
    resolution_note: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    resolved_by: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class AppSetting(Base):
    """Regles metier modifiables a chaud (cle : pricing, goals)."""

    __tablename__ = "app_settings"

    key: Mapped[str] = mapped_column(String(40), primary_key=True)
    value: Mapped[dict] = mapped_column(JSONB)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    updated_by: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)


class AuditLog(TimestampMixin, Base):
    __tablename__ = "audit_logs"

    id: Mapped[int] = mapped_column(primary_key=True)
    actor_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True, index=True)
    action: Mapped[str] = mapped_column(String(80), index=True)
    entity: Mapped[str] = mapped_column(String(40))
    entity_id: Mapped[str | None] = mapped_column(String(40), nullable=True)
    before: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    after: Mapped[dict | None] = mapped_column(JSONB, nullable=True)


class Notification(TimestampMixin, Base):
    __tablename__ = "notifications"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    kind: Mapped[str] = mapped_column(String(40))
    title: Mapped[str] = mapped_column(String(160))
    body: Mapped[str] = mapped_column(String(500))
    data: Mapped[dict] = mapped_column(JSON, default=dict)
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class PushCampaign(TimestampMixin, Base):
    __tablename__ = "push_campaigns"

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(160))
    body: Mapped[str] = mapped_column(String(500))
    audience: Mapped[dict] = mapped_column(JSON, default=dict)  # {role, mode}
    recipients: Mapped[int] = mapped_column(Integer, default=0)
    created_by: Mapped[int] = mapped_column(ForeignKey("users.id"))
