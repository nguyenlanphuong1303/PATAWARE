import os
from dotenv import dotenv_values
import google.generativeai as genai

env_vals = dotenv_values(".env")
api_key = env_vals.get("GEMINI_API_KEY")

genai.configure(api_key=api_key)

print("[*] Dang lay toan bo danh sach model...")
try:
    models = [m.name for m in genai.list_models() if 'generateContent' in m.supported_generation_methods]
    print(f"Tong cong {len(models)} models:")
    for m in models:
        print("  -", m)
except Exception as e:
    print("Loi list_models:", e)
