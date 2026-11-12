import os
from typing import List, Union
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Cấu hình toàn bộ ứng dụng thông qua biến môi trường (.env)."""
    APP_NAME: str = "Pataware Anti-Scam Platform"
    APP_ENV: str = "development"
    DEBUG: bool = True
    PORT: int = 8000
    HOST: str = "0.0.0.0"

    # Cấu hình bảo mật và JWT
    SECRET_KEY: str = "pataware-super-secret-key-change-in-production-2025"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # Thời hạn token: 24 giờ

    # Cấu hình chuỗi kết nối cơ sở dữ liệu (PostgreSQL/MySQL cho production, SQLite cho dev)
    DATABASE_URL: str = "sqlite:///./pataware.db"
    DB_POOL_SIZE: int = 10
    DB_MAX_OVERFLOW: int = 20
    DB_POOL_RECYCLE: int = 3600
    DB_POOL_TIMEOUT: int = 30

    # Cấu hình API Trí tuệ nhân tạo (Google Gemini) và công cụ OCR (Tesseract)
    GEMINI_API_KEY: str = ""
    TESSERACT_CMD: str = ""

    # Cấu hình các cổng dữ liệu tình báo mã độc & mối đe dọa quốc tế (Threat Intelligence APIs)
    GOOGLE_SAFE_BROWSING_API_KEY: str = ""
    VIRUSTOTAL_API_KEY: str = ""
    ENABLE_URLHAUS_CHECK: bool = True
    ENABLE_CHONGLUADAO_CHECK: bool = True

    # Cấu hình nguồn gốc được phép gọi API (CORS)
    BACKEND_CORS_ORIGINS: List[str] = ["*"]

    class Config:
        env_file = ".env"
        extra = "allow"
        case_sensitive = True


settings = Settings()
