from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    APP_NAME: str = "모운"
    DATABASE_URL: str = "mysql+pymysql://moun:moun@localhost:3306/moun"
    REDIS_URL: str = "redis://localhost:6379/0"

    # JWT
    JWT_SECRET_KEY: str = "change-me-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Rate limiting: /auth/login
    LOGIN_RATE_LIMIT_MAX: int = 5        # 최대 시도 횟수
    LOGIN_RATE_LIMIT_WINDOW: int = 900   # 제한 윈도우 (초, 15분)

    # Kakao
    KAKAO_REST_API_KEY: str = "a4f52f3b3ad7cd259dd9f82f4c39144e"

    # MinIO
    MINIO_ENDPOINT: str = "localhost:9000"
    MINIO_ACCESS_KEY: str = "minioadmin"
    MINIO_SECRET_KEY: str = "minioadmin"
    MINIO_BUCKET: str = "moun"

    # Space 초대 링크
    FRONTEND_BASE_URL: str = "https://moun.app"
    SPACE_INVITE_EXPIRE_HOURS: int = 72


settings = Settings()
