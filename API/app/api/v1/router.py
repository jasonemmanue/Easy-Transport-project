from fastapi import APIRouter

from app.api.v1.routes import auth, rides, drivers, wallet, admin, zones

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth.router)
api_router.include_router(rides.router)
api_router.include_router(drivers.router)
api_router.include_router(wallet.router)
api_router.include_router(admin.router)
api_router.include_router(zones.router)
