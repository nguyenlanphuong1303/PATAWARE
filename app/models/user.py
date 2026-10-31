from datetime import datetime
from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base


class User(Base):
    """Bảng lưu trữ tài khoản người dùng và phân quyền trong hệ thống."""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100), nullable=True)
    role = Column(String(20), default="user", nullable=False)  # Phân quyền: admin (quản trị), moderator (kiểm duyệt), user (người dùng)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Quan hệ với các bài viết chia sẻ và kết quả trắc nghiệm
    stories = relationship("CommunityStory", back_populates="author", cascade="all, delete-orphan")
    quiz_results = relationship("UserQuizResult", back_populates="user", cascade="all, delete-orphan")
