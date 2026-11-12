import re
import socket
import logging
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FutureTimeoutError
import tldextract

logger = logging.getLogger(__name__)

try:
    import Levenshtein
except ImportError:
    Levenshtein = None

try:
    import whois
except ImportError:
    whois = None

# Danh sách các thương hiệu ngân hàng, sàn thương mại điện tử và dịch vụ công phổ biến tại Việt Nam
# Dùng để đối soát phát hiện hành vi cố tình tạo tên miền nhái (Typosquatting)
DEFAULT_POPULAR_BRANDS = [
    {"name": "Vietcombank", "keyword": "vietcombank", "domain": "vietcombank.com.vn"},
    {"name": "MBBank", "keyword": "mbbank", "domain": "mbbank.com.vn"},
    {"name": "Techcombank", "keyword": "techcombank", "domain": "techcombank.com"},
    {"name": "BIDV", "keyword": "bidv", "domain": "bidv.com.vn"},
    {"name": "Agribank", "keyword": "agribank", "domain": "agribank.com.vn"},
    {"name": "VPBank", "keyword": "vpbank", "domain": "vpbank.com.vn"},
    {"name": "ACB", "keyword": "acb", "domain": "acb.com.vn"},
    {"name": "TPBank", "keyword": "tpbank", "domain": "tpb.vn"},
    {"name": "Sacombank", "keyword": "sacombank", "domain": "sacombank.com.vn"},
    {"name": "VietinBank", "keyword": "vietinbank", "domain": "vietinbank.vn"},
    {"name": "MoMo", "keyword": "momo", "domain": "momo.vn"},
    {"name": "ZaloPay", "keyword": "zalopay", "domain": "zalopay.vn"},
    {"name": "VNPay", "keyword": "vnpay", "domain": "vnpay.vn"},
    {"name": "Shopee", "keyword": "shopee", "domain": "shopee.vn"},
    {"name": "Lazada", "keyword": "lazada", "domain": "lazada.vn"},
    {"name": "Tiki", "keyword": "tiki", "domain": "tiki.vn"},
    {"name": "TikTok Shop", "keyword": "tiktok", "domain": "tiktok.com"},
    {"name": "VNeID", "keyword": "vneid", "domain": "vneid.gov.vn"},
    {"name": "VNPost", "keyword": "vnpost", "domain": "vnpost.vn"},
    {"name": "ViettelPost", "keyword": "viettelpost", "domain": "viettelpost.com.vn"},
    {"name": "Telegram", "keyword": "telegram", "domain": "telegram.org"},
    {"name": "Facebook", "keyword": "facebook", "domain": "facebook.com"}
]


class DeepUrlAnalyzer:
    """
    Trình phân tích kỹ thuật URL & Tên miền độc hại (Điểm nhấn kỹ thuật số 1):
    - Kiểm tra tuổi thọ tên miền thông qua truy vấn WHOIS (phát hiện tên miền dưới 30 ngày)
    - Phát hiện mạo danh thương hiệu (Typosquatting) bằng thuật toán khoảng cách chuỗi Levenshtein
    - Phát hiện tấn công ký tự đồng hình (Homoglyph Attack) và mã hóa quốc tế Punycode (xn--)
    """

    @staticmethod
    def extract_domain_info(url_or_domain: str) -> Dict[str, str]:
        """Chuẩn hóa đường dẫn URL và bóc tách tên miền gốc, tên miền phụ (subdomain) và phần mở rộng (suffix)."""
        target = url_or_domain.strip().lower()
        if not target.startswith("http://") and not target.startswith("https://"):
            target = "https://" + target
        
        extracted = tldextract.extract(target)
        registered_domain = extracted.registered_domain
        domain_name = extracted.domain
        subdomain = extracted.subdomain
        suffix = extracted.suffix

        return {
            "normalized_url": target,
            "registered_domain": registered_domain,
            "domain_name": domain_name,
            "subdomain": subdomain,
            "suffix": suffix,
            "full_host": f"{subdomain}.{registered_domain}".strip(".") if subdomain else registered_domain
        }

    @staticmethod
    def check_homoglyph_and_punycode(domain_info: Dict[str, str]) -> Dict[str, Any]:
        """
        Kiểm tra mã hóa Punycode (tiền tố xn--) và các ký tự đồng hình phi chuẩn (ví dụ: chữ Cyrillic 'а', 'е', 'о' giả chữ Latin).
        """
        registered = domain_info.get("registered_domain", "")
        full_host = domain_info.get("full_host", "")

        is_punycode = "xn--" in registered.lower() or "xn--" in full_host.lower()

        # Kiểm tra sự xuất hiện của ký tự ngoài bảng mã ASCII thường dùng để đánh lừa thị giác người dùng
        non_ascii_chars = [ch for ch in full_host if ord(ch) > 127]
        is_homoglyph = is_punycode or len(non_ascii_chars) > 0

        reasons = []
        if is_punycode:
            reasons.append("Tên miền sử dụng mã hóa quốc tế Punycode (xn--), dấu hiệu che giấu ký tự giả mạo.")
        if non_ascii_chars:
            reasons.append(f"Tên miền chứa các ký tự phi chuẩn/đồng hình: {''.join(set(non_ascii_chars))}")

        return {
            "is_punycode": is_punycode,
            "is_homoglyph": is_homoglyph,
            "non_ascii_chars": list(set(non_ascii_chars)),
            "reasons": reasons
        }

    @classmethod
    def check_typosquatting(cls, domain_info: Dict[str, str]) -> Dict[str, Any]:
        """
        Sử dụng thuật toán khoảng cách chuỗi Levenshtein Distance, phân tách token và chuẩn hóa Leetspeak
        để phát hiện hành vi cố ý nhái tên thương hiệu.
        Ví dụ: 'vietc0mbank', 'vietc0mbank-portal', 'sh0pee-vn', 'mbbank-online'.
        """
        domain_name = domain_info.get("domain_name", "").lower()
        full_host = domain_info.get("full_host", "").lower()

        # Chuẩn hóa Leetspeak (thay số 0 -> o, 1 -> l/i, 3 -> e, 5 -> s, @ -> a)
        leetspeak_map = str.maketrans("0135@", "olsea")
        norm_domain = domain_name.translate(leetspeak_map)
        norm_host = full_host.translate(leetspeak_map)

        # Phân rã thành các từ/token đơn (ví dụ vietc0mbank-portal -> ['vietc0mbank', 'portal'])
        tokens = re.split(r'[-_.]', domain_name)
        norm_tokens = [t.translate(leetspeak_map) for t in tokens if t]

        detected = False
        target_brand = None
        reasons = []
        best_similarity = 0.0

        for brand in DEFAULT_POPULAR_BRANDS:
            keyword = brand["keyword"].lower()
            official_domain = brand["domain"].lower()

            # Nếu trùng khớp hoàn toàn với tên miền chính thức của thương hiệu -> An toàn
            if domain_info.get("registered_domain", "").lower() == official_domain:
                continue

            # 1. Kiểm tra xuất hiện trực tiếp hoặc qua Leetspeak (ví dụ vietc0mbank -> vietcombank)
            has_raw = keyword in domain_name or keyword in full_host
            has_leetspeak = keyword in norm_domain or keyword in norm_host

            if has_leetspeak:
                detected = True
                target_brand = brand["name"]
                best_similarity = 0.98 if not has_raw else 0.95
                if not has_raw:
                    reasons.append(
                        f"Phát hiện thủ đoạn ngụy trang ký tự Leetspeak (thay chữ bằng số, ví dụ '0' thay 'o') để giả mạo thương hiệu '{brand['name']}'."
                    )
                else:
                    reasons.append(
                        f"Tên miền chứa từ khóa thương hiệu '{brand['name']}' nhưng không phải tên miền chính thức ({official_domain})."
                    )
                break

            # 2. Kiểm tra khoảng cách Levenshtein trên toàn bộ domain_name và trên từng token
            candidates = [domain_name] + tokens + norm_tokens
            found_lev = False
            for cand in candidates:
                if not cand or cand == keyword:
                    continue
                if Levenshtein and abs(len(cand) - len(keyword)) <= 3:
                    dist = Levenshtein.distance(cand, keyword)
                    ratio = Levenshtein.ratio(cand, keyword)

                    if 1 <= dist <= 2 and ratio >= 0.72:
                        detected = True
                        target_brand = brand["name"]
                        best_similarity = ratio
                        reasons.append(
                            f"Phát hiện thủ đoạn mạo danh (Typosquatting) trong cụm '{cand}' gần giống thương hiệu '{brand['name']}' (Khoảng cách ký tự: {dist}, tỷ lệ tương đồng: {ratio:.1%})."
                        )
                        found_lev = True
                        break
            if found_lev:
                break

        return {
            "typosquatting_detected": detected,
            "target_brand": target_brand,
            "similarity_score": best_similarity,
            "reasons": reasons
        }

    @staticmethod
    def _raw_whois_lookup(domain: str):
        """Thực hiện truy vấn WHOIS với socket timeout cục bộ."""
        old_timeout = socket.getdefaulttimeout()
        try:
            socket.setdefaulttimeout(2.5)
            return whois.whois(domain)
        finally:
            socket.setdefaulttimeout(old_timeout)

    @classmethod
    def check_domain_age(cls, domain: str, timeout_seconds: float = 2.5) -> Dict[str, Any]:
        """
        Truy vấn thông tin WHOIS để xác định ngày đăng ký và tính tuổi tên miền theo số ngày.
        Tên miền dưới 30 ngày là dấu hiệu điển hình của hạ tầng lừa đảo dùng một lần.
        Bảo vệ chặt chẽ: Giới hạn timeout 2.5s qua ThreadPoolExecutor và socket timeout,
        chống blocking toàn bộ worker FastAPI khi WHOIS server phản hồi chậm hoặc bị treo.
        """
        if not whois or not domain:
            return {"age_days": None, "creation_date": None, "is_new_domain": False, "reasons": []}

        executor = ThreadPoolExecutor(max_workers=1)
        try:
            future = executor.submit(cls._raw_whois_lookup, domain)
            w = future.result(timeout=timeout_seconds)
        except FutureTimeoutError:
            logger.debug(f"[UrlAnalyzer] WHOIS query timeout ({timeout_seconds}s) cho domain: {domain}")
            return {"age_days": None, "creation_date": None, "is_new_domain": False, "reasons": []}
        except socket.timeout:
            logger.debug(f"[UrlAnalyzer] Socket timeout khi kết nối WHOIS cho domain: {domain}")
            return {"age_days": None, "creation_date": None, "is_new_domain": False, "reasons": []}
        except Exception as e:
            logger.debug(f"[UrlAnalyzer] Lỗi ngoại lệ khi truy vấn WHOIS ({domain}): {e}")
            return {"age_days": None, "creation_date": None, "is_new_domain": False, "reasons": []}
        finally:
            # wait=False để không chặn thread chính nếu worker thread chưa kịp thoát
            executor.shutdown(wait=False, cancel_futures=True)

        try:
            creation_date = getattr(w, "creation_date", None)

            # WHOIS có thể trả về một danh sách các ngày
            if isinstance(creation_date, list) and creation_date:
                creation_date = creation_date[0]

            if not creation_date:
                return {"age_days": None, "creation_date": None, "is_new_domain": False, "reasons": []}

            # Chuẩn hóa múi giờ
            if hasattr(creation_date, "tzinfo") and creation_date.tzinfo is not None:
                now = datetime.now(timezone.utc)
            else:
                now = datetime.utcnow()

            age_days = (now - creation_date).days
            is_new = age_days <= 30
            is_recent = age_days <= 90

            reasons = []
            if is_new:
                reasons.append(f"Tên miền mới được đăng ký cách đây {age_days} ngày (< 30 ngày). Dấu hiệu đặc trưng của 95% website lừa đảo.")
            elif is_recent:
                reasons.append(f"Tên miền còn tương đối mới ({age_days} ngày, < 90 ngày), cần thận trọng.")

            return {
                "age_days": age_days,
                "creation_date": creation_date.isoformat() if hasattr(creation_date, "isoformat") else str(creation_date),
                "is_new_domain": is_new,
                "is_recent_domain": is_recent,
                "reasons": reasons
            }
        except Exception as parse_err:
            logger.debug(f"[UrlAnalyzer] Lỗi bóc tách creation_date từ WHOIS: {parse_err}")
            return {
                "age_days": None,
                "creation_date": None,
                "is_new_domain": False,
                "reasons": []
            }

    @classmethod
    def analyze(cls, url_or_domain: str) -> Dict[str, Any]:
        """Thực thi toàn diện các bước kiểm tra kỹ thuật tầng mạng cho tên miền."""
        domain_info = cls.extract_domain_info(url_or_domain)
        reg_domain = domain_info.get("registered_domain") or domain_info.get("full_host")

        homoglyph_res = cls.check_homoglyph_and_punycode(domain_info)
        typosquat_res = cls.check_typosquatting(domain_info)
        whois_res = cls.check_domain_age(reg_domain) if reg_domain else {"age_days": None, "reasons": []}

        all_reasons = homoglyph_res["reasons"] + typosquat_res["reasons"] + whois_res.get("reasons", [])

        # Tính toán điểm rủi ro kỹ thuật cho tên miền (0 - 100)
        tech_score = 0
        if typosquat_res["typosquatting_detected"]:
            tech_score += 45
        if homoglyph_res["is_homoglyph"]:
            tech_score += 35
        if whois_res.get("is_new_domain"):
            tech_score += 35
        elif whois_res.get("is_recent_domain"):
            tech_score += 15

        # Kiểm tra phần mở rộng tên miền (TLD) giá rẻ có tỷ lệ rủi ro cao
        suspicious_tld = [".top", ".xyz", ".club", ".vip", ".work", ".site", ".online", ".icu", ".cam"]
        for tld in suspicious_tld:
            if domain_info.get("registered_domain", "").endswith(tld):
                tech_score += 15
                all_reasons.append(f"Tên miền sử dụng phần mở rộng rủi ro cao ({tld}) thường xuyên bị kẻ gian lợi dụng do chi phí rẻ.")
                break

        tech_score = min(tech_score, 100)

        return {
            "domain_info": domain_info,
            "registered_domain": reg_domain,
            "technical_risk_score": tech_score,
            "age_days": whois_res.get("age_days"),
            "creation_date": whois_res.get("creation_date"),
            "is_new_domain": whois_res.get("is_new_domain", False),
            "is_punycode_homoglyph": homoglyph_res["is_homoglyph"],
            "typosquatting_detected": typosquat_res["typosquatting_detected"],
            "impersonated_brand": typosquat_res["target_brand"],
            "similarity_score": typosquat_res.get("similarity_score"),
            "reasons": all_reasons
        }
