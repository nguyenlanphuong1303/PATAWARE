import os
from typing import List, Union
from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Cấu hình toàn bộ ứng dụng thông qua biến môi trường (.env)."""
    APP_NAME: str = "Pataware Anti-Scam Platform"
    APP_ENV: str = "development"
    DEBUG: bool = True
    PORT: int = 8000
    HOST: str = "0.0.0.0"

    # Cấu hình bảo mật và JWT
    SECRET_KEY: str = Field(min_length=32)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # Thời hạn token: 24 giờ

    # Cấu hình chuỗi kết nối cơ sở dữ liệu (SQLite cho môi trường dev hoặc MySQL cho production)
    DATABASE_URL: str = "sqlite:///./pataware.db"

    # Cấu hình API Trí tuệ nhân tạo (Google Gemini) và công cụ OCR (Tesseract)
    GEMINI_API_KEY: str = ""
    TESSERACT_CMD: str = ""

    # Cấu hình nguồn gốc được phép gọi API (CORS)
    BACKEND_CORS_ORIGINS: List[str] = ["*"]

    class Config:
        env_file = ".env"
        extra = "allow"
        case_sensitive = True


settings = Settings()
