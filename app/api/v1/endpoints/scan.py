import hashlib
from typing import List, Optional
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, Request
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.scan_log import ScanLog
import re
from app.schemas.scan import ScanRequest, ScanResponse, QuickCheckRequest, QuickCheckResponse, RiskBreakdown
from app.services.risk_engine import HybridRiskEngine
from app.services.ocr_service import OcrService

router = APIRouter()


@router.post("/inspect", response_model=ScanResponse)
def inspect_target(request: Request, scan_req: ScanRequest, db: Session = Depends(get_db)):
    """
    Điểm cuối (Endpoint) kiểm tra rủi ro đa tầng:
    Đánh giá mức độ rủi ro của URL, Số điện thoại, Số tài khoản ngân hàng hoặc Tin nhắn văn bản.
    """
    engine = HybridRiskEngine(db)
    result = engine.evaluate(scan_req.content, scan_req.input_type)

    # Ẩn danh hóa địa chỉ IP của người dùng để bảo vệ quyền riêng tư
    client_ip = request.client.host if request.client else "unknown"
    ip_hash = hashlib.sha256(client_ip.encode()).hexdigest()[:16]

    # Lưu kết quả vào cơ sở dữ liệu scan_logs để thống kê xu hướng thời gian thực
    domain_age = result.domain_analysis.age_days if result.domain_analysis else None
    is_new = result.domain_analysis.is_new_domain if result.domain_analysis else False
    is_typo = result.domain_analysis.typosquatting_detected if result.domain_analysis else False
    impersonated = result.domain_analysis.impersonated_brand if result.domain_analysis else None
    is_homo = result.domain_analysis.is_punycode_homoglyph if result.domain_analysis else False

    log_entry = ScanLog(
        input_type=scan_req.input_type,
        raw_input=scan_req.content[:500],
        risk_score=result.risk_score,
        risk_level=result.risk_level,
        domain_age_days=domain_age,
        is_new_domain=is_new,
        is_typosquatting=is_typo,
        target_brand=impersonated,
        is_homoglyph=is_homo,
        is_blacklist_matched=(result.breakdown.blacklist_score >= 100),
        ai_verdict=result.verdict_summary,
        client_ip_hash=ip_hash
    )
    db.add(log_entry)
    db.commit()

    return result


def filter_and_evaluate_image_content(combined_text: str, engine: HybridRiskEngine, db: Session) -> ScanResponse:
    """
    Bộ lọc và đánh giá nội dung hình ảnh OCR:
    - Loại bỏ các dòng thông số rác, ngày giờ hệ thống, định dạng camera giám sát/giao thông qua clean_ocr_text.
    - Nếu tổng số ký tự quá ít hoặc văn bản chỉ chứa thông tin thông thường (không có từ khóa lừa đảo nhạy cảm
      như chuyển cọc, nhiệm vụ hoa hồng, mạo danh cơ quan chức năng, không có liên kết rủi ro), hệ thống tự động
      gán điểm rủi ro về mức thấp (SAFE) và KHÔNG xếp loại DANGEROUS một cách cảm tính.
    - Nếu phát hiện từ khóa lừa đảo rõ ràng hoặc đường link độc hại, hệ thống kích hoạt HybridRiskEngine đánh giá chi tiết.
    """
    cleaned_text = OcrService.clean_ocr_text(combined_text)
    lower_text = cleaned_text.lower()

    # Nhóm từ khóa nhận diện hành vi lừa đảo trực tuyến tại Việt Nam
    SCAM_REGEX_PATTERNS = [
        # Nhóm bẫy tài chính & tuyển dụng cộng tác viên
        r'(?:cộng\s*tác\s*viên|giật\s*đơn|làm\s*nhiệm\s*vụ|hoa\s*hồng\s*\d+%|tiền\s*cọc|đặt\s*cọc|nạp\s*tiền\s*(?:vào|để)|hoàn\s*tiền\s*đơn|việc\s*nhẹ\s*lương\s*cao)',
        # Nhóm mạo danh cơ quan công quyền / đe dọa hình sự
        r'(?:công\s*an|viện\s*kiểm\s*sát|tòa\s*án|bộ\s*công\s*an|lệnh\s*bắt|khởi\s*tố|phong\s*tỏa\s*tài\s*khoản|rửa\s*tiền|ma\s*túy|điều\s*tra\s*án)',
        # Nhóm chiếm đoạt OTP / thông tin xác thực
        r'(?:mã\s*otp|cung\s*cấp\s*otp|gửi\s*mã\s*xác\s*thực|nhập\s*mật\s*khẩu|xác\s*nhận\s*mã\s*giao\s*dịch)',
        # Nhóm đe dọa khóa thẻ / tài khoản khẩn cấp
        r'(?:khóa\s*tài\s*khoản|khóa\s*thẻ|trong\s*vòng\s*\d+\s*(?:giờ|phút)|hết\s*hạn\s*sau|tạm\s*ngừng\s*dịch\s*vụ)',
        # Nhóm bẫy đầu tư tài chính siêu lợi nhuận
        r'(?:bao\s*lỗ|cam\s*kết\s*lợi\s*nhuận|lãi\s*suất\s*\d+%/ngày|sàn\s*quốc\s*tế|đầu\s*tư\s*forex|nhóm\s*vip)',
        # Nhóm mạo danh kích hoạt định danh VNeID
        r'(?:định\s*danh\s*mức\s*2|cập\s*nhật\s*vneid|kích\s*hoạt\s*lại\s*tài\s*khoản)',
        # Nhóm trúng thưởng / tri ân mồi chài nạp phí
        r'(?:trúng\s*thưởng|quà\s*tri\s*ân|nhận\s*thưởng\s*miễn\s*phí|chuyển\s*phí\s*nhận\s*quà)'
    ]

    matched_scam_tactics = []
    for pat in SCAM_REGEX_PATTERNS:
        matches = re.findall(pat, lower_text)
        if matches:
            matched_scam_tactics.extend(matches)

    # Kiểm tra liên kết lạ hoặc tên miền rủi ro cao
    suspicious_url_match = re.search(
        r'(?:https?://|www\.)[^\s]+|\b[a-zA-Z0-9-]+\.(?:xyz|top|site|vip|club|tk|ml|ga|cf|gq|cam|online|info|cc)\b',
        lower_text
    )

    # Kiểm tra trong cơ sở dữ liệu Blacklist nội bộ
    has_blacklist_match = False
    if suspicious_url_match:
        from app.models.blacklist import Blacklist
        cand = suspicious_url_match.group(0).lower()
        if db.query(Blacklist).filter(Blacklist.value.contains(cand)).first():
            has_blacklist_match = True

    # 1. ĐIỀU KIỆN ÉP VỀ AN TOÀN (SAFE):
    # Nếu không phát hiện bất kỳ từ khóa lừa đảo rõ ràng nào, không có URL độc hại và không khớp Blacklist
    # (Ví dụ: ảnh phong cảnh, ảnh camera giao thông chỉ có thông số xe cộ/ngày giờ, hóa đơn hợp pháp, tài liệu hành chính)
    if not matched_scam_tactics and not suspicious_url_match and not has_blacklist_match:
        return ScanResponse(
            input_type="image",
            target=combined_text[:300],
            risk_score=12.0,
            risk_level="SAFE",
            verdict_summary="AN TOÀN - Nội dung hình ảnh tài liệu, phong cảnh hoặc thông số thiết bị thông thường; không ghi nhận từ khóa lừa đảo hay dấu hiệu thao túng tài chính.",
            breakdown=RiskBreakdown(
                blacklist_score=0.0,
                technical_domain_score=0.0,
                heuristic_regex_score=10.0,
                ai_psychological_score=10.0
            ),
            domain_analysis=None,
            recommendations=[
                "Hình ảnh an toàn, không chứa thông tin đe dọa, giục chuyển cọc hay yêu cầu mã OTP.",
                "Vẫn luôn chú ý nguyên tắc bảo mật: Không cung cấp mã xác thực OTP hay mật khẩu cho bất kỳ ai."
            ],
            scam_indicators=[]
        )

    # 2. NẾU CÓ DẤU HIỆU LỪA ĐẢO RÕ RÀNG HOẶC LIÊN KẾT NGUY HẠI:
    # Gửi sang HybridRiskEngine để tính toán đa tầng
    result = engine.evaluate(cleaned_text if cleaned_text else combined_text, "image")

    # Đảm bảo nếu từ khóa lừa đảo nguy hiểm xuất hiện thì điểm rủi ro phải đạt mức DANGEROUS tương xứng
    if matched_scam_tactics and result.risk_score < 70.0:
        result.risk_score = max(result.risk_score, 82.0)
        result.risk_level = "DANGEROUS"
        unique_tactics = list(dict.fromkeys(matched_scam_tactics))
        result.verdict_summary = f"NGUY HIỂM CAO - Phát hiện các từ khóa lừa đảo trong hình ảnh: {', '.join(unique_tactics[:3])}."
        for tac in unique_tactics[:3]:
            result.scam_indicators.append(f"Từ khóa phát hiện: '{tac}'")

    return result


@router.post("/ocr-inspect", response_model=ScanResponse)
async def inspect_image_ocr(
    request: Request,
    file: Optional[UploadFile] = File(None),
    files: Optional[List[UploadFile]] = File(None),
    extra_text: Optional[str] = Form(None),
    db: Session = Depends(get_db)
):
    """
    Điểm cuối kiểm tra bằng bóc tách hình ảnh (OCR):
    Hỗ trợ tiếp nhận một hoặc nhiều ảnh chụp màn hình (tin nhắn, biên lai, mã QR hoặc đường link),
    bóc tách chữ qua Tesseract OCR và chấm điểm rủi ro đa tầng toàn diện.
    """
    all_files: List[UploadFile] = []
    if files:
        for f in files:
            if f and f.filename:
                all_files.append(f)
    if file and file.filename and file not in all_files:
        all_files.append(file)

    # Dự phòng trích xuất từ form nếu client gửi dạng khác
    if not all_files:
        try:
            form_data = await request.form()
            for key, val in form_data.multi_items():
                if isinstance(val, UploadFile) and val.filename and val not in all_files:
                    all_files.append(val)
        except Exception:
            pass

    if not all_files:
        raise HTTPException(
            status_code=400,
            detail="Vui lòng đính kèm ít nhất một tệp hình ảnh (.png, .jpg, .jpeg, .webp) để quét OCR."
        )

    image_texts = []
    valid_file_names = []

    for idx, img_file in enumerate(all_files, 1):
        filename = img_file.filename or f"image_{idx}.png"
        is_image = (img_file.content_type and img_file.content_type.startswith("image/")) or \
                   filename.lower().endswith(('.png', '.jpg', '.jpeg', '.webp', '.bmp', '.gif'))
        if not is_image:
            continue

        valid_file_names.append(filename)
        contents = await img_file.read()
        ocr_result = OcrService.extract_text_from_bytes(contents)
        if ocr_result.get("success") and ocr_result.get("text"):
            extracted = ocr_result["text"].strip()
            if extracted:
                image_texts.append(f"--- [Hình ảnh {idx}: {filename}] ---\n{extracted}")

    if not image_texts:
        if extra_text and extra_text.strip():
            combined_text = extra_text.strip()
        else:
            raise HTTPException(
                status_code=400,
                detail="Không bóc tách được ký tự từ các hình ảnh tải lên. Vui lòng kiểm tra chất lượng hình ảnh hoặc đảm bảo ảnh có chứa chữ rõ nét."
            )
    else:
        combined_text = "\n\n".join(image_texts)
        if extra_text and extra_text.strip():
            combined_text = f"Ghi chú kèm theo: {extra_text.strip()}\n\n" + combined_text

    engine = HybridRiskEngine(db)
    result = filter_and_evaluate_image_content(combined_text, engine, db)

    file_count = len(valid_file_names)
    if file_count > 1:
        result.target = f"[{file_count} ảnh] {', '.join(valid_file_names[:3])}{'...' if file_count > 3 else ''}"
    elif file_count == 1:
        result.target = f"[1 ảnh] {valid_file_names[0]}"

    # Lưu nhật ký quét ảnh vào database
    client_ip = request.client.host if request.client else "unknown"
    ip_hash = hashlib.sha256(client_ip.encode()).hexdigest()[:16]

    log_entry = ScanLog(
        input_type="image",
        raw_input=f"[Quét {file_count} ảnh: {', '.join(valid_file_names[:3])}] " + combined_text[:400],
        risk_score=result.risk_score,
        risk_level=result.risk_level,
        ai_verdict=result.verdict_summary,
        client_ip_hash=ip_hash
    )
    db.add(log_entry)
    db.commit()

    return result


@router.post("/quick-check", response_model=QuickCheckResponse)
def quick_check_url(scan_req: QuickCheckRequest, db: Session = Depends(get_db)):
    """
    Điểm cuối kiểm tra thời gian thực siêu tốc phục vụ Real-time Interception cho Extension (Độ trễ < 30ms):
    1. Kiểm tra Blacklist nội bộ Pataware (< 1ms)
    2. Kiểm tra bộ lọc Parental Control (Cờ bạc, nội dung người lớn 18+) (< 1ms)
    3. Phân tích Homoglyph & Typosquatting (Levenshtein) (< 2ms)
    4. Tra cứu nhanh Threat Intelligence (có timeout bảo vệ)
    Bỏ qua WHOIS sâu và phân tích LLM AI để đảm bảo phản hồi tức thì trước khi trang web tải xong.
    """
    from urllib.parse import urlparse
    from app.services.url_analyzer import DeepUrlAnalyzer
    from app.services.threat_intel import ThreatIntelService
    from app.services.content_filter import ParentalControlFilter
    from app.models.blacklist import Blacklist
    import tldextract

    raw_url = scan_req.url.strip()
    if not raw_url.startswith("http://") and not raw_url.startswith("https://"):
        clean_url = "https://" + raw_url
    else:
        clean_url = raw_url

    parsed = urlparse(clean_url)
    domain = parsed.hostname or clean_url
    domain_lower = domain.lower()

    reasons = []
    category = "SAFE"
    risk_score = 0.0

    # 1. Kiểm tra Bộ lọc Parental Control (Cờ bạc & 18+)
    parental = ParentalControlFilter.check_content_or_url(clean_url)
    if parental.get("is_flagged"):
        category = parental.get("category", "GAMBLING")
        risk_score = max(risk_score, float(parental.get("risk_score", 95.0)))
        reasons.append(parental.get("reason"))

    # 2. Kiểm tra Blacklist Database nội bộ
    extracted = tldextract.extract(clean_url)
    reg_domain = (extracted.registered_domain or "").strip().lower()
    candidates = [c for c in [domain_lower, reg_domain, clean_url] if c]

    matched_bl = db.query(Blacklist).filter(
        Blacklist.type.in_(["domain", "url"]),
        Blacklist.value.in_(candidates)
    ).first()

    if matched_bl:
        category = "PHISHING"
        risk_score = 100.0
        reasons.append(f"Tên miền nằm trong danh sách đen cảnh báo ({matched_bl.reason or 'Lừa đảo trực tuyến'}).")

    # 3. Phân tích kỹ thuật nhẹ: Punycode & Typosquatting Levenshtein
    domain_info = DeepUrlAnalyzer.extract_domain_info(clean_url)
    homoglyph_res = DeepUrlAnalyzer.check_homoglyph_and_punycode(domain_info)
    typosquat_res = DeepUrlAnalyzer.check_typosquatting(domain_info)

    if homoglyph_res.get("is_homoglyph"):
        risk_score = max(risk_score, 90.0)
        category = "PHISHING"
        reasons.extend(homoglyph_res.get("reasons", []))

    if typosquat_res.get("typosquatting_detected"):
        risk_score = max(risk_score, 92.0)
        category = "PHISHING"
        reasons.extend(typosquat_res.get("reasons", []))

    # 4. Tra cứu nhanh Threat Intel nếu chưa phát hiện nguy cơ cao
    if risk_score < 70:
        intel_service = ThreatIntelService()
        intel = intel_service.check_url_intel(clean_url)
        if intel.get("is_malicious"):
            risk_score = max(risk_score, float(intel.get("score_penalty", 95.0)))
            category = "PHISHING"
            reasons.append(f"Cảnh báo tình báo mạng ({intel.get('source')}): {intel.get('detail')}")

    is_malicious = risk_score >= 70
    if is_malicious:
        risk_level = "DANGEROUS"
    elif risk_score >= 40:
        risk_level = "SUSPICIOUS"
    else:
        risk_level = "SAFE"

    return QuickCheckResponse(
        url=clean_url,
        domain=domain,
        is_malicious=is_malicious,
        risk_score=risk_score,
        risk_level=risk_level,
        category=category,
        reasons=reasons
    )


@router.get("/history")
def get_scan_history(limit: int = 10, db: Session = Depends(get_db)):
    """
    Điểm cuối lấy danh sách nhật ký các lượt kiểm tra quét rủi ro gần nhất từ cơ sở dữ liệu.
    """
    logs = db.query(ScanLog).order_by(ScanLog.created_at.desc()).limit(limit).all()
    return [
        {
            "id": log.id,
            "input_type": log.input_type,
            "raw_input": log.raw_input,
            "risk_score": log.risk_score,
            "risk_level": log.risk_level,
            "ai_verdict": log.ai_verdict,
            "created_at": log.created_at.strftime("%H:%M %d/%m/%Y") if log.created_at else None
        }
        for log in logs
    ]

