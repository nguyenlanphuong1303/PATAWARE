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


# Kịch bản tư vấn kiến thức an ninh mạng tức thì (phản hồi siêu tốc < 0.1s)
KNOWLEDGE_BASE = [
    (
        r'^(chào|hi|hello|alo|ơi|hey|bạn ơi|xin chào|chao ban|chào bạn)',
        "👋 **Chào bạn! Tôi là Trợ lý AI Pataware**, chuyên gia tư vấn an toàn mạng và phòng chống lừa đảo trực tuyến tại Việt Nam.\n\n"
        "Tôi có thể hỗ trợ bạn:\n"
        "• 🔍 Kiểm tra số tài khoản ngân hàng, số điện thoại hoặc đường link có an toàn không.\n"
        "• ⚠️ Nhận diện các bẫy lừa đảo: Mạo danh công an, bẫy việc làm CTV Shopee/TikTok, video Deepfake...\n"
        "• 🚨 Hướng dẫn xử lý khẩn cấp khi lỡ chuyển tiền cho kẻ gian.\n\n"
        "Bạn đang gặp tình huống nào cần hỗ trợ?"
    ),
    (
        r'(bạn là ai|giới thiệu|pataware là gì|là ai|ai đấy)',
        "🤖 Tôi là **Trợ lý Trí tuệ Nhân tạo PATAWARE** (Anti-Scam AI & Network Defense).\n"
        "Sứ mệnh của tôi là hỗ trợ cộng đồng phát hiện, ngăn chặn và phòng chống các hình thức lừa đảo trực tuyến tại Việt Nam."
    ),
    (
        r'(bị lừa|lỡ chuyển|chuyển tiền|mất tiền|lấy lại tiền|lừa tiền|chuyển khoản nhầm)',
        "🚨 **HƯỚNG DẪN XỬ LÝ KHẨN CẤP KHI BỊ LỪA CHUYỂN TIỀN:**\n\n"
        "1. **Liên hệ ngay ngân hàng:** Gọi đường dây nóng (Hotline) ngân hàng bạn vừa chuyển tiền để yêu cầu khóa thẻ và đề nghị hỗ trợ phong tỏa tài khoản thụ hưởng (nếu kịp).\n"
        "2. **Thu thập bằng chứng:** Chụp toàn bộ biên lai chuyển khoản, nội dung tin nhắn đe dọa/dụ dỗ, số tài khoản và số điện thoại của kẻ gian.\n"
        "3. **Báo cơ quan công an:** Đến trực tiếp Công an phường/quận nơi bạn cư trú hoặc gửi đơn tố giác đến Cục An ninh mạng (A05 - Bộ Công an).\n"
        "⚠️ *Lưu ý tuyệt đối: Không tin các dịch vụ 'hỗ trợ lấy lại tiền bị lừa' trên mạng, 100% đều là bẫy lừa đảo lần hai!*"
    ),
    (
        r'(công an|viện kiểm sát|tòa án|lệnh bắt|khởi tố|đe dọa|rửa tiền|ma túy)',
        "⚠️ **CẢNH BÁO 100% LỪA ĐẢO TỐNG TIỀN:**\n\n"
        "Cơ quan Công an, Viện kiểm sát và Tòa án **KHÔNG BAO GIỜ** làm việc, thông báo lệnh bắt hoặc yêu cầu người dân chuyển tiền 'chứng minh trong sạch' qua điện thoại, Zalo hay Telegram.\n\n"
        "👉 **Hành động ngay:** Hãy cúp máy ngay lập tức và tuyệt đối không chuyển bất kỳ khoản tiền nào!"
    ),
    (
        r'(cộng tác viên|ctv|nhiệm vụ|giật đơn|hoa hồng|shopee|lazada|tiki|nạp tiền)',
        "⚠️ **BẪY TUYỂN CỘNG TÁC VIÊN LÀM NHIỆM VỤ:**\n\n"
        "Đây là kịch bản lừa đảo cực kỳ phổ biến: Kẻ gian mời bạn làm CTV giật đơn Shopee/Lazada hưởng hoa hồng 10-20%. Sau vài đơn đầu nạp tiền ít được hoàn tiền thật, họ sẽ yêu cầu nạp hàng chục đến hàng trăm triệu rồi khóa liên lạc.\n\n"
        "👉 **Tuyệt đối KHÔNG nạp thêm tiền** với hy vọng gỡ gạc, hãy dừng lại ngay!"
    ),
    (
        r'(deepfake|gọi video|khuôn mặt|mượn tiền|giật cục)',
        "🎭 **CẢNH BÁO CUỘC GỌI VIDEO DEEPFAKE:**\n\n"
        "Kẻ gian dùng AI ghép mặt người thân gọi video chỉ 5-10 giây với lý do 'mạng yếu' rồi tắt máy, sau đó nhắn tin gửi số tài khoản lạ để mượn tiền.\n\n"
        "👉 **Cách xử lý:** Gọi điện thoại thông thường (qua sóng SIM) trực tiếp tới số cá nhân của người thân để xác nhận danh tính trước khi chuyển tiền."
    ),
    (
        r'(link|đường dẫn|website|trang web|url|kiểm tra link)',
        "🔍 **KIỂM TRA ĐƯỜNG LINK AN TOÀN:**\n\n"
        "Bạn hãy sao chép đường link nghi vấn đó và dán trực tiếp vào ô tìm kiếm **'Kiểm Tra Toàn Diện Ngay'** ở đầu trang web PATAWARE. Hệ thống sẽ bóc tách kỹ thuật WHOIS, tuổi tên miền và phát hiện mạo danh ngân hàng ngay lập tức!"
    )
]


def call_gemini_fast(prompt: str, api_key: str) -> Optional[str]:
    """
    Gọi trực tiếp Google Gemini REST API với giới hạn thời gian (Timeout 3.5s).
    Tránh tình trạng thư viện gRPC bị treo (hanging) vô thời hạn.
    """
    models = ["gemini-flash-latest", "gemini-2.5-pro", "gemini-2.5-flash", "gemini-2.0-flash"]
    payload = {
        "contents": [{"parts": [{"text": prompt}]}]
    }

    for m in models:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{m}:generateContent?key={api_key}"
        try:
            with httpx.Client(timeout=3.5) as client:
                res = client.post(url, json=payload, headers={"Content-Type": "application/json"})
                if res.status_code == 200:
                    data = res.json()
                    candidates = data.get("candidates", [])
                    if candidates:
                        parts = candidates[0].get("content", {}).get("parts", [])
                        if parts and "text" in parts[0]:
                            return parts[0]["text"].strip()
        except Exception:
            continue
    return None


@router.post("", response_model=ChatResponse)
@router.post("/", response_model=ChatResponse)
def handle_chat(req: ChatRequest):
    """
    Điểm cuối tiếp nhận tin nhắn trò chuyện với Trợ lý AI PATAWARE.
    Ưu tiên phản hồi thần tốc: Thử gọi Gemini AI trong tối đa 3-4 giây;
    nếu mạng Google bị nghẽn thì tự động phản hồi bằng tri thức chuyên gia Pataware ngay lập tức!
    """
    user_msg = (req.message or "").strip()
    if not user_msg:
        return ChatResponse(reply="Xin chào! Tôi là Trợ lý AI PATAWARE. Bạn cần tư vấn về vấn đề an toàn mạng nào?")

    print(f"[*] Nhận câu hỏi từ người dùng: '{user_msg}'")

    api_key = get_active_gemini_key()

    # 1. Nếu có API Key, thử gọi Gemini AI (giới hạn thời gian tối đa 3.5s để không bị treo)
    if api_key:
        system_prompt = (
            "Bạn là Trợ lý AI Chuyên gia An ninh mạng của nền tảng PATAWARE (Việt Nam). "
            "Nhiệm vụ của bạn là tư vấn, giải đáp thắc mắc và hướng dẫn người dân phòng chống lừa đảo trực tuyến. "
            "Trả lời bằng tiếng Việt, ngắn gọn, súc tích, chuyên nghiệp, đưa ra các bước hành động cụ thể để bảo vệ an toàn tài sản và thông tin cá nhân."
        )
        prompt = f"{system_prompt}\n\nNgười dùng hỏi: {user_msg}\nTrợ lý AI trả lời:"
        ai_reply = call_gemini_fast(prompt, api_key)
        if ai_reply:
            print("[+] Đã trả lời thành công qua Gemini API!")
            return ChatResponse(reply=ai_reply)

    # 2. Phản hồi nhanh bằng Cơ sở Tri thức Chuyên gia An Ninh Mạng PATAWARE (tức thì 0.05s)
    lowered = user_msg.lower()
    for pattern, reply_text in KNOWLEDGE_BASE:
        if re.search(pattern, lowered):
            print("[+] Đã trả lời ngay qua Cơ sở Tri thức Chuyên gia Pataware!")
            return ChatResponse(reply=reply_text)

    # 3. Phản hồi thông minh mặc định nếu chưa khớp chuyên biệt
    print("[+] Trả lời qua bộ định hướng tổng quát!")
    return ChatResponse(
        reply=f"Tôi đã ghi nhận nội dung: *\"{user_msg}\"*.\n\n"
              "💡 **Lời khuyên an toàn từ PATAWARE:**\n"
              "• Tuyệt đối không cung cấp mã OTP, mật khẩu ngân hàng cho bất kỳ ai.\n"
              "• Nếu đây là một số điện thoại, số tài khoản hoặc đường link khả nghi, bạn hãy dán vào ô **Kiểm Tra Toàn Diện Ngay** ở trang chủ để hệ thống bóc tách điểm rủi ro chi tiết nhé!"
    )
