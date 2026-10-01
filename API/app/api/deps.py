from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.clock import utcnow
from app.core.errors import AppError, Forbidden, NotFound
from app.core.security import decode_token
from app.db.session import get_db
from app.models import Driver, User, UserRole

bearer = HTTPBearer(auto_error=False)


class Unauthorized(AppError):
    status_code = 401

    def __init__(self, message: str = "Authentification requise"):
        super().__init__("UNAUTHENTICATED", message)


def current_user(creds: HTTPAuthorizationCredentials | None = Depends(bearer),
                 db: Session = Depends(get_db)) -> User:
    if creds is None:
        raise Unauthorized()
    try:
        user_id = decode_token(creds.credentials, "access")
    except ValueError:
        raise Unauthorized("Jeton invalide ou expire")
    user = db.get(User, user_id)
    if user is None or user.deleted_at is not None:
        raise Unauthorized("Compte introuvable")
    if not user.is_active:
        raise Forbidden("ACCOUNT_BANNED", "Compte desactive")
    if user.suspended_until and user.suspended_until > utcnow():
        raise Forbidden("ACCOUNT_SUSPENDED", "Compte suspendu", until=user.suspended_until.isoformat())
    return user


def require_roles(*roles: UserRole):
    def dep(user: User = Depends(current_user)) -> User:
        if user.role not in roles:
            raise Forbidden("INSUFFICIENT_ROLE", "Role insuffisant pour cette action",
                            required=[r.value for r in roles])
        return user
    return dep


passenger_only = require_roles(UserRole.passenger)
admin_only = require_roles(UserRole.admin)


def current_driver(user: User = Depends(require_roles(UserRole.drivers, UserRole.copilote))) -> Driver:
    if user.driver is None:
        raise NotFound("Profil chauffeur")
    return user.driver
