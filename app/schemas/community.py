from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class StoryCreate(BaseModel):
    title: str = Field(..., max_length=200)
    content: str = Field(..., description="Raw story content (will be automatically redacted)")
    scam_type: str = Field(..., description="'financial_investment', 'job_offer', 'impersonation', 'phishing_link', 'otp_theft'")
    reported_scammer_phone: Optional[str] = None
    reported_scammer_bank: Optional[str] = None
    reported_scammer_url: Optional[str] = None
    loss_amount: Optional[str] = None


class StoryModeration(BaseModel):
    status: str = Field(..., description="'approved' or 'rejected'")
    moderation_notes: Optional[str] = None


class StoryResponse(BaseModel):
    id: int
    title: str
    redacted_content: str
    scam_type: str
    reported_scammer_phone: Optional[str]
    reported_scammer_bank: Optional[str]
    reported_scammer_url: Optional[str]
    loss_amount: Optional[str]
    status: str
    upvotes: int
    created_at: datetime

    class Config:
        from_attributes = True
