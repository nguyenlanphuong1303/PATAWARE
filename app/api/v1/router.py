from fastapi import APIRouter
from app.api.v1.endpoints import auth, scan, community, dashboard, quiz

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(scan.router, prefix="/scan", tags=["Hybrid Risk Scanner & OCR"])
api_router.include_router(community.router, prefix="/community", tags=["Community & ScamGuard"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["Real-time Stats & Heatmap"])
api_router.include_router(quiz.router, prefix="/quiz", tags=["Gamification & Education"])
