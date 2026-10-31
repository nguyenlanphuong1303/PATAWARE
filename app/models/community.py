from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base


class CommunityStory(Base):
    """Bảng lưu trữ các câu chuyện chia sẻ cảnh báo lừa đảo từ cộng đồng (ScamGuard) đã qua bộ lọc ẩn danh PII."""
    __tablename__ = "community_stories"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    
    title = Column(String(200), nullable=False)           # Tiêu đề bài viết chia sẻ
    raw_content = Column(Text, nullable=True)             # Nội dung gốc của người dùng
    redacted_content = Column(Text, nullable=False)       # Nội dung hiển thị công khai (đã tự động che mờ CCCD, SĐT, STK)
    
    scam_type = Column(String(50), index=True, nullable=False)  # Hình thức: 'financial_investment', 'job_offer', 'impersonation', 'phishing_link', 'otp_theft'
    reported_scammer_phone = Column(String(50), nullable=True)  # Số điện thoại kẻ lừa đảo bị tố cáo
    reported_scammer_bank = Column(String(100), nullable=True)  # Số tài khoản ngân hàng kẻ lừa đảo bị tố cáo
    reported_scammer_url = Column(String(255), nullable=True)   # Đường link độc hại liên quan
    loss_amount = Column(String(50), nullable=True)             # Số tiền thiệt hại ước tính
    evidence_image = Column(String(255), nullable=True)         # Ảnh chụp bằng chứng (nếu có)
    
    # Quy trình kiểm duyệt: 'pending' (chờ duyệt), 'approved' (đã duyệt), 'rejected' (từ chối)
    status = Column(String(20), default="approved", index=True)
    moderated_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    moderation_notes = Column(Text, nullable=True)
    
    upvotes = Column(Integer, default=0)                  # Số lượt người dùng đánh giá hữu ích
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    author = relationship("User", foreign_keys=[user_id], back_populates="stories")
