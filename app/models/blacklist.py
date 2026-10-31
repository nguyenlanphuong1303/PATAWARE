from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, DateTime
from app.core.database import Base


class Blacklist(Base):
    """Bảng lưu trữ danh sách đen (Blacklist): số tài khoản, số điện thoại, tên miền và URL lừa đảo."""
    __tablename__ = "blacklists"

    id = Column(Integer, primary_key=True, index=True)
    type = Column(String(30), index=True, nullable=False)  # Phân loại: 'bank_account', 'phone', 'domain', 'url'
    value = Column(String(255), unique=True, index=True, nullable=False)
    bank_name = Column(String(100), nullable=True)  # Tên ngân hàng (nếu là số tài khoản)
    owner_name = Column(String(100), nullable=True)  # Tên chủ tài khoản kẻ lừa đảo
    reason = Column(Text, nullable=True)             # Lý do hoặc hành vi vi phạm
    report_count = Column(Integer, default=1)        # Số lượt người dùng tố cáo
    severity = Column(String(20), default="high")    # Mức độ nghiêm trọng: low, medium, high, critical
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class WhitelistBrand(Base):
    """Bảng lưu trữ thương hiệu uy tín tại Việt Nam để đối soát phát hiện hành vi mạo danh (Typosquatting)."""
    __tablename__ = "whitelist_brands"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)        # Tên thương hiệu: ví dụ 'Vietcombank'
    domain = Column(String(150), unique=True, index=True, nullable=False)  # Tên miền chính thức: 'vietcombank.com.vn'
    brand_keyword = Column(String(50), index=True, nullable=False)         # Từ khóa nhận diện: 'vietcombank'
    category = Column(String(50), default="bank")     # Lĩnh vực: bank, ecommerce, government, e-wallet
    created_at = Column(DateTime, default=datetime.utcnow)
