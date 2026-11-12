import time
import base64
import logging
from urllib.parse import urlparse
from typing import Dict, Any, List, Optional, Tuple
from concurrent.futures import ThreadPoolExecutor, as_completed
import httpx
from app.core.config import settings

logger = logging.getLogger(__name__)


class ThreatIntelService:
    """
    Dịch vụ Tình báo Mối đe dọa trực tuyến Đa nguồn (Multi-Source Threat Intelligence Engine):
    Hợp nhất và đối soát song song nhiều nguồn cấp dữ liệu mã độc & lừa đảo uy tín toàn cầu:
    1. Chống Lừa Đảo (ChongLuaDao.vn / CyRadar - Việt Nam)
    2. Google Safe Browsing API v4 (Google - Toàn cầu)
    3. VirusTotal API v3 (Hợp nhất 70+ Antivirus engines: Kaspersky, Bitdefender, Sophos, ESET...)
    4. URLhaus (abuse.ch - Cơ sở dữ liệu mã độc mở quốc tế cập nhật từng phút)
    
    Tích hợp bộ đệm In-Memory TTL Cache và thực thi song song (Parallel Execution)
    với giới hạn timeout 1.5s, đảm bảo Risk Engine phản hồi siêu tốc, không bao giờ bị treo.
    """

    # Bộ nhớ đệm TTL trong RAM (URL/Domain -> (timestamp, result))
    _cache: Dict[str, Tuple[float, Dict[str, Any]]] = {}
    CACHE_TTL_SECONDS = 3600  # Lưu đệm 1 giờ

    def __init__(self):
        self.chongluadao_api = "https://api.chongluadao.vn/v2/antiphishing"
        self.urlhaus_api = "https://urlhaus-api.abuse.ch/v1/url/"
        
        # Khóa API bên thứ ba (Cấu hình trong file .env nếu có)
        self.google_key = (settings.GOOGLE_SAFE_BROWSING_API_KEY or "").strip()
        self.vt_key = (settings.VIRUSTOTAL_API_KEY or "").strip()
        self.enable_urlhaus = getattr(settings, "ENABLE_URLHAUS_CHECK", True)
        self.enable_chongluadao = getattr(settings, "ENABLE_CHONGLUADAO_CHECK", True)

        # Timeout phân lớp: Kết nối tối đa 1.0s, đọc tối đa 1.5s
        self.timeout_config = httpx.Timeout(connect=1.0, read=1.5, write=1.0, pool=1.2)

    def _check_chongluadao(self, clean_url: str, domain: str) -> Optional[Dict[str, Any]]:
        """1. Truy vấn Chống Lừa Đảo (ChongLuaDao.vn / CyRadar)."""
        if not self.enable_chongluadao:
            return None
        try:
            with httpx.Client(timeout=self.timeout_config) as client:
                res = client.post(
                    self.chongluadao_api,
                    json={"url": clean_url},
                    headers={"User-Agent": "Pataware-AntiScam-Engine/1.0"}
                )
                if res.status_code == 200:
                    data = res.json()
                    is_bad = (
                        data.get("type") == "malicious"
                        or data.get("status") in ("bad", "unsafe", "scam")
                        or data.get("is_malicious") is True
                    )
                    if is_bad:
                        return {
                            "source": "Chống Lừa Đảo (ChongLuaDao.vn)",
                            "detail": data.get("reason") or "Tên miền nằm trong danh sách đen cảnh báo lừa đảo trực tuyến tại Việt Nam.",
                            "penalty": 95
                        }
        except Exception as e:
            logger.debug(f"[ThreatIntel] ChongLuaDao error: {e}")
        return None

    def _check_google_safebrowsing(self, clean_url: str, domain: str) -> Optional[Dict[str, Any]]:
        """2. Truy vấn Google Safe Browsing API v4."""
        if not self.google_key:
            return None
        endpoint = f"https://safebrowsing.googleapis.com/v4/threatMatches:find?key={self.google_key}"
        payload = {
            "client": {"clientId": "pataware-platform", "clientVersion": "1.0.0"},
            "threatInfo": {
                "threatTypes": ["MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE", "POTENTIALLY_HARMFUL_APPLICATION"],
                "platformTypes": ["ANY_PLATFORM"],
                "threatEntryTypes": ["URL"],
                "threatEntries": [{"url": clean_url}]
            }
        }
        try:
            with httpx.Client(timeout=self.timeout_config) as client:
                res = client.post(endpoint, json=payload)
                if res.status_code == 200:
                    data = res.json()
                    matches = data.get("matches", [])
                    if matches:
                        threat_types = list(set(m.get("threatType", "MALWARE") for m in matches))
                        return {
                            "source": "Google Safe Browsing API",
                            "detail": f"Google cảnh báo trang web nguy hiểm ({', '.join(threat_types)}).",
                            "penalty": 100
                        }
        except Exception as e:
            logger.debug(f"[ThreatIntel] Google Safe Browsing error: {e}")
        return None

    def _check_virustotal(self, clean_url: str, domain: str) -> Optional[Dict[str, Any]]:
        """3. Truy vấn VirusTotal API v3 (70+ Antivirus engines)."""
        if not self.vt_key:
            return None
        try:
            # Mã hóa Base64 không padding theo quy chuẩn VirusTotal v3 URL ID
            url_id = base64.urlsafe_b64encode(clean_url.encode()).decode().strip("=")
            endpoint = f"https://www.virustotal.com/api/v3/urls/{url_id}"
            headers = {
                "x-apikey": self.vt_key,
                "User-Agent": "Pataware-AntiScam-Engine/1.0"
            }
            with httpx.Client(timeout=self.timeout_config) as client:
                res = client.get(endpoint, headers=headers)
                if res.status_code == 200:
                    data = res.json()
                    stats = data.get("data", {}).get("attributes", {}).get("last_analysis_stats", {})
                    malicious_count = stats.get("malicious", 0)
                    suspicious_count = stats.get("suspicious", 0)

                    if malicious_count >= 1 or suspicious_count >= 2:
                        return {
                            "source": "VirusTotal Intelligence",
                            "detail": f"Có {malicious_count} hãng bảo mật xếp loại Mã độc và {suspicious_count} hãng đánh giá Đáng ngờ.",
                            "penalty": 98 if malicious_count >= 3 else 90
                        }
        except Exception as e:
            logger.debug(f"[ThreatIntel] VirusTotal error: {e}")
        return None

    def _check_urlhaus(self, clean_url: str, domain: str) -> Optional[Dict[str, Any]]:
        """4. Truy vấn URLhaus (abuse.ch) - CSDL mã độc mở quốc tế cập nhật liên tục."""
        if not self.enable_urlhaus:
            return None
        try:
            with httpx.Client(timeout=self.timeout_config) as client:
                res = client.post(
                    self.urlhaus_api,
                    data={"url": clean_url},
                    headers={"User-Agent": "Pataware-AntiScam-Engine/1.0"}
                )
                if res.status_code == 200:
                    data = res.json()
                    if data.get("query_status") == "ok":
                        threat = data.get("threat", "malware_download")
                        tags = data.get("tags") or []
                        tag_str = f" [Thẻ: {', '.join(tags)}]" if tags else ""
                        return {
                            "source": "URLhaus (abuse.ch)",
                            "detail": f"Máy chủ bị ghi nhận phân phối mã độc ({threat}){tag_str}.",
                            "penalty": 100
                        }
        except Exception as e:
            logger.debug(f"[ThreatIntel] URLhaus error: {e}")
        return None

    def check_url_intel(self, url: str) -> Dict[str, Any]:
        """
        Tra cứu song song (Parallel Execution) đa nguồn tình báo mã độc.
        Giới hạn thời gian tối đa 1.8s. Nếu bất kỳ nguồn nào phát hiện nguy hiểm,
        kết quả sẽ được tổng hợp ngay lập tức.
        """
        if not url or not url.strip():
            return {
                "is_malicious": False,
                "source": "Local Threat Engine",
                "domain": "",
                "score_penalty": 0,
                "detail": "URL rỗng.",
                "sources_matched": []
            }

        clean_url = url.strip()
        if not clean_url.startswith("http://") and not clean_url.startswith("https://"):
            clean_url = "https://" + clean_url

        try:
            domain = urlparse(clean_url).netloc or clean_url
        except Exception:
            domain = clean_url

        # Kiểm tra Bộ đệm Cache (tránh gọi API trùng lặp trong vòng 1 giờ)
        cache_key = clean_url.lower()
        now = time.time()
        if cache_key in self._cache:
            ts, cached_data = self._cache[cache_key]
            if now - ts < self.CACHE_TTL_SECONDS:
                return cached_data

        # Khởi chạy đa luồng đồng thời 4 cổng dữ liệu
        feed_tasks = [
            self._check_chongluadao,
            self._check_urlhaus,
        ]
        if self.google_key:
            feed_tasks.append(self._check_google_safebrowsing)
        if self.vt_key:
            feed_tasks.append(self._check_virustotal)

        detected_sources = []
        details = []
        max_penalty = 0

        # Chạy song song với ThreadPoolExecutor, tổng thời gian chờ tối đa 1.8 giây
        with ThreadPoolExecutor(max_workers=len(feed_tasks)) as executor:
            futures = [executor.submit(task, clean_url, domain) for task in feed_tasks]
            try:
                for future in as_completed(futures, timeout=1.8):
                    try:
                        res = future.result()
                        if res:
                            detected_sources.append(res["source"])
                            details.append(f"{res['source']}: {res['detail']}")
                            max_penalty = max(max_penalty, res.get("penalty", 95))
                    except Exception:
                        pass
            except Exception:
                # Quá hạn 1.8s, tiếp tục với các kết quả đã kịp hoàn thành
                pass

        if detected_sources:
            result = {
                "is_malicious": True,
                "source": " + ".join(detected_sources),
                "domain": domain,
                "score_penalty": max_penalty,
                "detail": " | ".join(details),
                "sources_matched": detected_sources
            }
        else:
            result = {
                "is_malicious": False,
                "source": "Multi-Source Threat Shield",
                "domain": domain,
                "score_penalty": 0,
                "detail": "Không phát hiện trong các cơ sở dữ liệu mã độc trực tuyến.",
                "sources_matched": []
            }

        # Lưu kết quả vào bộ đệm Cache
        self._cache[cache_key] = (now, result)
        # Giới hạn kích thước cache để không tốn RAM
        if len(self._cache) > 5000:
            self._cache.clear()

        return result
