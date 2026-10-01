"""Systeme de points chauffeur (cahier des charges 3.1.3)."""
from sqlalchemy.orm import Session

from app.models import Driver, DriverValidation, PointEvent

SUSPENSION_THRESHOLD = 20
MAX_POINTS = 100

RIDE_COMPLETED = 2
UNAUTHORIZED_REFUSAL = -5
UNJUSTIFIED_CANCELLATION = -5
PAUSE_ABUSE = -3


def add_points(db: Session, driver: Driver, delta: int, kind: str, reason: str | None = None,
               ride_id: int | None = None) -> PointEvent:
    driver.points = max(0, min(MAX_POINTS, driver.points + delta))
    event = PointEvent(driver_id=driver.id, delta=delta, kind=kind, reason=reason,
                       ride_id=ride_id, balance_after=driver.points)
    db.add(event)
    # Score insuffisant (< 20 points) : suspension temporaire automatique.
    if driver.points < SUSPENSION_THRESHOLD and driver.validation_status == DriverValidation.approved:
        driver.validation_status = DriverValidation.suspended
        driver.online = False
    return event
