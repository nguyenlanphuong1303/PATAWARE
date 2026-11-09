import re
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session

from app.models.blacklist import Blacklist
from app.services.url_analyzer import DeepUrlAnalyzer
from app.services.ai_service import AiAnalysisService
from app.services.threat_intel import ThreatIntelService
from app.services.content_filter import ParentalControlFilter
from app.schemas.scan import ScanResponse, RiskBreakdown, DomainAnalysisDetail


class HybridRiskEngine:
    """
    Bộ Chấm Điểm Rủi Ro Đa Tầng (Hybrid Risk Engine - Mục 3.1):
    Tổng hợp kết quả đánh giá từ 4 tầng:
    1. Danh sách đen (Blacklist Database & Cloud Threat Intelligence từ ChongLuaDao / CyRadar)
    2. Phân tích kỹ thuật tầng mạng (WHOIS Age, Typosquatting Levenshtein, Punycode Homoglyph)
    3. Trí tuệ nhân tạo (LLM AI) bóc tách hành vi thao túng tâm lý
    4. Bộ lọc quy tắc cứng (Heuristic / Regex)
    """

    def __init__(self, db: Session):
        self.db = db
        self.ai_service = AiAnalysisService()
        self.threat_intel = ThreatIntelService()

    def check_blacklist(self, value: str, input_type: str) -> Optional[Blacklist]:
        """Truy vấn cơ sở dữ liệu danh sách đen để tìm sự trùng khớp."""
        cleaned_val = value.strip().lower()

        # 1. Khớp chính xác giá trị nguyên bản
        matched = self.db.query(Blacklist).filter(Blacklist.value == cleaned_val).first()
        if matched:
            return matched

        # 2. Nếu là URL hoặc tên miền, bóc tách hostname / tên miền đã đăng ký
        if input_type in ("url", "domain") or "://" in cleaned_val or "." in cleaned_val:
            from urllib.parse import urlparse
            import tldextract
            target = cleaned_val if "://" in cleaned_val else f"https://{cleaned_val}"
            try:
                parsed = urlparse(target)
                netloc = (parsed.netloc or "").split(":")[0].strip().lower()
                extracted = tldextract.extract(target)
                reg_domain = (extracted.registered_domain or "").strip().lower()

                candidates = [c for c in [netloc, reg_domain] if c]
                if candidates:
                    matched = self.db.query(Blacklist).filter(
                        Blacklist.type.in_(["domain", "url"]),
                        Blacklist.value.in_(candidates)
                    ).first()
                    if matched:
                        return matched
            except Exception:
                pass

        # 3. Nếu là Số điện thoại hoặc STK, làm sạch khoảng trắng / ký tự phân cách
        if input_type in ("phone", "bank_account"):
            digits_only = re.sub(r'\D', '', cleaned_val)
            if digits_only and digits_only != cleaned_val:
                matched = self.db.query(Blacklist).filter(
                    Blacklist.type == input_type,
                    Blacklist.value == digits_only
                ).first()
                if matched:
                    return matched

        return None

    def evaluate(self, content: str, input_type: str) -> ScanResponse:
        """Thực hiện quy trình chấm điểm và đánh giá rủi ro đa tầng."""
        cleaned_content = content.strip()
        indicators = []
        recommendations = []

        blacklist_score = 0.0
        tech_score = 0.0
        ai_score = 0.0
        heuristic_score = 0.0
        domain_detail = None

        # TẦNG 1: Đối soát Danh sách đen (Blacklist Check) & Threat Intelligence
        matched_bl = self.check_blacklist(cleaned_content, input_type)
        if matched_bl:
            blacklist_score = 100.0
            indicators.append(
                f"Đã nằm trong DANH SÁCH ĐEN cảnh báo ({matched_bl.type}): {matched_bl.reason or 'Bị tố cáo lừa đảo nhiều lần'} (Lượt báo cáo: {matched_bl.report_count})"
            )
            recommendations.append("TUYỆT ĐỐI KHÔNG thực hiện giao dịch, chuyển tiền hoặc nhấn vào liên kết này.")
        elif input_type in ("url", "domain") or (input_type == "text" and re.search(r'https?://[^\s]+', cleaned_content)):
            # Tra cứu thời gian thực đám mây từ Threat Intelligence (Chống Lừa Đảo / CyRadar)
            url_to_check = cleaned_content
            url_match = re.search(r'https?://[^\s]+', cleaned_content)
            if url_match:
                url_to_check = url_match.group(0)

            intel = self.threat_intel.check_url_intel(url_to_check)
            if intel.get("is_malicious"):
                blacklist_score = float(intel.get("score_penalty", 95.0))
                indicators.append(
                    f"CẢNH BÁO TÌNH BÁO MẠNG ({intel.get('source')}): {intel.get('detail')}"
                )
                recommendations.append("TUYỆT ĐỐI KHÔNG truy cập, không cung cấp tài khoản hay thực hiện chuyển tiền theo trang web này.")

                # Tự động cache vào Database nội bộ của PATAWARE
                try:
                    cached_domain = intel.get("domain") or url_to_check
                    new_bl = Blacklist(
                        type="url" if input_type == "url" else "domain",
                        value=cached_domain[:255],
                        reason=f"[{intel.get('source')}] {intel.get('detail')}",
                        report_count=10,
                        severity="critical"
                    )
                    self.db.add(new_bl)
                    self.db.commit()
                except Exception:
                    self.db.rollback()

        # TẦNG 2: Phân tích Kỹ thuật Tầng mạng (Deep Domain & Network Analyzer)
        if input_type == "url" or (input_type == "text" and re.search(r'https?://[^\s]+', cleaned_content)):
            url_match = re.search(r'https?://[^\s]+', cleaned_content)
            target_url = url_match.group(0) if url_match else cleaned_content
            
            analysis = DeepUrlAnalyzer.analyze(target_url)
            tech_score = analysis["technical_risk_score"]

            domain_detail = DomainAnalysisDetail(
                domain=analysis.get("registered_domain"),
                age_days=analysis.get("age_days"),
                creation_date=analysis.get("creation_date"),
                is_new_domain=analysis.get("is_new_domain", False),
                is_punycode_homoglyph=analysis.get("is_punycode_homoglyph", False),
                typosquatting_detected=analysis.get("typosquatting_detected", False),
                impersonated_brand=analysis.get("impersonated_brand"),
                similarity_score=analysis.get("similarity_score"),
                reasons=analysis.get("reasons", [])
            )

            indicators.extend(analysis.get("reasons", []))

            if analysis.get("typosquatting_detected"):
                recommendations.append(f"Cảnh báo mạo danh: Đây KHÔNG PHẢI trang chính thức của {analysis.get('impersonated_brand')}.")
            if analysis.get("is_new_domain"):
                recommendations.append("Tên miền có tuổi đời dưới 30 ngày. Hãy cực kỳ thận trọng, không đăng nhập thông tin cá nhân.")

        # TẦNG 3: Phân tích Thao túng Tâm lý và Hành vi lừa đảo bằng AI (LLM / Heuristic)
        ai_res = self.ai_service.analyze_scam_context(cleaned_content, input_type)
        ai_score = ai_res.get("score", 0.0)
        for tactic in ai_res.get("tactics_detected", []):
            indicators.append(f"Dấu hiệu thao túng tâm lý: {tactic}")

        # TẦNG 4: Bộ Lọc Diện Rộng & Bảo Vệ Trẻ Em (Parental Control: Cờ Bạc & Nội Dung Người Lớn 18+)
        parental_res = ParentalControlFilter.check_content_or_url(cleaned_content)
        if parental_res.get("is_flagged"):
            heuristic_score = float(parental_res.get("risk_score", 95.0))
            indicators.append(f"[{parental_res.get('badge')}] {parental_res.get('reason')}")
            recommendations.append(parental_res.get("recommendation"))

        # TẦNG 5: Tính toán Điểm Rủi Ro Tổng Hợp theo Trọng số (Thang điểm 0 - 100)
        if blacklist_score >= 100:
            final_score = 100.0
        elif parental_res.get("is_flagged"):
            final_score = heuristic_score
        else:
            if input_type == "url":
                # Đối với URL: nếu phát hiện mạo danh Typosquatting thì trực tiếp là NGUY HIỂM CAO
                if domain_detail and domain_detail.typosquatting_detected:
                    final_score = max(88.0, float(tech_score))
                elif domain_detail and domain_detail.is_new_domain:
                    final_score = max(72.0, float(tech_score))
                else:
                    final_score = (tech_score * 0.50) + (ai_score * 0.40) + (heuristic_score * 0.10)
            elif input_type in ("phone", "bank_account"):
                # Đối với STK / Số điện thoại: Ưu tiên Blacklist và nhận diện dạng số
                final_score = max(blacklist_score, ai_score * 0.7)
            else:
                # Đối với Văn bản / Tin nhắn chat: 70% AI Phân tích tâm lý + 30% Kỹ thuật/Luật
                final_score = (ai_score * 0.70) + (tech_score * 0.30)

        final_score = round(min(max(final_score, 0.0), 100.0), 1)

        # Phân loại mức độ rủi ro (Risk Level)
        if final_score >= 70:
            risk_level = "DANGEROUS"
            verdict_summary = "NGUY HIỂM CAO - Phát hiện nhiều bằng chứng lừa đảo hoặc dấu hiệu mạo danh tinh vi."
            recommendations.append("Ngừng mọi tương tác ngay lập tức, không cung cấp OTP, mật khẩu, và không chuyển bất kỳ khoản phí nào.")
        elif final_score >= 40:
            risk_level = "SUSPICIOUS"
            verdict_summary = "ĐÁNG NGỜ - Có một số yếu tố rủi ro bất thường cần kiểm chứng thêm trước khi tiếp tục."
            recommendations.append("Hãy gọi điện thoại trực tiếp qua số hotline chính thống của tổ chức để xác nhận lại thông tin.")
        else:
            risk_level = "SAFE"
            verdict_summary = "AN TOÀN - Chưa ghi nhận dấu hiệu lừa đảo nào trong hệ cơ sở dữ liệu và phân tích kỹ thuật."
            recommendations.append("Vẫn nên duy trì nguyên tắc an toàn: Không bao giờ chia sẻ mã OTP hoặc mật khẩu với bất kỳ ai.")

        breakdown = RiskBreakdown(
            blacklist_score=blacklist_score,
            technical_domain_score=tech_score,
            heuristic_regex_score=heuristic_score,
            ai_psychological_score=ai_score
        )

        return ScanResponse(
            input_type=input_type,
            target=cleaned_content,
            risk_score=final_score,
            risk_level=risk_level,
            verdict_summary=verdict_summary,
            breakdown=breakdown,
            domain_analysis=domain_detail,
            recommendations=list(dict.fromkeys(recommendations)),
            scam_indicators=list(dict.fromkeys(indicators))
        )
