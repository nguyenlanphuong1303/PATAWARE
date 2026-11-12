import os
import re
from typing import Optional
from dotenv import dotenv_values
from fastapi import APIRouter
from pydantic import BaseModel
import httpx
from app.core.config import settings

try:
    import google.generativeai as genai
except ImportError:
    genai = None

router = APIRouter()


class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    reply: str


def get_active_gemini_key() -> str:
    """Lấy API Key từ file .env hoặc biến môi trường thời gian thực."""
    key = (settings.GEMINI_API_KEY or "").strip()
    if not key:
        env_dict = dotenv_values(".env")
        key = (env_dict.get("GEMINI_API_KEY") or os.getenv("GEMINI_API_KEY") or "").strip()
    return key


# Danh sách kiến thức mẫu để định hướng nội dung cho Gemini (Giúp AI hiểu sâu hơn về nghiệp vụ Pataware)
PATAWARE_GUIDELINES = """
Thông tin nền tảng PATAWARE (Anti-Scam AI & Network Defense):
- Sứ mệnh: Hỗ trợ cộng đồng phát hiện, ngăn chặn và phòng chống lừa đảo trực tuyến tại Việt Nam.
- Các kịch bản lừa đảo phổ biến cần cảnh giác:
  1. Lừa chuyển tiền: Hướng dẫn gọi ngay hotline ngân hàng khóa thẻ/tài khoản, chụp biên lai, báo công an phường hoặc Cục A05, tuyệt đối không tin dịch vụ 'lấy lại tiền bị lừa'.
  2. Mạo danh Công an, Viện kiểm sát, Tòa án đe dọa lệnh bắt/rửa tiền: Khẳng định 100% cơ quan nhà nước không làm việc qua điện thoại/Zalo, yêu cầu cúp máy ngay.
  3. Bẫy cộng tác viên (CTV) Shopee/Lazada/Tiki giật đơn ảo hưởng hoa hồng: Cảnh báo chiêu trò nạp tiền ban đầu trả hoa hồng nhỏ rồi lừa số tiền lớn.
  4. Deepfake gọi video giả mạo người thân mượn tiền: Hướng dẫn gọi điện xác nhận qua sóng SIM thông thường.
  5. Link/Website giả mạo: Hướng dẫn sử dụng tính năng 'Kiểm Tra Toàn Diện Ngay' trên Pataware để quét WHOIS và tuổi tên miền.
"""


def call_gemini_smart(prompt: str, api_key: str) -> Optional[str]:
    """
    Gọi trực tiếp Google Gemini REST API với các model mới và thiết lập tính cách linh hoạt.
    """
    # Thử tối đa 2 model nhanh nhất để tránh kéo dài thời gian phản hồi khi mạng lag
    models = ["gemini-1.5-flash", "gemini-2.0-flash"]
    timeout_cfg = httpx.Timeout(connect=1.5, read=3.5, write=1.5, pool=1.5)
    
    system_instruction = (
        "Bạn là Trợ lý Trí tuệ Nhân tạo PATAWARE (Anti-Scam AI & Network Defense) - chuyên gia an ninh mạng thông minh. "
        "Hãy tư vấn cho người dùng một cách trực tiếp, ngắn gọn (1-3 câu), vào thẳng trọng tâm vấn đề. "
        "Tuyệt đối KHÔNG lặp lại câu hỏi của người dùng, KHÔNG đưa ra văn mẫu lan man ngoài lề. "
        "Nền tảng PATAWARE hiện có lưu trữ lịch sử cuộc trò chuyện và lịch sử tìm kiếm/quét rủi ro trên trình duyệt của người dùng.\n"
        f"{PATAWARE_GUIDELINES}"
    )

    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "system_instruction": {"parts": [{"text": system_instruction}]},
        "generationConfig": {
            "temperature": 0.7,  # Tăng tính sáng tạo và tự nhiên cho câu trả lời
            "maxOutputTokens": 1000,
        }
    }

    for m in models:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{m}:generateContent?key={api_key}"
        try:
            with httpx.Client(timeout=timeout_cfg) as client:
                res = client.post(url, json=payload, headers={"Content-Type": "application/json"})
                if res.status_code == 200:
                    data = res.json()
                    candidates = data.get("candidates", [])
                    if candidates:
                        parts = candidates[0].get("content", {}).get("parts", [])
                        if parts and "text" in parts[0]:
                            return parts[0]["text"].strip()
                elif res.status_code in (401, 403):
                    # Khóa API không hợp lệ hoặc bị cấm, dừng ngay lập tức không thử tiếp
                    break
        except (httpx.TimeoutException, httpx.RequestError):
            continue
        except Exception:
            continue
    return None


@router.post("", response_model=ChatResponse)
@router.post("/", response_model=ChatResponse)
def handle_chat(req: ChatRequest):
    """
    Điểm cuối tiếp nhận tin nhắn trò chuyện với Trợ lý AI PATAWARE.
    Luôn ưu tiên sử dụng Gemini AI để sinh câu trả lời thông minh, linh hoạt như ChatGPT.
    """
    user_msg = (req.message or "").strip()
    if not user_msg:
        return ChatResponse(reply="👋 Chào bạn! Tôi là Trợ lý AI PATAWARE. Bạn cần tư vấn về vấn đề an toàn mạng hay kiểm tra rủi ro nào hôm nay?")

    print(f"[*] Nhận câu hỏi từ người dùng: '{user_msg}'")

    api_key = get_active_gemini_key()

    # 1. ƯU TIÊN SỐ 1: Luôn gọi Gemini AI để có câu trả lời linh hoạt, thông minh như ChatGPT
    if api_key:
        ai_reply = call_gemini_smart(user_msg, api_key)
        if ai_reply:
            print("[+] Đã trả lời thông minh qua Gemini API thành công!")
            return ChatResponse(reply=ai_reply)

    # 2. PHÒNG HỜ (FALLBACK): Chỉ dùng khi mất API key hoặc lỗi mạng không gọi được Google Gemini
    print("[!] Không gọi được Gemini API, chuyển sang cơ chế dự phòng khẩn cấp.")
    
    # Bạn có thể giữ lại một vài phản hồi cơ bản nhất cho trường hợp ngoại lệ mất mạng
    lowered = user_msg.lower()
    if any(k in lowered for k in ["lịch sử", "lưu tin nhắn", "lưu cuộc trò chuyện"]):
        return ChatResponse(
            reply="Cuộc trò chuyện này và lịch sử tìm kiếm đã được lưu trữ tự động trên trình duyệt của bạn. Bạn có thể xem lại hoặc bấm biểu tượng thùng rác để xóa khi muốn."
        )

    if any(k in lowered for k in ["bị lừa", "chuyển tiền", "mất tiền"]):
        return ChatResponse(
            reply="🚨 Hãy gọi ngay hotline ngân hàng để khóa tài khoản, lưu lại biên lai và đến cơ quan công an trình báo ngay lập tức!"
        )

    return ChatResponse(
        reply="Hiện tại hệ thống AI đang bận. Bạn hãy nhập thông tin cụ thể (SĐT, STK, Link) vào ô tìm kiếm để kiểm tra an toàn nhé!"
    )