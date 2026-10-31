from typing import List, Dict, Any
from pydantic import BaseModel


class ScamStatItem(BaseModel):
    label: str
    count: int
    percentage: float = 0.0


class TopReportedEntity(BaseModel):
    value: str
    type: str  # bank, phone, domain
    report_count: int
    severity: str


class DashboardStatsResponse(BaseModel):
    total_scans: int
    threats_blocked: int
    high_risk_ratio: float
    scam_by_category: List[ScamStatItem]
    top_reported_scammers: List[TopReportedEntity]
    recent_trend_days: List[Dict[str, Any]]
