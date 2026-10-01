"""Objectifs hebdomadaires et partage d'objectif entre chauffeurs.

Principe du partage :
- un chauffeur qui n'atteint pas son objectif (le proprietaire) invite des
  chauffeurs ayant deja atteint le leur (les aidants), avec un pourcentage
  du bonus pour chacun ;
- une fois l'invitation acceptee, les courses de l'aidant (au-dela de son
  propre objectif) sont creditees sur l'objectif partage ;
- au versement, si l'objectif partage est atteint, le bonus est reparti :
  chaque aidant recoit son pourcentage, le proprietaire recoit le reste.
"""
from datetime import date, datetime

from sqlalchemy import (
    CheckConstraint, Date, DateTime, ForeignKey, Integer, String, UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base
from app.models.base import TimestampMixin, pg_enum
from app.models.enums import GoalShareStatus, GoalStatus


class WeeklyGoal(TimestampMixin, Base):
    __tablename__ = "weekly_goals"
    __table_args__ = (
        UniqueConstraint("driver_id", "week_start", name="uq_goal_driver_week"),
        CheckConstraint("target_rides > 0", name="ck_goal_target_positive"),
        CheckConstraint("bonus_xaf >= 0", name="ck_goal_bonus_positive"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    driver_id: Mapped[int] = mapped_column(ForeignKey("drivers.id", ondelete="CASCADE"), index=True)
    week_start: Mapped[date] = mapped_column(Date, index=True)  # lundi, heure de Douala
    target_rides: Mapped[int] = mapped_column(Integer)
    bonus_xaf: Mapped[int] = mapped_column(Integer)

    own_rides: Mapped[int] = mapped_column(Integer, default=0)      # courses du proprietaire
    shared_rides: Mapped[int] = mapped_column(Integer, default=0)   # courses apportees par les aidants

    status: Mapped[GoalStatus] = mapped_column(
        pg_enum(GoalStatus, "goal_status"), default=GoalStatus.active, index=True
    )
    paused_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    pause_used: Mapped[bool] = mapped_column(default=False)
    achieved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    driver = relationship("Driver")
    shares = relationship("GoalShare", back_populates="goal", order_by="GoalShare.id")

    @property
    def progress_rides(self) -> int:
        return self.own_rides + self.shared_rides

    @property
    def driver_name(self) -> str:
        return self.driver.user.full_name


class GoalShare(TimestampMixin, Base):
    """Invitation d'un aidant sur l'objectif d'un proprietaire, avec son pourcentage."""

    __tablename__ = "goal_shares"
    __table_args__ = (
        UniqueConstraint("goal_id", "helper_driver_id", name="uq_share_goal_helper"),
        CheckConstraint("percent BETWEEN 1 AND 99", name="ck_share_percent_range"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    goal_id: Mapped[int] = mapped_column(ForeignKey("weekly_goals.id", ondelete="CASCADE"), index=True)
    helper_driver_id: Mapped[int] = mapped_column(ForeignKey("drivers.id", ondelete="CASCADE"), index=True)
    percent: Mapped[int] = mapped_column(Integer)
    status: Mapped[GoalShareStatus] = mapped_column(
        pg_enum(GoalShareStatus, "goal_share_status"), default=GoalShareStatus.pending, index=True
    )
    contributed_rides: Mapped[int] = mapped_column(Integer, default=0)
    message: Mapped[str | None] = mapped_column(String(300), nullable=True)
    responded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    goal = relationship("WeeklyGoal", back_populates="shares")
    helper = relationship("Driver")


class GoalRideCredit(TimestampMixin, Base):
    """Trace de l'objectif credite par chaque course terminee (une ligne par course)."""

    __tablename__ = "goal_ride_credits"

    id: Mapped[int] = mapped_column(primary_key=True)
    ride_id: Mapped[int] = mapped_column(ForeignKey("rides.id"), unique=True)
    driver_id: Mapped[int] = mapped_column(ForeignKey("drivers.id"), index=True)  # qui a conduit
    goal_id: Mapped[int] = mapped_column(ForeignKey("weekly_goals.id"), index=True)
    share_id: Mapped[int | None] = mapped_column(ForeignKey("goal_shares.id"), nullable=True)


class GoalSettlement(TimestampMixin, Base):
    """Versement du bonus d'un objectif (unique par objectif : idempotence)."""

    __tablename__ = "goal_settlements"

    id: Mapped[int] = mapped_column(primary_key=True)
    goal_id: Mapped[int] = mapped_column(ForeignKey("weekly_goals.id"), unique=True)
    bonus_xaf: Mapped[int] = mapped_column(Integer)
    shared_total_xaf: Mapped[int] = mapped_column(Integer)   # deduit du proprietaire
    owner_net_xaf: Mapped[int] = mapped_column(Integer)
    settled_by: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)

    lines = relationship("GoalSettlementLine", back_populates="settlement", order_by="GoalSettlementLine.id")
    goal = relationship("WeeklyGoal")

    @property
    def week_start(self):
        return self.goal.week_start


class GoalSettlementLine(TimestampMixin, Base):
    __tablename__ = "goal_settlement_lines"

    id: Mapped[int] = mapped_column(primary_key=True)
    settlement_id: Mapped[int] = mapped_column(ForeignKey("goal_settlements.id", ondelete="CASCADE"), index=True)
    driver_id: Mapped[int] = mapped_column(ForeignKey("drivers.id"), index=True)
    role: Mapped[str] = mapped_column(String(10))  # owner / helper
    percent: Mapped[int] = mapped_column(Integer)
    amount_xaf: Mapped[int] = mapped_column(Integer)
    wallet_tx_id: Mapped[int | None] = mapped_column(ForeignKey("wallet_txs.id"), nullable=True)

    settlement = relationship("GoalSettlement", back_populates="lines")
    driver = relationship("Driver")

    @property
    def driver_name(self) -> str:
        return self.driver.user.full_name
