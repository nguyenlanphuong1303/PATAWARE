import re
from typing import Dict, Any, Optional


class ParentalControlFilter:
    """
    Bộ Lọc Diện Rộng & Bảo Vệ Trẻ Em (Parental Control & Content Shield):
    - Tự động nhận diện và chặn website cờ bạc trực tuyến, cá độ bóng đá, game bài đổi thưởng
    - Nhận diện và chặn website khiêu dâm, nội dung người lớn 18+ độc hại với học sinh và trẻ em
    """

    # Danh sách từ khóa và thương hiệu nhà cái, cổng game bài cờ bạc phổ biến tại VN
    GAMBLING_KEYWORDS = [
        "kubet", "ku789", "ku11", "thabet", "tha789", "sunwin", "go88", "b52club", "nohu", "rikvip",
        "w88", "fun88", "fb88", "m88", "188bet", "bet188", "bk8", "jun88", "new88", "hi88", "shbet",
        "f8bet", "789bet", "okvip", "mb66", "789club", "iwin", "taixiu", "keonhacai", "socdia", "daga",
        "dagatructiep", "xoso66", "lode88", "cacuoc", "banca", "casino", "saba-sports", "cmd368", "dafabet",
        "k8vn", "sodo", "mu9", "debet", "sin88", "red88", "five88", "lucky88", "sv388", "bong88", "sbotop"
    ]

    # Danh sách từ khóa nội dung người lớn, khiêu dâm 18+
    ADULT_KEYWORDS = [
        "porn", "xvideos", "xnxx", "phimsex", "javhd", "hentai", "sexvn", "vlxx", "lauxanh",
        "gaixinh18", "goidau", "showhang", "clipnong", "thudam", "sextube", "pornhub", "stripchat",
        "chaturbate", "onlyfans-leak", "sexchat", "subnhanh18"
    ]

    @classmethod
    def check_content_or_url(cls, text_or_url: str) -> Dict[str, Any]:
        """
        Kiểm tra URL hoặc chuỗi văn bản đối chiếu với bộ lọc Cờ bạc & Người lớn
        """
        lower = text_or_url.strip().lower()
        clean = re.sub(r'[^a-z0-9]', '', lower)

        # 1. Kiểm tra Cờ bạc, Cá độ, Game bài
        matched_gambling = []
        for kw in cls.GAMBLING_KEYWORDS:
            if kw in lower or kw in clean:
                matched_gambling.append(kw)

        if matched_gambling:
            return {
                "is_flagged": True,
                "category": "GAMBLING",
                "risk_score": 95,
                "risk_level": "DANGEROUS",
                "badge": "CỜ BẠC / CÁ CƯỢC TRÁI PHÉP",
                "reason": f"Phát hiện dấu hiệu cờ bạc trực tuyến, cá độ hoặc cổng game bài đổi thưởng (Từ khóa: {', '.join(matched_gambling[:3])}).",
                "recommendation": "Trang web cờ bạc vi phạm pháp luật và tiềm ẩn rủi ro lừa đảo chiếm đoạt tài sản. Vui lòng đóng trang ngay."
            }

        # 2. Kiểm tra Nội dung Người lớn (18+ / Parental Control)
        matched_adult = []
        for kw in cls.ADULT_KEYWORDS:
            if kw in lower or kw in clean:
                matched_adult.append(kw)

        if matched_adult:
            return {
                "is_flagged": True,
                "category": "ADULT",
                "risk_score": 90,
                "risk_level": "DANGEROUS",
                "badge": "NỘI DUNG NGƯỜI LỚN 18+ (PARENTAL CONTROL)",
                "reason": f"Phát hiện nội dung nhạy cảm, người lớn hoặc độc hại đối với học sinh/trẻ em (Từ khóa: {', '.join(matched_adult[:3])}).",
                "recommendation": "Nội dung không phù hợp với lứa tuổi vị thành niên. Hệ thống tự động ngăn chặn để bảo vệ trẻ em."
            }

        return {
            "is_flagged": False,
            "category": "NONE",
            "risk_score": 0,
            "risk_level": "SAFE",
            "badge": "AN TOÀN",
            "reason": "",
            "recommendation": ""
        }
