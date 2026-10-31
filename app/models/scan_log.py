from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, Float, Boolean, DateTime
from app.core.database import Base


class ScanLog(Base):
    """Bảng ghi nhận nhật ký tất cả các lượt kiểm tra quét rủi ro của người dùng phục vụ thống kê thời gian thực."""
    __tablename__ = "scan_logs"

    id = Column(Integer, primary_key=True, index=True)
    input_type = Column(String(30), index=True, nullable=False)  # Loại kiểm tra: 'url', 'text', 'phone', 'bank_account', 'image'
    raw_input = Column(Text, nullable=False)                     # Dữ liệu người dùng gửi lên
    risk_score = Column(Float, nullable=False)                   # Điểm rủi ro tổng hợp (0 - 100)
    risk_level = Column(String(20), index=True, nullable=False)  # Phân loại mức độ: 'SAFE', 'SUSPICIOUS', 'DANGEROUS'
    
    # Kết quả phân tích kỹ thuật tầng mạng (Deep Domain Analysis)
    domain_age_days = Column(Integer, nullable=True)             # Tuổi thọ tên miền tính theo ngày
    is_new_domain = Column(Boolean, default=False)               # Tên miền mới đăng ký dưới 30 ngày hay không
    is_typosquatting = Column(Boolean, default=False)            # Có dấu hiệu mạo danh tên thương hiệu hay không
    target_brand = Column(String(100), nullable=True)            # Thương hiệu bị nhắm tới giả mạo
    is_homoglyph = Column(Boolean, default=False)                # Có sử dụng ký tự đồng hình hoặc Punycode xn-- hay không
    is_blacklist_matched = Column(Boolean, default=False)        # Có khớp với danh sách đen hay không
    
    # Kết quả đánh giá bằng AI và tóm tắt
    ai_verdict = Column(Text, nullable=True)                     # Nhận định tóm tắt rủi ro
    details_json = Column(Text, nullable=True)                   # Chi tiết các thông số kỹ thuật dưới dạng chuỗi JSON
    
    client_ip_hash = Column(String(64), nullable=True)           # Mã băm IP ẩn danh bảo vệ người dùng
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
