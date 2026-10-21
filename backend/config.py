import os
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

load_dotenv()

class Settings(BaseSettings):
    PROJECT_NAME: str = "Shekhar Sir Classes API"
    ENV_MODE: str = os.getenv("ENV_MODE", "production")
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your_super_secret_jwt_key_here")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30  # 30 days
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql://shekhar_db_user:secret_pass@localhost:5432/shekharsir_db")
    ALLOWED_ORIGINS: str = os.getenv("ALLOWED_ORIGINS", "*")
    ALLOWED_HOSTS: str = os.getenv("ALLOWED_HOSTS", "*")

    class Config:
        env_file = ".env"
        extra = "allow"

settings = Settings()
