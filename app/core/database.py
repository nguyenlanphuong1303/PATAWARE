from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from app.core.config import settings

# Tùy biến tham số kết nối: nếu dùng SQLite thì cần check_same_thread=False
connect_args = {}
if settings.DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

# Khởi tạo Engine kết nối cơ sở dữ liệu
engine = create_engine(
    settings.DATABASE_URL,
    connect_args=connect_args,
    pool_pre_ping=True
)

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
