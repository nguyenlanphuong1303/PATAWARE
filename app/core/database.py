from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from app.core.config import settings

# Chuẩn hóa URL kết nối (hỗ trợ cú pháp postgres:// thường gặp trên PaaS/Docker)
db_url = settings.DATABASE_URL
if db_url.startswith("postgres://"):
    db_url = db_url.replace("postgres://", "postgresql://", 1)

# Tùy biến tham số khởi tạo Engine tùy theo hệ quản trị CSDL
engine_kwargs = {
    "pool_pre_ping": True,
}

if db_url.startswith("sqlite"):
    engine_kwargs["connect_args"] = {"check_same_thread": False}
else:
    # Cấu hình Connection Pool tối ưu hiệu năng và độ ổn định cho Production (PostgreSQL, MySQL)
    engine_kwargs.update({
        "pool_size": settings.DB_POOL_SIZE,
        "max_overflow": settings.DB_MAX_OVERFLOW,
        "pool_recycle": settings.DB_POOL_RECYCLE,
        "pool_timeout": settings.DB_POOL_TIMEOUT,
    })

# Khởi tạo Engine kết nối cơ sở dữ liệu
engine = create_engine(db_url, **engine_kwargs)

# Khởi tạo Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Lớp cơ sở (Base) cho tất cả các Model ORM
Base = declarative_base()


def get_db():
    """Hàm phụ thuộc (Dependency) cung cấp phiên làm việc với cơ sở dữ liệu và tự động đóng sau khi xử lý xong request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
