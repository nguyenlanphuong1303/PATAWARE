import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

from app.core.config import settings
from app.core.database import engine, Base, SessionLocal
from app.core.security import get_password_hash
from app.api.v1.router import api_router
from app.models.user import User
from app.models.blacklist import WhitelistBrand, Blacklist
from app.models.quiz import QuizQuestion, QuizOption
from app.models.community import CommunityStory

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

# Hàm nạp dữ liệu mẫu ban đầu vào cơ sở dữ liệu nếu hệ thống chưa có dữ liệu
def seed_data():
    db = SessionLocal()
    try:
        # 1. Khởi tạo tài khoản Quản trị viên và người dùng mẫu nếu chưa có
        if db.query(User).count() == 0:
            admin_user = User(
                username="admin",
                email="admin@pataware.vn",
                hashed_password=get_password_hash("admin123"),
                full_name="Pataware Administrator",
                role="admin",
                is_active=True
            )
            demo_user = User(
                username="demo_user",
                email="user@pataware.vn",
                hashed_password=get_password_hash("user123"),
                full_name="Nguyễn Văn An",
                role="user",
                is_active=True
            )
            db.add_all([admin_user, demo_user])
            db.commit()

        # 2. Nạp danh sách thương hiệu uy tín (ngân hàng, sàn TMĐT, MXH, bưu chính, DVC)
        if db.query(WhitelistBrand).count() == 0:
            sample_brands = [
                WhitelistBrand(name="Vietcombank", domain="vietcombank.com.vn", brand_keyword="vietcombank", category="bank"),
                WhitelistBrand(name="MBBank", domain="mbbank.com.vn", brand_keyword="mbbank", category="bank"),
                WhitelistBrand(name="Techcombank", domain="techcombank.com", brand_keyword="techcombank", category="bank"),
                WhitelistBrand(name="BIDV", domain="bidv.com.vn", brand_keyword="bidv", category="bank"),
                WhitelistBrand(name="Agribank", domain="agribank.com.vn", brand_keyword="agribank", category="bank"),
                WhitelistBrand(name="VietinBank", domain="vietinbank.vn", brand_keyword="vietinbank", category="bank"),
                WhitelistBrand(name="VPBank", domain="vpbank.com.vn", brand_keyword="vpbank", category="bank"),
                WhitelistBrand(name="ACB", domain="acb.com.vn", brand_keyword="acb", category="bank"),
                WhitelistBrand(name="TPBank", domain="tpb.vn", brand_keyword="tpbank", category="bank"),
                WhitelistBrand(name="Sacombank", domain="sacombank.com.vn", brand_keyword="sacombank", category="bank"),
                WhitelistBrand(name="MoMo", domain="momo.vn", brand_keyword="momo", category="e-wallet"),
                WhitelistBrand(name="ZaloPay", domain="zalopay.vn", brand_keyword="zalopay", category="e-wallet"),
                WhitelistBrand(name="VNPay", domain="vnpay.vn", brand_keyword="vnpay", category="e-wallet"),
                WhitelistBrand(name="Shopee VN", domain="shopee.vn", brand_keyword="shopee", category="ecommerce"),
                WhitelistBrand(name="Lazada VN", domain="lazada.vn", brand_keyword="lazada", category="ecommerce"),
                WhitelistBrand(name="Tiki", domain="tiki.vn", brand_keyword="tiki", category="ecommerce"),
                WhitelistBrand(name="TikTok Shop", domain="tiktok.com", brand_keyword="tiktok", category="ecommerce"),
                WhitelistBrand(name="VNeID", domain="vneid.gov.vn", brand_keyword="vneid", category="government"),
                WhitelistBrand(name="Bộ Công An", domain="bocongan.gov.vn", brand_keyword="bocongan", category="government"),
                WhitelistBrand(name="Cổng DVC Quốc gia", domain="dichvucong.gov.vn", brand_keyword="dichvucong", category="government"),
                WhitelistBrand(name="VNPost", domain="vnpost.vn", brand_keyword="vnpost", category="logistics"),
                WhitelistBrand(name="ViettelPost", domain="viettelpost.com.vn", brand_keyword="viettelpost", category="logistics"),
                WhitelistBrand(name="Telegram", domain="telegram.org", brand_keyword="telegram", category="social"),
                WhitelistBrand(name="Facebook", domain="facebook.com", brand_keyword="facebook", category="social")
            ]
            db.add_all(sample_brands)
            db.commit()

        # 3. Nạp dữ liệu danh sách đen (Blacklist) các đối tượng lừa đảo phổ biến
        if db.query(Blacklist).count() == 0:
            sample_blacklists = [
                Blacklist(type="domain", value="vietc0mbank-portal.xyz", reason="Giả mạo ngân hàng Vietcombank đánh cắp mã Smart OTP", report_count=84, severity="critical"),
                Blacklist(type="domain", value="mbbank-online-support.site", reason="Mạo danh MBBank lừa nâng hạn mức thẻ tín dụng", report_count=63, severity="critical"),
                Blacklist(type="domain", value="vneid-dinhdanh-gov.top", reason="Giả mạo ứng dụng VNeID phát tán mã độc chiếm quyền điện thoại", report_count=58, severity="critical"),
                Blacklist(type="domain", value="shopee-trungthuong.top", reason="Bẫy trúng thưởng xe SH mạo danh Shopee yêu cầu nộp thuế phí cọc", report_count=47, severity="critical"),
                Blacklist(type="bank_account", value="1029384756", bank_name="Techcombank", owner_name="NGUYEN VAN A", reason="Tài khoản nhận tiền lừa đảo tuyển CTV làm nhiệm vụ giật đơn Shopee", report_count=79, severity="critical"),
                Blacklist(type="bank_account", value="998877665544", bank_name="MBBank", owner_name="TRAN VAN B", reason="Nhận tiền cọc mua xe máy, điện thoại giá rẻ sau đó chặn liên lạc", report_count=54, severity="high"),
                Blacklist(type="bank_account", value="0381000998877", bank_name="Vietcombank", owner_name="LE THI C", reason="Dụ dỗ nạn nhân nạp tiền tham gia sàn giao dịch tài chính nhị phân", report_count=48, severity="critical"),
                Blacklist(type="phone", value="0879654321", reason="Mạo danh cán bộ điều tra Bộ Công an đe dọa lệnh bắt giam rửa tiền", report_count=92, severity="critical"),
                Blacklist(type="phone", value="0912345678", reason="Giả mạo nhân viên nhà mạng dọa khóa SIM sau 2 giờ nếu không cập nhật CCCD", report_count=65, severity="high"),
                Blacklist(type="phone", value="0865998877", reason="Tự xưng nhân viên ngân hàng hỗ trợ rút tiền mặt thẻ tín dụng phí 0 đồng", report_count=44, severity="high")
            ]
            db.add_all(sample_blacklists)
            db.commit()

        # 4. Nạp ngân hàng câu hỏi tình huống trắc nghiệm nếu chưa có
        if db.query(QuizQuestion).count() == 0:
            from app.api.v1.endpoints.quiz import SEED_QUESTIONS
            for q_data in SEED_QUESTIONS:
                q = QuizQuestion(
                    category=q_data.get("category", "general"),
                    scenario_title=q_data["scenario_title"],
                    scenario_description=q_data["scenario_description"],
                    explanation=q_data["explanation"],
                    difficulty=q_data.get("difficulty", "medium")
                )
                db.add(q)
                db.flush()
                for opt_text, is_corr in q_data["options"]:
                    db.add(QuizOption(question_id=q.id, option_text=opt_text, is_correct=is_corr))
            db.commit()

        # 5. Nạp bài viết cảnh báo cộng đồng mẫu
        if db.query(CommunityStory).count() == 0:
            first_user = db.query(User).first()
            user_id = first_user.id if first_user else None
            stories = [
                CommunityStory(
                    user_id=user_id,
                    title="Cảnh báo chiêu trò bẫy việc nhẹ lương cao giật đơn Shopee",
                    raw_content="Bọn chúng dụ mình nạp 500k làm nhiệm vụ đơn đầu có tiền, đến đơn 50 triệu thì giam tiền bắt nạp thêm phí giải cứu.",
                    redacted_content="Bọn chúng dụ mình nạp 500k làm nhiệm vụ đơn đầu có tiền, đến đơn 50 triệu thì giam tiền bắt nạp thêm phí giải cứu.",
                    scam_type="job_offer",
                    reported_scammer_bank="Techcombank: [STK ĐÃ ĐƯỢC CHE MỜ]",
                    loss_amount="50.000.000 VNĐ",
                    status="approved",
                    upvotes=42
                ),
                CommunityStory(
                    user_id=user_id,
                    title="Mạo danh cán bộ thuế gọi điện bắt cài app DVC giả mạo",
                    raw_content="Một đối tượng gọi báo sai thông tin thuế cá nhân, gửi link apk qua Zalo. May mắn mình kiểm tra qua Pataware phát hiện app chứa mã độc.",
                    redacted_content="Một đối tượng gọi báo sai thông tin thuế cá nhân, gửi link apk qua Zalo. May mắn mình kiểm tra qua Pataware phát hiện app chứa mã độc.",
                    scam_type="impersonation",
                    loss_amount="0 VNĐ (Ngăn chặn kịp)",
                    status="approved",
                    upvotes=35
                )
            ]
            db.add_all(stories)
            db.commit()

    except Exception as e:
        db.rollback()
        print(f"[!] Lỗi khi nạp dữ liệu mẫu ban đầu: {e}")
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


@app.get("/script.js")
def get_script_js():
    return FileResponse(os.path.join(static_dir, "script.js"))


@app.get("/style.css")
def get_style_css():
    return FileResponse(os.path.join(static_dir, "style.css"))


@app.get("/health")
def health_check():
    """Kiểm tra trạng thái hoạt động của hệ thống."""
    return {"status": "ok", "app": settings.APP_NAME}
