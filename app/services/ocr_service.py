import os
import re
from typing import Optional, Dict, Any
from PIL import Image
import io

try:
    import pytesseract
except ImportError:
    pytesseract = None

try:
    import google.generativeai as genai
except ImportError:
    genai = None

from app.core.config import settings


class OcrService:
    """
    Dịch vụ bóc tách ký tự quang học từ hình ảnh (OCR Image Extractor):
    Bóc tách nội dung văn bản từ ảnh chụp màn hình tin nhắn đáng ngờ, SMS lừa đảo hoặc biên lai chuyển khoản ngân hàng.
    Hỗ trợ làm sạch nhiễu thông số camera, timestamp, ngày giờ hệ thống trước khi chấm điểm rủi ro.
    """

    def __init__(self):
        # Thiết lập đường dẫn thực thi tesseract nếu người dùng cấu hình trong .env
        if pytesseract and settings.TESSERACT_CMD:
            pytesseract.pytesseract.tesseract_cmd = settings.TESSERACT_CMD

    @staticmethod
    def clean_ocr_text(raw_text: str) -> str:
        """
        Lọc bỏ các thông số rác, ngày giờ hệ thống, định dạng camera giám sát / giao thông:
        Loại bỏ các dòng chỉ chứa timestamp, tên thiết bị (CAM, CCTV, HIKVISION), độ phân giải,
        giúp bộ máy chấm điểm rủi ro chỉ tập trung vào nội dung tin nhắn, tài khoản hoặc liên kết thực sự.
        """
        if not raw_text or not raw_text.strip():
            return ""

        # Mẫu nhận diện các dòng chứa thông số camera hoặc ngày giờ thuần túy
        camera_meta_patterns = [
            r'^\s*(?:CAM|CH|CAMERA|CHANNEL|IPC|IPCAM|DEVICE)[-_\s]?\d+.*$',
            r'^\s*(?:HIKVISION|DAHUA|KBVISION|EZVIZ|IMOU|YOOSEE|PANASONIC|BOSCH|SONY|AXIS).{0,30}$',
            r'^\s*(?:NVR|DVR|CCTV|FPS|1080P|720P|4K|HD|FULL\s*HD|H\.26[45]|HEVC).{0,20}$',
            r'^\s*(?:REC|PLAY|LIVE|SPEED|TOC\s*DO|KM/H|LAN\s*DUONG|KM\s*\d+).{0,20}$',
            r'^\s*(?:\d{4}[-/.]\d{1,2}[-/.]\d{1,2}|\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4})\s*(?:[T\s]\s*\d{1,2}:\d{2}(?::\d{2})?(?:\s*(?:AM|PM|SA|CH))?)?\s*$',
            r'^\s*\d{1,2}:\d{2}(?::\d{2})?(?:\s*(?:AM|PM|SA|CH))?\s*$',
            r'^[^a-zA-Z0-9\u00C0-\u1EF9]{1,4}$'  # Dòng chỉ chứa vài ký tự đặc biệt rác
        ]

        cleaned_lines = []
        for line in raw_text.splitlines():
            line_str = line.strip()
            if not line_str:
                continue

            # Kiểm tra xem dòng có khớp hoàn toàn với mẫu rác camera/ngày giờ không
            is_garbage = False
            for pat in camera_meta_patterns:
                if re.match(pat, line_str, re.IGNORECASE):
                    is_garbage = True
                    break

            if not is_garbage:
                # Xóa bớt timestamp ở đầu hoặc cuối dòng nếu có
                inline_cleaned = re.sub(
                    r'(?:\d{4}[-/.]\d{1,2}[-/.]\d{1,2}|\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4})\s*(?:[T\s]\s*\d{1,2}:\d{2}(?::\d{2})?(?:\s*(?:AM|PM|SA|CH))?)?',
                    '',
                    line_str,
                    flags=re.IGNORECASE
                ).strip()

                # Xóa tiếp tag camera inline nếu còn sót
                inline_cleaned = re.sub(r'\b(?:CAM|CH|CHANNEL|CAMERA)[-_\s]?\d+\b', '', inline_cleaned, flags=re.IGNORECASE).strip()

                # Chỉ giữ lại nếu dòng còn ít nhất 2 ký tự chữ/số có nghĩa
                alpha_num_count = len(re.sub(r'[^a-zA-Z0-9\u00C0-\u1EF9]', '', inline_cleaned))
                if alpha_num_count >= 2:
                    cleaned_lines.append(inline_cleaned)

        return "\n".join(cleaned_lines).strip()

    @staticmethod
    def extract_text_from_bytes(image_bytes: bytes) -> Dict[str, Any]:
        """
        Bóc tách văn bản từ mảng byte của tệp hình ảnh:
        Ưu tiên Tesseract OCR cục bộ; nếu Tesseract chưa cài đặt thì tự động dự phòng
        sang Google Gemini Multimodal Vision API để trích xuất văn bản tiếng Việt chính xác.
        """
        raw_text = ""
        source_engine = "none"

        # 1. Thử bóc tách với Tesseract OCR nếu có cấu hình
        if pytesseract:
            try:
                image = Image.open(io.BytesIO(image_bytes))
                if image.mode in ("RGBA", "P"):
                    image = image.convert("RGB")

                try:
                    raw_text = pytesseract.image_to_string(image, lang="vie+eng")
                except Exception:
                    raw_text = pytesseract.image_to_string(image)

                if raw_text and raw_text.strip():
                    source_engine = "tesseract"
            except Exception:
                raw_text = ""

        # 2. Dự phòng thông minh bằng Gemini Vision API nếu Tesseract không cho kết quả
        if (not raw_text or not raw_text.strip()) and genai and settings.GEMINI_API_KEY:
            try:
                from concurrent.futures import ThreadPoolExecutor, TimeoutError as FutureTimeoutError
                genai.configure(api_key=settings.GEMINI_API_KEY)
                image = Image.open(io.BytesIO(image_bytes))
                if image.mode in ("RGBA", "P"):
                    image = image.convert("RGB")

                # Nén giảm kích thước ảnh nếu quá lớn (trên 1000px) để gửi API siêu tốc < 1s
                if image.width > 1000 or image.height > 1000:
                    image.thumbnail((1000, 1000))

                def _call_gemini_vision(img):
                    # Ưu tiên mô hình nhẹ và tốc độ cao nhất
                    for m_name in ["models/gemini-3.8-flash", "models/gemini-2.5-pro", "gemini-1.5-flash", "models/gemini-flash-latest"]:
                        try:
                            g_model = genai.GenerativeModel(m_name)
                            resp = g_model.generate_content([
                                "Đọc và bóc tách chữ viết tiếng Việt, số điện thoại, STK, link trong ảnh (nếu không có thì trả về trống):",
                                img
                            ])
                            txt = getattr(resp, "text", "").strip()
                            if txt:
                                return txt
                        except Exception:
                            continue
                    return ""

                with ThreadPoolExecutor(max_workers=1) as executor:
                    future = executor.submit(_call_gemini_vision, image)
                    res_text = future.result(timeout=3.5)  # Giới hạn tối đa 3.5 giây
                    if res_text:
                        raw_text = res_text
                        source_engine = "gemini_vision"
            except Exception:
                pass

        if not raw_text or not raw_text.strip():
            return {
                "success": False,
                "text": "",
                "raw_text": "",
                "error": "Không bóc tách được văn bản từ hình ảnh."
            }

        cleaned = OcrService.clean_ocr_text(raw_text)

        return {
            "success": True,
            "text": cleaned if cleaned else raw_text.strip(),
            "raw_text": raw_text.strip(),
            "cleaned_text": cleaned,
            "source": source_engine,
            "length": len(cleaned if cleaned else raw_text.strip()),
            "error": None
        }
