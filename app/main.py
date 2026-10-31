import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

from app.core.config import settings
from app.core.database import engine, Base, SessionLocal
from app.api.v1.router import api_router
from app.models.blacklist import WhitelistBrand, Blacklist

# Tự động tạo các bảng cơ sở dữ liệu nếu chưa tồn tại
Base.metadata.create_all(bind=engine)

# Khởi tạo ứng dụng FastAPI với thông tin cấu hình
app = FastAPI(
    title=settings.APP_NAME,
    description="Hệ thống phát hiện và cảnh báo lừa đảo trực tuyến tích hợp trí tuệ nhân tạo và phân tích kỹ thuật mạng",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Cấu hình chính sách chia sẻ tài nguyên nguồn gốc chéo (CORS)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Hàm nạp dữ liệu mẫu ban đầu vào cơ sở dữ liệu
def seed_data():
    db = SessionLocal()
    try:
        # Nạp danh sách thương hiệu uy tín (ngân hàng, sàn TMĐT) để đối chiếu mạo danh (Typosquatting)
        if db.query(WhitelistBrand).count() == 0:
            sample_brands = [
                WhitelistBrand(name="Vietcombank", domain="vietcombank.com.vn", brand_keyword="vietcombank", category="bank"),
                WhitelistBrand(name="MBBank", domain="mbbank.com.vn", brand_keyword="mbbank", category="bank"),
                WhitelistBrand(name="Techcombank", domain="techcombank.com", brand_keyword="techcombank", category="bank"),
                WhitelistBrand(name="Shopee VN", domain="shopee.vn", brand_keyword="shopee", category="ecommerce"),
                WhitelistBrand(name="VNeID", domain="vneid.gov.vn", brand_keyword="vneid", category="government")
            ]
            db.add_all(sample_brands)

        # Nạp dữ liệu danh sách đen (Blacklist) các đối tượng lừa đảo phổ biến
        if db.query(Blacklist).count() == 0:
            sample_blacklists = [
                Blacklist(type="domain", value="vietc0mbank-portal.xyz", reason="Giả mạo ngân hàng Vietcombank đánh cắp OTP", report_count=84, severity="critical"),
                Blacklist(type="bank_account", value="1029384756", bank_name="Techcombank", owner_name="NGUYEN VAN A", reason="Tài khoản nhận tiền lừa đảo tuyển CTV làm nhiệm vụ", report_count=67, severity="high"),
                Blacklist(type="phone", value="0879654321", reason="Mạo danh cán bộ điều tra bộ công an đe dọa lệnh bắt", report_count=52, severity="high")
            ]
            db.add_all(sample_blacklists)

        db.commit()
    finally:
        db.close()

# Thực hiện nạp dữ liệu mẫu khi khởi động
seed_data()

# Gắn kết các tuyến đường API (Router) v1
app.include_router(api_router, prefix="/api/v1")

# Cấu hình thư mục chứa tài nguyên tĩnh của giao diện web (HTML, CSS, JS)
static_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")


@app.get("/")
def read_root():
    """Trả về giao diện web trang chủ hoặc thông tin API nếu chưa có giao diện."""
    index_file = os.path.join(static_dir, "index.html")
    if os.path.exists(index_file):
        return FileResponse(index_file)
    return {
        "app": settings.APP_NAME,
        "status": "online",
        "docs": "/docs",
        "api_v1": "/api/v1"
    }


@app.get("/health")
def health_check():
    """Kiểm tra trạng thái hoạt động của hệ thống."""
    return {"status": "ok", "app": settings.APP_NAME}
