# File khởi động chính của hệ thống Pataware
import uvicorn
from app.core.config import settings

if __name__ == "__main__":
    # In thông tin khởi động và đường dẫn tài liệu Swagger
    print(f"[*] Đang khởi chạy {settings.APP_NAME} tại http://{settings.HOST}:{settings.PORT}")
    print(f"[*] Tài liệu kiểm thử API Swagger: http://localhost:{settings.PORT}/docs")
    
    # Khởi động máy chủ Uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )
