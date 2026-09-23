from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    APP_NAME: str = "EasyTransport API"
    APP_ENV: str = "development"
    APP_HOST: str = "0.0.0.0"
    APP_PORT: int = 8000

    SECRET_KEY: str = "change-me"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    DATABASE_URL: str = "postgresql+psycopg2://postgres:postgres@localhost:5432/easytransport"
    REDIS_URL: str = "redis://localhost:6379/0"

    GOOGLE_MAPS_API_KEY: str = ""
    FIREBASE_CREDENTIALS_PATH: str = ""

    COMMISSION_RATE: float = 0.08
    MIN_WALLET_XAF: int = 500
    CANCELLATION_FREE_WINDOW_SECONDS: int = 15
    TRAFFIC_TOLERANCE_MINUTES: int = 2
    COPILOTE_MONTHLY_QUOTA_XAF: int = 5000


settings = Settings()
