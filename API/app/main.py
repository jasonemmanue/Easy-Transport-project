from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.api.v1.router import api_router

app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    description=(
        "API REST EasyTransport v1.2 - Marketplace bi-mode Easy Flexible + Easy Taxi. "
        "Endpoints : authentification, chauffeurs (Drivers & Copilote), passagers, "
        "reservations, tarification (arrets, embouteillage, pause arret, route degradee), "
        "wallet Mobile Money, zones Easy Taxi, administration."
    ),
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", tags=["root"])
def root():
    return {"app": settings.APP_NAME, "env": settings.APP_ENV, "docs": "/docs"}


@app.get("/healthz", tags=["root"])
def health():
    return {"status": "ok"}


app.include_router(api_router)
