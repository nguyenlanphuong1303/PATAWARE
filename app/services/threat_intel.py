from urllib.parse import urlparse
from typing import Dict, Any
import httpx


class ThreatIntelService:
    """
    Dịch vụ Tình báo Mối đe dọa trực tuyến (Threat Intelligence Engine):
    Tra cứu thời gian thực cơ sở dữ liệu Blacklist từ Chống Lừa Đảo (ChongLuaDao.vn) và các cổng an ninh mạng.
    """

    def __init__(self):
        # API công khai kiểm tra phishing / scam của Chống Lừa Đảo
        self.chongluadao_api = "https://api.chongluadao.vn/v2/antiphishing"
        self.timeout = 2.5  # Giới hạn thời gian chờ tối đa 2.5 giây

    def check_url_intel(self, url: str) -> Dict[str, Any]:
        """
        Gửi URL lên các cổng Threat Intelligence để tra cứu uy tín tên miền.
        Cơ chế Fail-safe: Nếu API quá tải, timeout hoặc mất mạng, tự động bỏ qua để hệ thống AI nội bộ xử lý.
        """
        clean_url = url.strip()
        if not clean_url.startswith("http://") and not clean_url.startswith("https://"):
            clean_url = "https://" + clean_url

        domain = urlparse(clean_url).netloc or clean_url

        try:
            with httpx.Client(timeout=self.timeout) as client:
                response = client.post(
                    self.chongluadao_api,
                    json={"url": clean_url},
                    headers={"User-Agent": "Pataware-AntiScam-ThreatIntel/1.0"}
                )

                if response.status_code == 200:
                    res_data = response.json()
                    is_bad = (
                        res_data.get("type") == "malicious"
                        or res_data.get("status") in ("bad", "unsafe", "scam")
                        or res_data.get("is_malicious") is True
                    )
                    if is_bad:
                        return {
                            "is_malicious": True,
                            "source": "Threat Intelligence Engine (ChongLuaDao.vn / CyRadar)",
                            "domain": domain,
                            "score_penalty": 95,
                            "detail": res_data.get("reason") or "Tên miền nằm trong danh sách đen cảnh báo lừa đảo trực tuyến."
                        }
        except Exception:
            # Nếu API timeout hoặc mất kết nối, chuyển tiếp quyền đánh giá cho AI/Rules nội bộ
            pass

        return {
            "is_malicious": False,
            "source": "Local Threat Engine",
            "domain": domain,
            "score_penalty": 0,
            "detail": "Không phát hiện trong Blacklist trực tuyến."
        }
