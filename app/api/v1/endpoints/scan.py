import hashlib
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, Request
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.scan_log import ScanLog
from app.schemas.scan import ScanRequest, ScanResponse
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


@router.post("/ocr-inspect", response_model=ScanResponse)
async def inspect_image_ocr(
    request: Request,
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """
    Điểm cuối kiểm tra bằng bóc tách hình ảnh (OCR):
    Tiếp nhận ảnh chụp màn hình tin nhắn hoặc biên lai, bóc tách chữ qua Tesseract và chấm điểm rủi ro.
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Tệp tải lên phải là định dạng hình ảnh (.png, .jpg, .jpeg)")

    contents = await file.read()
    ocr_result = OcrService.extract_text_from_bytes(contents)

    if not ocr_result["success"] or not ocr_result["text"]:
        raise HTTPException(
            status_code=400,
            detail=ocr_result.get("error") or "Không bóc tách được ký tự từ hình ảnh tải lên."
        )

    extracted_text = ocr_result["text"]
    engine = HybridRiskEngine(db)
    result = engine.evaluate(extracted_text, "image")

    # Lưu nhật ký quét ảnh vào database
    client_ip = request.client.host if request.client else "unknown"
    ip_hash = hashlib.sha256(client_ip.encode()).hexdigest()[:16]

    log_entry = ScanLog(
        input_type="image",
        raw_input=f"[Ảnh OCR: {file.filename}] " + extracted_text[:400],
        risk_score=result.risk_score,
        risk_level=result.risk_level,
        ai_verdict=result.verdict_summary,
        client_ip_hash=ip_hash
    )
    db.add(log_entry)
    db.commit()

    return result
