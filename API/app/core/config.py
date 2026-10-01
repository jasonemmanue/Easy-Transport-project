from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuration d'infrastructure (.env).

    Les regles metier modifiables a chaud (tarifs, objectifs, partage d'objectif)
    ne sont PAS ici : elles vivent en base (table `app_settings`) et se modifient
    via `/api/v1/admin/settings/*`. Les valeurs ci-dessous ne servent que de
    valeurs initiales lors du premier demarrage.
    """

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    APP_NAME: str = "Carlinq API"
    APP_ENV: str = "development"

    SECRET_KEY: str = "change-me"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    DATABASE_URL: str = "postgresql+psycopg2://postgres:postgres@localhost:55432/carlinq"

    # Cache Redis (vide = cache desactive). Jamais source de verite.
    REDIS_URL: str = "redis://localhost:56379/0"
    CACHE_TTL_SECONDS: int = 300

    # Fuseau metier : les semaines d'objectifs et les quotas journaliers
    # se calculent a l'heure de Douala.
    TIMEZONE: str = "Africa/Douala"

    CORS_ORIGINS: str = "*"


settings = Settings()
