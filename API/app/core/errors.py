"""Erreurs metier typees.

Chaque erreur porte un code stable (`code`) que les clients (apps Flutter,
Backoffice) peuvent tester, en plus du message lisible.
"""
from fastapi import Request
from fastapi.responses import JSONResponse


class AppError(Exception):
    status_code = 400

    def __init__(self, code: str, message: str, **details):
        super().__init__(message)
        self.code = code
        self.message = message
        self.details = details


class NotFound(AppError):
    status_code = 404

    def __init__(self, entity: str, entity_id=None):
        super().__init__("NOT_FOUND", f"{entity} introuvable", entity=entity, id=entity_id)


class Forbidden(AppError):
    status_code = 403


class Conflict(AppError):
    """Regle metier non satisfaite (failed-precondition)."""

    status_code = 409


class Invalid(AppError):
    status_code = 422


async def app_error_handler(_: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": {"code": exc.code, "message": exc.message, "details": exc.details}},
    )
