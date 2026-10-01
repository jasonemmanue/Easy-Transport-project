from datetime import datetime

from sqlalchemy import DateTime, Enum as SAEnum, func
from sqlalchemy.orm import Mapped, mapped_column


def pg_enum(enum_cls, name: str):
    """Enum PostgreSQL stockant la valeur (et non le nom) de l'enum Python."""
    return SAEnum(enum_cls, name=name, values_callable=lambda e: [m.value for m in e])


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
