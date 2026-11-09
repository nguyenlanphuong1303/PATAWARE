import os
import google.generativeai as genai
from dotenv import dotenv_values

env_vals = dotenv_values(".env")
api_key = env_vals.get("GEMINI_API_KEY")

genai.configure(api_key=api_key)

print("[*] Đang gửi câu hỏi thử nghiệm tới Gemini AI với model: models/gemini-3.8-flash...")

try:
    model = genai.GenerativeModel("models/gemini-3.8-flash")
    response = model.generate_content("Chào bạn, hãy giới thiệu ngắn gọn 1 câu về bạn bằng tiếng Việt.")
    print("\n[THÀNH CÔNG RỰC RỠ] Phản hồi từ Gemini 3.8 Flash:")
    print(f"\"{response.text.strip()}\"\n")
except Exception as e:
    print(f"[!] Thất bại với models/gemini-3.8-flash: {e}")
    # Thử thêm các model khác nếu có
    for m in ["gemini-3.8-flash", "models/gemini-2.5-pro", "models/gemini-flash-latest"]:
        try:
            print(f"[*] Thử thêm model: {m}...")
            alt_model = genai.GenerativeModel(m)
            alt_resp = alt_model.generate_content("Xin chào")
            print(f"[+] Thành công với {m}: \"{alt_resp.text.strip()}\"")
            break
        except Exception as alt_err:
            print(f"[-] {m} thất bại: {alt_err}")
