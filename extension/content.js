// ==============================================================================
// PATAWARE CONTENT SCRIPT - REAL-TIME CLIENT-SIDE DEFENSE SHIELD
// Chạy trực tiếp tại document_start: Phân tích Heuristics 0ms & Bảo vệ giao diện người dùng
// ==============================================================================

(function () {
    const currentUrl = window.location.href;
    const currentHostname = window.location.hostname.toLowerCase();

    // Bỏ qua các trang nội bộ hoặc localhost
    if (!currentUrl || currentUrl.startsWith("chrome://") || currentUrl.startsWith("edge://") ||
        currentHostname === "localhost" || currentHostname === "127.0.0.1" || 
        currentUrl.includes("warning.html")) {
        return;
    }

    // 1. Thuật toán Client-side Heuristic siêu nhẹ (0ms độ trễ)
    function fastClientHeuristic(hostname, url) {
        const lower = (url + " " + hostname).toLowerCase();
        const clean = lower.replace(/[^a-z0-9]/g, '');

        // Nhận diện mã hóa Punycode giả mạo ký tự
        if (hostname.includes("xn--")) {
            return {
                is_danger: true,
                badge: "GIẢ MẠO ĐỒNG HÌNH (PUNYCODE)",
                reason: "Tên miền sử dụng mã hóa Punycode xn-- để đánh lừa thị giác người dùng."
            };
        }

        // Nhận diện mạo danh thương hiệu (Typosquatting)
        const brands = [
            { name: "Vietcombank", keys: ["vietcombank", "vietc0mbank", "vcb-digibank"], official: "vietcombank.com.vn" },
            { name: "Techcombank", keys: ["techcombank", "tcb-bank"], official: "techcombank.com" },
            { name: "MBBank", keys: ["mbbank", "mb-bank"], official: "mbbank.com.vn" },
            { name: "Shopee", keys: ["shopee", "sh0pee"], official: "shopee.vn" },
            { name: "VNeID", keys: ["vneid", "dinhdanh-gov"], official: "vneid.gov.vn" },
            { name: "Bộ Công An", keys: ["bocongan", "dichvucong-bca"], official: "bocongan.gov.vn" },
            { name: "MoMo", keys: ["momo-pay", "momo-vn"], official: "momo.vn" }
        ];

        const riskyTlds = [".xyz", ".top", ".site", ".cc", ".icu", ".vip", ".club", ".space", ".work", ".cfd", ".online"];
        const hasRiskyTld = riskyTlds.some(tld => hostname.endsWith(tld));

        for (const b of brands) {
            for (const k of b.keys) {
                if (lower.includes(k) && !hostname.endsWith(b.official) && !hostname.endsWith("." + b.official)) {
                    return {
                        is_danger: hasRiskyTld || lower.includes("otp") || lower.includes("login"),
                        is_suspicious: true,
                        badge: `NGHI VẤN MẠO DANH ${b.name.toUpperCase()}`,
                        reason: `Tên miền có dấu hiệu giả mạo thương hiệu ${b.name} (Đuôi miền: ${hostname}).`
                    };
                }
            }
        }

        // Bẫy thu thập mã Smart OTP hoặc cờ bạc
        if (lower.includes("dang-nhap-otp") || lower.includes("xac-thuc-smart-otp") || lower.includes("vneid-dinhdanh")) {
            return {
                is_danger: true,
                badge: "BẪY ĐÁNH CẮP OTP",
                reason: "Đường dẫn chứa cấu trúc giả mạo thu thập mã OTP ngân hàng."
            };
        }

        return { is_danger: false, is_suspicious: false };
    }

    const check = fastClientHeuristic(currentHostname, currentUrl);

    // 2. Chèn thanh cảnh báo nổi nếu phát hiện rủi ro (Floating Security Banner)
    function injectWarningBanner(badge, reason) {
        if (document.getElementById("pataware-safety-banner")) return;

        const banner = document.createElement("div");
        banner.id = "pataware-safety-banner";
        banner.style.cssText = `
            position: fixed !important;
            top: 0 !important;
            left: 0 !important;
            width: 100% !important;
            z-index: 2147483647 !important;
            background: linear-gradient(90deg, #991b1b, #dc2626) !important;
            color: #ffffff !important;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
            font-size: 13px !important;
            font-weight: 500 !important;
            padding: 8px 16px !important;
            box-shadow: 0 4px 12px rgba(0,0,0,0.3) !important;
            display: flex !important;
            align-items: center !important;
            justify-content: space-between !important;
            box-sizing: border-box !important;
        `;

        banner.innerHTML = `
            <div style="display: flex; align-items: center; gap: 10px;">
                <span style="background: rgba(255,255,255,0.25); padding: 2px 8px; border-radius: 4px; font-weight: 700; font-size: 11px; letter-spacing: 0.5px;">
                    🛡️ PATAWARE SHIELD
                </span>
                <span><strong>[${badge}]:</strong> ${reason} <em>Tuyệt đối không nhập mật khẩu hay mã OTP!</em></span>
            </div>
            <button id="pataware-close-banner" style="background: transparent; border: none; color: #fff; font-size: 16px; cursor: pointer; padding: 0 4px; line-height: 1;">
                &times;
            </button>
        `;

        if (document.body) {
            document.body.prepend(banner);
        } else {
            document.addEventListener("DOMContentLoaded", () => {
                document.body.prepend(banner);
            });
        }

        setTimeout(() => {
            const closeBtn = document.getElementById("pataware-close-banner");
            if (closeBtn) {
                closeBtn.addEventListener("click", () => banner.remove());
            }
        }, 100);
    }

    if (check.is_suspicious || check.is_danger) {
        injectWarningBanner(check.badge, check.reason);
    }
})();
