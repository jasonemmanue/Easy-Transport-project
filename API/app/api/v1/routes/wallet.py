from fastapi import APIRouter

from app.schemas.schemas import WalletTopupIn

router = APIRouter(prefix="/wallet", tags=["wallet"])


@router.get("/balance/{user_id}")
def balance(user_id: int):
    return {"user_id": user_id, "balance_xaf": 2500, "min_xaf": 500}


@router.post("/topup/{user_id}")
def topup(user_id: int, payload: WalletTopupIn):
    return {
        "user_id": user_id,
        "credited_xaf": payload.amount_xaf,
        "channel": payload.channel,
        "status": "success",
    }


@router.get("/history/{user_id}")
def history(user_id: int):
    return {
        "user_id": user_id,
        "transactions": [
            {"amount_xaf": -2350, "kind": "ride", "date": "2026-09-23"},
            {"amount_xaf": 5000, "kind": "topup", "date": "2026-09-22"},
        ],
    }
