# PATAWARE - Nền Tảng Cảnh Báo & Phát Hiện Lừa Đảo Trực Tuyến

> **Hệ thống phát hiện và cảnh báo lừa đảo trực tuyến tích hợp trí tuệ nhân tạo và phân tích kỹ thuật mạng**  
> *Đề tài nghiên cứu ứng dụng kết hợp AI (LLM & OCR), Phân tích kỹ thuật tầng mạng (WHOIS, Levenshtein Typosquatting, Homoglyph) và Bảo vệ cộng đồng (PII Redaction).*

---

## 1. Cấu Trúc Thư Mục Dự Án

```text
E:\PATAWARE\
├── app/
│   ├── api/
│   │   └── v1/
│   │       ├── endpoints/
│   │       │   ├── auth.py          # Xác thực JWT, đăng ký, đăng nhập
│   │       │   ├── scan.py          # Chấm điểm URL, SĐT, STK, Đoạn chat & OCR hình ảnh
│   │       │   ├── community.py     # Góc chia sẻ ẩn danh & duyệt bài
│   │       │   ├── dashboard.py     # Thống kê & biểu đồ xu hướng thời gian thực
│   │       │   └── quiz.py          # Trắc nghiệm tình huống lừa đảo & Gamification
│   │       └── router.py            # Tổng hợp router v1
│   ├── core/
│   │   ├── config.py                # Cấu hình biến môi trường (pydantic-settings)
│   │   ├── database.py              # Kết nối SQLAlchemy (hỗ trợ SQLite / MySQL)
│   │   └── security.py              # Mã hóa Bcrypt & Quản lý Token JWT
│   ├── models/                      # SQLAlchemy ORM Models
│   │   ├── user.py                  # Bảng users
│   │   ├── blacklist.py             # Bảng blacklists & whitelist_brands
│   │   ├── scan_log.py              # Bảng scan_logs (lịch sử quét)
│   │   ├── community.py             # Bảng community_stories (chia sẻ cộng đồng)
│   │   └── quiz.py                  # Bảng quiz_questions & user_quiz_results
│   ├── schemas/                     # Pydantic Schemas (Request/Response)
│   ├── services/                    # Tầng nghiệp vụ cốt lõi
│   │   ├── risk_engine.py           # Hybrid Risk Engine (Bộ chấm điểm rủi ro đa tầng)
│   │   ├── url_analyzer.py          # Deep URL Analyzer (WHOIS, Levenshtein, Punycode)
│   │   ├── pii_redactor.py          # ScamGuard PII Redactor (Che mờ CCCD, SĐT, STK)
│   │   ├── ocr_service.py           # Bóc tách chữ từ ảnh chụp màn hình (Tesseract)
│   │   └── ai_service.py            # Phân tích thao túng tâm lý (Gemini API + Heuristic)
│   └── main.py                      # Khởi tạo FastAPI App, CORS, Static Files & Seeding
├── static/
│   └── index.html                   # Web UI hoàn chỉnh (Tailwind CSS, Chart.js)
├── run.py                           # Entrypoint khởi chạy server Uvicorn
├── requirements.txt                 # Danh mục thư viện phụ thuộc
├── .env.example                     # Mẫu biến môi trường
└── README.md
```

---

## 2. Các Tính Năng Đã Hoàn Thiện

1. **Hybrid Risk Engine (3.1)**:
   - Chấm điểm rủi ro theo thang điểm 0 - 100 dựa trên 4 lớp: Blacklist Database (30%), Tầng kỹ thuật mạng (35%), Tầng ngữ cảnh & AI (35%).
   - Tự động phân loại mức độ: `SAFE` (0-39), `SUSPICIOUS` (40-69), `DANGEROUS` (70-100).

2. **Deep URL & Domain Analyzer (3.2 - Điểm nhấn kỹ thuật số 1)**:
   - **Domain Age Lookup**: Truy vấn WHOIS xác định ngày đăng ký và tính tuổi tên miền (Cảnh báo đỏ nếu `< 30 ngày`).
   - **Typosquatting Detection**: Dùng thuật toán khoảng cách chuỗi `Levenshtein` và đối soát với danh sách trắng hơn 20 ngân hàng, sàn TMĐT Việt Nam (Vietcombank, MBBank, Shopee, Techcombank...).
   - **Homoglyph & Punycode Attack**: Phát hiện tiền tố `xn--` và ký tự phi chuẩn giả mạo thị giác.

3. **Bản đồ Xu hướng & Thống kê Thời gian thực (3.3 - Điểm nhấn xã hội 2)**:
   - Dashboard tổng hợp lượt kiểm tra, tỷ lệ ngăn chặn nguy cơ cao.
   - Biểu đồ phân bổ hình thức lừa đảo (Doughnut Chart) và biểu đồ xu hướng 7 ngày (Line Chart) sử dụng Chart.js.
   - Bảng xếp hạng Top số tài khoản ngân hàng và tên miền bị báo cáo nhiều nhất.

4. **Góc Chia Sẻ & Tự Động Che Mờ Thông Tin Cá Nhân (3.4 - ScamGuard & PII Redaction)**:
   - Tự động nhận diện và che mờ số CCCD (12 số), CMND (9 số), số điện thoại cá nhân (10 số), số tài khoản ngân hàng trước khi hiển thị công khai.
   - Hỗ trợ gửi bài ẩn danh và quy trình kiểm duyệt (Moderation).

5. **Gamification & Trắc Nghiệm An Toàn Mạng (3.5)**:
   - Bộ câu hỏi tình huống mô phỏng thực tế (Mạo danh ngân hàng khóa thẻ, Bẫy tuyển CTV giật đơn, Deepfake mượn tiền).
   - Đánh giá câu trả lời kèm phần giải thích cặn kẽ nâng cao nhận thức cho người dùng.

---

## 3. Hướng Dẫn Cài Đặt & Khởi Chạy

### Bước 1: Mở Terminal tại thư mục `E:\PATAWARE`
```powershell
cd E:\PATAWARE
```

### Bước 2: Tạo môi trường ảo Python & Cài đặt thư viện
```powershell
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
```

### Bước 3: Cấu hình biến môi trường (`.env`)
Tạo file `.env` từ mẫu và đặt khóa bí mật riêng dài ít nhất 32 ký tự trước khi chạy:
```powershell
Copy-Item .env.example .env
python -c "import secrets; print(secrets.token_urlsafe(48))"
```
Sao chép giá trị được tạo vào `SECRET_KEY` trong `.env`. Không chia sẻ hoặc commit file `.env`. Hệ thống dùng SQLite `pataware.db` theo mặc định, không bắt buộc cài MySQL.
- Nếu muốn dùng MySQL:
  ```env
  DATABASE_URL=mysql+pymysql://root:password@localhost:3306/pataware_db?charset=utf8mb4
  ```
- Nếu có Google Gemini API Key:
  ```env
  GEMINI_API_KEY=AIzaSy...
  ```

### Bước 4: Khởi chạy hệ thống
```powershell
python run.py
```
Hoặc dùng trực tiếp uvicorn:
```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

---

## 4. Truy Cập Ứng Dụng

- **Giao diện Web Trực Quan**: [http://localhost:8000](http://localhost:8000)
- **Tài liệu API Swagger UI (FastAPI Interactive Docs)**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **Tài liệu API ReDoc**: [http://localhost:8000/redoc](http://localhost:8000/redoc)
