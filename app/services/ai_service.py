import os
import json
import re
from typing import Dict, Any, List
from app.core.config import settings

try:
    import google.generativeai as genai
except ImportError:
    genai = None


class AiAnalysisService:
    """
    Dịch vụ phân tích ngữ cảnh và hành vi thao túng tâm lý bằng Trí tuệ nhân tạo (AI):
    Nhận diện các kịch bản lừa đảo kỹ thuật xã hội (tạo áp lực thời gian, lòng tham, nỗi sợ hãi, mạo danh cơ quan chức năng).
    Sử dụng Google Gemini API nếu có cấu hình khóa API; tự động chuyển sang bộ giải thuật Heuristic chuyên sâu nếu chưa có khóa.
    """

    def __init__(self):
        from dotenv import dotenv_values
        self.api_key = settings.GEMINI_API_KEY or os.getenv("GEMINI_API_KEY") or dotenv_values(".env").get("GEMINI_API_KEY")
        if genai and self.api_key:
            genai.configure(api_key=self.api_key)
            try:
                self.model = genai.GenerativeModel("models/gemini-3.8-flash")
            except Exception:
                self.model = genai.GenerativeModel("gemini-3.8-flash")
        else:
            self.model = None

    def analyze_scam_context(self, content: str, input_type: str = "text") -> Dict[str, Any]:
        """
        Phân tích nội dung để phát hiện các dấu hiệu thao túng tâm lý và kịch bản lừa đảo.
        """
        if not content or not content.strip():
            return {
                "score": 0,
                "tactics_detected": [],
                "verdict": "Nội dung trống, không đủ dữ liệu đánh giá.",
                "confidence": 0.0
            }

        # Nếu đã cấu hình Gemini API thì gọi mô hình ngôn ngữ lớn LLM
        if self.model:
            try:
                return self._analyze_with_gemini(content, input_type)
            except Exception:
                # Nếu kết nối API bị lỗi, tự động chuyển sang bộ phân tích Heuristic dự phòng
                return self._analyze_with_heuristic(content, input_type)

        return self._analyze_with_heuristic(content, input_type)

    def _analyze_with_gemini(self, content: str, input_type: str) -> Dict[str, Any]:
        """Phân tích chuyên sâu thông qua Google Gemini LLM API."""
        prompt = f"""
        Bạn là chuyên gia an ninh mạng phân tích lừa đảo trực tuyến tại Việt Nam.
        Hãy phân tích nội dung sau (Loại dữ liệu: {input_type}):
        ---
        {content}
        ---
        Đánh giá các khía cạnh:
        1. Thao túng tâm lý (tạo áp lực thời gian, đe dọa công an/tòa án, dụ dỗ hoa hồng cao, yêu cầu cung cấp OTP, mật khẩu, chuyển tiền cọc).
        2. Chấm điểm rủi ro từ 0 (Hoàn toàn an toàn) đến 100 (Chắc chắn lừa đảo).
        
        Trả về DUY NHẤT một chuỗi JSON hợp lệ theo format:
        {{
            "score": <số nguyên từ 0-100>,
            "tactics_detected": [<danh sách các thủ đoạn phát hiện được>],
            "verdict": "<nhận xét súc tích bằng tiếng Việt>",
            "confidence": <số thập phân từ 0.0 - 1.0>
        }}
        """
        response = self.model.generate_content(prompt)
        text_resp = response.text.strip()
        # Loại bỏ các ký tự bọc markdown codeblock nếu có
        text_resp = re.sub(r'^```json\s*', '', text_resp)
        text_resp = re.sub(r'\s*```$', '', text_resp)
        parsed = json.loads(text_resp)
        return {
            "score": float(parsed.get("score", 0)),
            "tactics_detected": parsed.get("tactics_detected", []),
            "verdict": parsed.get("verdict", "Phân tích bởi Gemini AI"),
            "confidence": float(parsed.get("confidence", 0.85))
        }

    def _analyze_with_heuristic(self, content: str, input_type: str) -> Dict[str, Any]:
        """
        Bộ quy tắc phân tích Heuristic dựa trên các kịch bản lừa đảo trực tuyến thực tế tại Việt Nam.
        """
        lowered = content.lower()
        score = 0
        tactics = []

        patterns = [
            (
                r'(công an|viện kiểm sát|tòa án|bộ công an|lệnh bắt|khởi tố|rửa tiền|ma túy)',
                35,
                "Mạo danh cơ quan tư pháp/công an đe dọa bắt giữ"
            ),
            (
                r'(cộng tác viên|nhiệm vụ|hoa hồng|shopee|lazada|tiki|nạp tiền|nhận thưởng|việc nhẹ lương cao)',
                30,
                "Bẫy tuyển cộng tác viên làm nhiệm vụ giật đơn hưởng hoa hồng"
            ),
            (
                r'(otp|mã xác thực|mật khẩu|pass|cung cấp mã|gửi mã|mã xác nhận)',
                40,
                "Yêu cầu cung cấp mã xác thực OTP / mật khẩu ngân hàng"
            ),
            (
                r'(khóa tài khoản|trong vòng \d+ giờ|ngay lập tức|hết hạn|khẩn cấp|nếu không sẽ bị)',
                25,
                "Tạo áp lực thời gian khẩn cấp, hù dọa khóa dịch vụ"
            ),
            (
                r'(đầu tư|lợi nhuận|bao lỗ|cam kết|lãi suất \d+%|sàn quốc tế|tiền ảo|forex)',
                30,
                "Kêu gọi đầu tư tài chính ảo cam kết lợi nhuận bất thường"
            ),
            (
                r'(vneid|định danh mức 2|kích hoạt lại|cập nhật thông tin cư trú)',
                25,
                "Mạo danh cán bộ hướng dẫn cập nhật thông tin VNeID"
            ),
            (
                r'(chuyển khoản gấp|mượn tiền|tài khoản bị lỗi|chuyển cọc)',
                20,
                "Mượn tiền khẩn cấp hoặc yêu cầu chuyển tiền đặt cọc"
            )
        ]

        for regex, weight, tactic in patterns:
            if re.search(regex, lowered):
                score += weight
                tactics.append(tactic)

        score = min(score, 100)
        verdict = ""
        if score >= 70:
            verdict = "Nội dung mang dấu hiệu thao túng tâm lý lừa đảo cực kỳ rõ rệt."
        elif score >= 40:
            verdict = "Nội dung có chứa một số từ khóa đáng ngờ, người dùng cần đề cao cảnh giác."
        else:
            verdict = "Chưa phát hiện dấu hiệu thao túng tâm lý hoặc thủ đoạn lừa đảo phổ biến."

        return {
            "score": score,
            "tactics_detected": tactics,
            "verdict": verdict,
            "confidence": 0.80
        }
