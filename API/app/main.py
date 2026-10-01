from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.api.v1.router import api_router
from app.core import cache
from app.core.config import settings
from app.core.errors import AppError, app_error_handler
from app.db.session import engine

app = FastAPI(
    title=settings.APP_NAME,
    version="1.1.0",
    description=(
        "API REST Carlinq v1.2 - Carlinq Flexible + Carlinq Taxi. "
        "Authentification, passagers, chauffeurs (Drivers & Copilote), courses et tarification "
        "(arrets, Pause Arret, embouteillage, route degradee), portefeuille, objectifs hebdomadaires "
        "et partage d'objectif entre chauffeurs, zones Carlinq Taxi, litiges, administration."
    ),
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.CORS_ORIGINS.split(",")],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_exception_handler(AppError, app_error_handler)


@app.get("/", tags=["root"])
def root():
    return {"app": settings.APP_NAME, "env": settings.APP_ENV, "docs": "/docs"}


@app.get("/healthz", tags=["root"])
def health():
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    return {"status": "ok", "database": "ok", "cache": cache.ping()}


app.include_router(api_router)
