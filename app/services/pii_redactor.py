import re
from typing import Tuple, List, Dict


class PiiRedactor:
    """
    Bộ lọc bảo vệ quyền riêng tư người dùng (ScamGuard & PII Redaction):
    Tự động che mờ thông tin định danh cá nhân nhạy cảm trước khi công khai lên cộng đồng:
    - Căn cước công dân (CCCD 12 số) và Chứng minh nhân dân (CMND 9 số)
    - Số điện thoại cá nhân tại Việt Nam (10 chữ số)
    - Số tài khoản ngân hàng và số thẻ tín dụng
    - Địa chỉ thư điện tử (Email)
    """

    # Biểu thức chính quy phát hiện CCCD (12 chữ số) và CMND (9 chữ số)
    CCCD_PATTERN = re.compile(r'\b(0\d{11})\b')
    CMND_PATTERN = re.compile(r'\b(\d{9})\b')

    # Biểu thức chính quy phát hiện số điện thoại Việt Nam (đầu số 03, 05, 07, 08, 09 hoặc +84)
    VN_PHONE_PATTERN = re.compile(r'(\+84|0)(3|5|7|8|9)\d{8}\b')

    # Biểu thức chính quy phát hiện địa chỉ Email
    EMAIL_PATTERN = re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,7}\b')

    # Biểu thức chính quy phát hiện số tài khoản ngân hàng / số thẻ tín dụng kèm từ khóa
    BANK_ACC_PATTERN = re.compile(r'(?i)\b(?:stk|tk|số\s+tài\s+khoản|tài\s+khoản|account)[\s:]*([0-9]{8,19})\b')
    STANDALONE_LONG_DIGIT_PATTERN = re.compile(r'\b([0-9]{13,19})\b')

    @classmethod
    def mask_string(cls, val: str, keep_start: int = 3, keep_end: int = 3) -> str:
        """Hàm phụ trợ che mờ phần giữa của chuỗi bằng các dấu sao (*)."""
        val = val.strip()
        if len(val) <= keep_start + keep_end:
            return "***"
        return val[:keep_start] + "*" * (len(val) - keep_start - keep_end) + val[-keep_end:]

    @classmethod
    def redact(cls, text: str) -> Tuple[str, List[Dict[str, str]]]:
        """
        Bóc tách và che mờ thông tin cá nhân nhạy cảm khỏi văn bản đầu vào.
        Trả về:
            Tuple[văn_bản_đã_che_mờ, danh_sách_thực_thể_được_bảo_vệ]
        """
        if not text:
            return "", []

        redacted = text
        redacted_entities = []

        # 1. Che mờ Căn cước công dân (CCCD 12 số)
        def cccd_sub(match):
            original = match.group(0)
            masked = cls.mask_string(original, 3, 3)
            redacted_entities.append({"type": "CCCD", "original": original, "masked": masked})
            return f"[CCCD:{masked}]"

        redacted = cls.CCCD_PATTERN.sub(cccd_sub, redacted)

        # 2. Che mờ Số điện thoại cá nhân
        def phone_sub(match):
            original = match.group(0)
            masked = cls.mask_string(original, 3, 2)
            redacted_entities.append({"type": "PHONE", "original": original, "masked": masked})
            return f"[SĐT:{masked}]"

        redacted = cls.VN_PHONE_PATTERN.sub(phone_sub, redacted)

        # 3. Che mờ Địa chỉ Email
        def email_sub(match):
            original = match.group(0)
            parts = original.split("@")
            user_part = parts[0]
            domain_part = parts[1] if len(parts) > 1 else ""
            masked_user = cls.mask_string(user_part, 2, 1)
            masked = f"{masked_user}@{domain_part}"
            redacted_entities.append({"type": "EMAIL", "original": original, "masked": masked})
            return f"[EMAIL:{masked}]"

        redacted = cls.EMAIL_PATTERN.sub(email_sub, redacted)

        # 4. Che mờ Số tài khoản ngân hàng
        def bank_sub(match):
            prefix = match.group(0).split(match.group(1))[0]
            original = match.group(1)
            masked = cls.mask_string(original, 3, 3)
            redacted_entities.append({"type": "BANK_ACCOUNT", "original": original, "masked": masked})
            return f"{prefix}[STK:{masked}]"

        redacted = cls.BANK_ACC_PATTERN.sub(bank_sub, redacted)

        return redacted, redacted_entities
