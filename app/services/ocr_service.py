import os
from typing import Optional, Dict, Any
from PIL import Image
import io

try:
    import pytesseract
except ImportError:
    pytesseract = None

from app.core.config import settings


class OcrService:
    """
    Dịch vụ bóc tách ký tự quang học từ hình ảnh (OCR Image Extractor):
    Bóc tách nội dung văn bản từ ảnh chụp màn hình tin nhắn đáng ngờ, SMS lừa đảo hoặc biên lai chuyển khoản ngân hàng.
    """

    def __init__(self):
        # Thiết lập đường dẫn thực thi tesseract nếu người dùng cấu hình trong .env
        if pytesseract and settings.TESSERACT_CMD:
            pytesseract.pytesseract.tesseract_cmd = settings.TESSERACT_CMD

    @staticmethod
    def extract_text_from_bytes(image_bytes: bytes) -> Dict[str, Any]:
        """Bóc tách văn bản từ mảng byte của tệp hình ảnh sử dụng thư viện Tesseract OCR."""
        if not pytesseract:
            return {
                "success": False,
                "text": "",
                "error": "Thư viện pytesseract chưa được cấu hình. Vui lòng cài đặt Tesseract-OCR trên máy."
            }

        try:
            image = Image.open(io.BytesIO(image_bytes))
            # Chuyển đổi định dạng ảnh RGBA hoặc Palette sang RGB để Tesseract xử lý ổn định nhất
            if image.mode in ("RGBA", "P"):
                image = image.convert("RGB")

            # Ưu tiên sử dụng mô hình nhận diện tiếng Việt và tiếng Anh (vie+eng)
            try:
                extracted_text = pytesseract.image_to_string(image, lang="vie+eng")
            except Exception:
                extracted_text = pytesseract.image_to_string(image)

            cleaned_text = extracted_text.strip()
            return {
                "success": True,
                "text": cleaned_text,
                "length": len(cleaned_text),
                "error": None
            }
        except Exception as e:
            return {
                "success": False,
                "text": "",
                "error": f"Lỗi xử lý hình ảnh OCR: {str(e)}"
            }
