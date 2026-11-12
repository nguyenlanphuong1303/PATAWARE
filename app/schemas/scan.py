from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field


class ScanRequest(BaseModel):
    input_type: str = Field(..., description="One of: 'url', 'text', 'phone', 'bank_account'")
    content: str = Field(..., description="The string to inspect (URL, phone number, bank account, or message text)")


class DomainAnalysisDetail(BaseModel):
    domain: Optional[str] = None
    age_days: Optional[int] = None
    creation_date: Optional[str] = None
    is_new_domain: bool = False
    is_punycode_homoglyph: bool = False
    typosquatting_detected: bool = False
    impersonated_brand: Optional[str] = None
    similarity_score: Optional[float] = None
    reasons: List[str] = []


class RiskBreakdown(BaseModel):
    blacklist_score: float = 0.0
    technical_domain_score: float = 0.0
    heuristic_regex_score: float = 0.0
    ai_psychological_score: float = 0.0


class ScanResponse(BaseModel):
    input_type: str
    target: str
    risk_score: float  # 0 to 100
    risk_level: str  # SAFE (0-39), SUSPICIOUS (40-69), DANGEROUS (70-100)
    verdict_summary: str
    breakdown: RiskBreakdown
    domain_analysis: Optional[DomainAnalysisDetail] = None
    recommendations: List[str] = []
    scam_indicators: List[str] = []


class QuickCheckRequest(BaseModel):
    url: str


class QuickCheckResponse(BaseModel):
    url: str
    domain: str
    is_malicious: bool
    risk_score: float
    risk_level: str
    category: str  # PHISHING, GAMBLING, ADULT, SAFE
    reasons: List[str] = []
