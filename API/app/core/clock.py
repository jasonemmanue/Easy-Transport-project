"""Horloge metier : semaines d'objectifs et journees de quota a l'heure de Douala."""
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from app.core.config import settings

TZ = ZoneInfo(settings.TIMEZONE)


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def local_date(at: datetime | None = None) -> date:
    return (at or utcnow()).astimezone(TZ).date()


def week_start(at: datetime | date | None = None) -> date:
    """Lundi de la semaine (heure de Douala) contenant `at`."""
    if at is None or isinstance(at, datetime):
        d = local_date(at)
    else:
        d = at
    return d - timedelta(days=d.weekday())


def week_end_utc(start: date) -> datetime:
    """Fin de semaine d'objectif : lundi suivant 00:00 heure de Douala, en UTC."""
    nxt = datetime.combine(start + timedelta(days=7), datetime.min.time(), TZ)
    return nxt.astimezone(timezone.utc)
