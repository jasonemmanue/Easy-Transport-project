"""Regles metier stockees en base (`app_settings`), modifiables par l'admin.

Deux documents : `pricing` (tarification) et `goals` (objectifs + partage).
Toute ecriture passe par `update_setting`, qui journalise avant/apres.
"""
from pydantic import BaseModel, Field, field_validator, model_validator
from sqlalchemy.orm import Session

from app.core.clock import utcnow
from app.core.errors import Invalid
from app.models import AppSetting


class PricingConfig(BaseModel):
    # Commission plateforme : 8 % par defaut, jamais > 10 % (contrainte produit).
    commission_percent: int = Field(8, ge=0, le=10)
    rate_per_km_xaf: dict[str, int] = {"flexible": 350, "taxi": 250}
    min_fare_xaf: dict[str, int] = {"flexible": 1000, "taxi": 500}
    class_coefficients: dict[str, float] = {"eco": 1.0, "serenity": 1.3, "prestige": 1.7}
    stop_supplement_xaf: dict[str, int] = {"flexible": 300, "taxi": 200}
    extra_place_percent: int = Field(50, ge=0, le=100)
    traffic_tolerance_seconds: int = Field(180, ge=0)
    traffic_rate_per_minute_xaf: int = Field(50, ge=0)
    pause_rate_per_minute_xaf: int = Field(50, ge=0)
    max_impromptu_pauses: int = Field(3, ge=0)
    free_cancel_seconds: int = Field(15, ge=0)
    late_tolerance_seconds: int = Field(300, ge=0)
    cancellation_fee_xaf: int = Field(500, ge=0)
    min_wallet_xaf: int = Field(500, ge=0)
    premium_monthly_xaf: int = Field(5000, ge=0)
    refusal_window_seconds: int = Field(600, ge=300, le=600)  # 5 a 10 min / jour
    refusal_cost_seconds: int = Field(60, ge=1)

    @field_validator("rate_per_km_xaf", "min_fare_xaf", "stop_supplement_xaf")
    @classmethod
    def _modes(cls, v: dict[str, int]):
        if set(v) != {"flexible", "taxi"} or any(x < 0 for x in v.values()):
            raise ValueError("attendu : {flexible, taxi} en entiers XAF positifs")
        return v

    @field_validator("class_coefficients")
    @classmethod
    def _classes(cls, v: dict[str, float]):
        if set(v) != {"eco", "serenity", "prestige"} or any(x <= 0 for x in v.values()):
            raise ValueError("attendu : {eco, serenity, prestige} > 0")
        return v


class GoalTier(BaseModel):
    target_rides: int = Field(gt=0)
    bonus_xaf: int = Field(ge=0)


class GoalSharingConfig(BaseModel):
    enabled: bool = True
    max_helpers: int = Field(3, ge=1, le=10)
    min_percent: int = Field(5, ge=1, le=99)
    max_percent_per_helper: int = Field(30, ge=1, le=99)
    # Part maximale du bonus cedee aux aidants : le proprietaire garde le reste.
    max_total_percent: int = Field(50, ge=1, le=99)

    @model_validator(mode="after")
    def _coherent(self):
        if self.min_percent > self.max_percent_per_helper:
            raise ValueError("min_percent doit etre <= max_percent_per_helper")
        if self.max_percent_per_helper > self.max_total_percent:
            raise ValueError("max_percent_per_helper doit etre <= max_total_percent")
        return self


class GoalsConfig(BaseModel):
    tiers: list[GoalTier] = [
        GoalTier(target_rides=30, bonus_xaf=5000),
        GoalTier(target_rides=50, bonus_xaf=10000),
        GoalTier(target_rides=80, bonus_xaf=20000),
    ]
    points_on_achieved: int = Field(10, ge=0)
    pause_max_hours: int = Field(72, ge=0, le=72)
    # Reprise : jours apres la fin de semaine pour terminer un objectif en retard.
    grace_days: int = Field(3, ge=0, le=7)
    sharing: GoalSharingConfig = GoalSharingConfig()

    @field_validator("tiers")
    @classmethod
    def _tiers(cls, v: list[GoalTier]):
        if not v:
            raise ValueError("au moins un palier")
        targets = [t.target_rides for t in v]
        if targets != sorted(set(targets)):
            raise ValueError("paliers strictement croissants par nombre de courses")
        return v

    def bonus_for(self, target_rides: int) -> int:
        """Bonus du plus haut palier atteint par la cible choisie (0 si sous le 1er)."""
        eligible = [t.bonus_xaf for t in self.tiers if t.target_rides <= target_rides]
        return eligible[-1] if eligible else 0


SCHEMAS = {"pricing": PricingConfig, "goals": GoalsConfig}


def _load(db: Session, key: str):
    from app.core import cache

    model = SCHEMAS[key]

    def from_db():
        row = db.get(AppSetting, key)
        return row.value if row else model().model_dump()

    return model.model_validate(cache.get_or_set(f"settings:{key}", from_db))


def get_pricing(db: Session) -> PricingConfig:
    return _load(db, "pricing")


def get_goals_config(db: Session) -> GoalsConfig:
    return _load(db, "goals")


def update_setting(db: Session, key: str, payload: dict, actor_id: int):
    from app.core import cache
    from app.services.audit import audit

    if key not in SCHEMAS:
        raise Invalid("UNKNOWN_SETTING", f"Parametre inconnu : {key}")
    before = _load(db, key)
    try:
        after = SCHEMAS[key].model_validate({**before.model_dump(), **payload})
    except ValueError as exc:
        raise Invalid("SETTING_INVALID", str(exc)) from exc
    row = db.get(AppSetting, key)
    if row is None:
        row = AppSetting(key=key, value={})
        db.add(row)
    row.value = after.model_dump()
    row.updated_at = utcnow()
    row.updated_by = actor_id
    audit(db, actor_id, f"settings.{key}.update", "app_settings", key, before.model_dump(), after.model_dump())
    db.flush()
    cache.invalidate_on_commit(db, f"settings:{key}")
    return after

