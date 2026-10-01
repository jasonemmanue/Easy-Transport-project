from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base
from app.models.base import TimestampMixin, pg_enum
from app.models.enums import UserRole


class User(TimestampMixin, Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    full_name: Mapped[str] = mapped_column(String(120))
    phone: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    email: Mapped[str | None] = mapped_column(String(120), unique=True, nullable=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    role: Mapped[UserRole] = mapped_column(pg_enum(UserRole, "user_role"), index=True)
    language: Mapped[str] = mapped_column(String(2), default="fr")

    # Portefeuille : passager (paiement des courses) comme chauffeur (gains,
    # bonus d'objectif, parts de partage). Toujours en entier XAF.
    wallet_balance_xaf: Mapped[int] = mapped_column(Integer, default=0)

    home_address: Mapped[str | None] = mapped_column(String(255), nullable=True)
    home_lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    home_lng: Mapped[float | None] = mapped_column(Float, nullable=True)

    rating_avg: Mapped[float] = mapped_column(Float, default=5.0)
    rating_count: Mapped[int] = mapped_column(Integer, default=0)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    suspended_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    driver = relationship("Driver", back_populates="user", uselist=False)
