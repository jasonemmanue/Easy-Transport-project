from datetime import timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import current_user
from app.core.clock import utcnow
from app.core.errors import Conflict
from app.db.session import get_db
from app.models import Dispute, DisputeStatus, RideStatus, User
from app.schemas import DisputeIn, DisputeOut
from app.services import rides as rides_svc

router = APIRouter(prefix="/disputes", tags=["disputes"])

CONTEST_WINDOW = timedelta(days=7)


@router.post("", response_model=DisputeOut, status_code=201,
             summary="Contester (Pause Arret, prix...) ou signaler un probleme")
def open_dispute(payload: DisputeIn, user: User = Depends(current_user), db: Session = Depends(get_db)):
    ride = rides_svc.get_ride(db, payload.ride_id)
    rides_svc.assert_participant(ride, user)
    if ride.status != RideStatus.completed:
        raise Conflict("RIDE_NOT_COMPLETED", "Seule une course terminee peut etre contestee")
    if payload.kind == "pause_arret" and not ride.pauses:
        raise Conflict("NO_PAUSE_TO_CONTEST", "Aucune Pause Arret sur cette course")
    if ride.completed_at and utcnow() - ride.completed_at > CONTEST_WINDOW:
        raise Conflict("CONTEST_WINDOW_CLOSED", "Delai de contestation de 7 jours depasse")
    if db.execute(select(Dispute.id).where(Dispute.ride_id == ride.id, Dispute.kind == payload.kind,
                                           Dispute.opened_by == user.id)).first():
        raise Conflict("DISPUTE_EXISTS", "Contestation deja ouverte")
    dispute = Dispute(ride_id=ride.id, kind=payload.kind, opened_by=user.id, description=payload.description,
                      status=DisputeStatus.open, refund_xaf=0, points_penalty=0)
    db.add(dispute)
    db.commit()
    return dispute


@router.get("/mine", response_model=list[DisputeOut])
def mine(user: User = Depends(current_user), db: Session = Depends(get_db)):
    return db.execute(select(Dispute).where(Dispute.opened_by == user.id)
                      .order_by(Dispute.id.desc())).scalars().all()
