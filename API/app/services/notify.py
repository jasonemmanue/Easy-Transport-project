from sqlalchemy.orm import Session

from app.models import Notification


def notify(db: Session, user_id: int, kind: str, title: str, body: str, **data) -> None:
    """Notification in-app (le push FCM se branchera ici en Phase MVP)."""
    db.add(Notification(user_id=user_id, kind=kind, title=title, body=body, data=data))
