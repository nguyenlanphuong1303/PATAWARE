// ==============================================================================
// PATAWARE BROWSER EXTENSION - SERVICE WORKER (BACKGROUND SCRIPT)
// Bảo vệ thời gian thực: Chặn Lừa đảo, Cờ bạc/Cá độ & Nội dung người lớn (Parental Control)
// ==============================================================================

const API_ENDPOINT = "http://localhost:8000/api/v1/scan/inspect";

// Bộ nhớ đệm kết quả kiểm tra (tránh gọi API lặp lại)
const scanCache = new Map();
// Danh sách domain người dùng bấm "vẫn tiếp tục truy cập"
const tempAllowedDomains = new Set();

// Danh sách domain uy tín không bao giờ chặn
const SYSTEM_WHITELIST = [
    "google.com", "google.com.vn", "youtube.com", "facebook.com", "messenger.com",
    "github.com", "microsoft.com", "apple.com", "wikipedia.org", "gov.vn",
    "chongluadao.vn", "pataware.com", "localhost"
];

// Khởi tạo trạng thái bảo vệ (mặc định BẬT cả Khiên lừa đảo và Bảo vệ trẻ em)
chrome.runtime.onInstalled.addListener(() => {
    chrome.storage.local.set({ 
        isShieldActive: true, 
        isParentalActive: true, 
        blockedCount: 0 
    });
    console.log("[PATAWARE] Tiện ích Chống Lừa Đảo & Bảo Vệ Trẻ Em (Parental Control) đã sẵn sàng.");
});

function getDomainFromUrl(url) {
    try {
        const parsed = new URL(url);
        return parsed.hostname.toLowerCase();
    } catch {
        return "";
    }
}

function isExcludedUrl(url) {
    if (!url) return true;
    const lower = url.toLowerCase();
    if (lower.startsWith("chrome://") || lower.startsWith("edge://") || 
        lower.startsWith("chrome-extension://") || lower.startsWith("about:") ||
        lower.startsWith("file://") || lower.includes("localhost") || lower.includes("127.0.0.1")) {
        return true;
    }
    const domain = getDomainFromUrl(url);
    for (const w of SYSTEM_WHITELIST) {
        if (domain === w || domain.endsWith("." + w)) {
            return true;
        }
    }
    return false;
}

// Phân tích Heuristics chạy độc lập (0ms độ trễ)
function analyzeHeuristics(url, domain) {
    const lower = (url + " " + domain).toLowerCase();
    const clean = lower.replace(/[^a-z0-9]/g, '');
    let score = 0;
    let reasons = [];
    let category = "PHISHING";

    // 1. Kiểm tra Cờ bạc, Cá độ, Game bài đổi thưởng
    const gamblingKeywords = [
        "kubet", "ku789", "ku11", "thabet", "tha789", "sunwin", "go88", "b52club", "nohu", "rikvip",
        "w88", "fun88", "fb88", "m88", "188bet", "bet188", "bk8", "jun88", "new88", "hi88", "shbet",
        "f8bet", "789bet", "okvip", "mb66", "789club", "taixiu", "keonhacai", "socdia", "daga", "casino",
        "cacuoc", "xoso66", "lode88", "banca"
    ];

    for (const kw of gamblingKeywords) {
        if (lower.includes(kw) || clean.includes(kw)) {
            score = 95;
            category = "GAMBLING";
            reasons.push(`Phát hiện dấu hiệu website cờ bạc, cá cược bóng đá hoặc game bài đổi thưởng trái phép (${kw}).`);
            break;
        }
    }

    // 2. Kiểm tra Nội dung Người lớn (18+ / Parental Control)
    if (score < 70) {
        const adultKeywords = [
            "porn", "xvideos", "xnxx", "phimsex", "javhd", "hentai", "sexvn", "vlxx", "lauxanh",
            "gaixinh18", "goidau", "showhang", "clipnong", "thudam", "sextube", "pornhub", "stripchat"
        ];
        for (const kw of adultKeywords) {
            if (lower.includes(kw) || clean.includes(kw)) {
                score = 92;
                category = "ADULT";
                reasons.push(`Nội dung người lớn 18+ không phù hợp với học sinh/trẻ em (${kw}).`);
                break;
            }
        }
    }

    // 3. Kiểm tra Punycode
    if (score < 70 && domain.includes("xn--")) {
        score = 90;
        category = "PHISHING";
        reasons.push("Tên miền sử dụng mã hóa Punycode xn-- (tấn công ký tự đồng hình giả mạo).");
    }

    // 4. Mạo danh thương hiệu ngân hàng (Typosquatting)
    if (score < 70) {
        const brands = [
            { name: "Vietcombank", keys: ["vietcombank", "vietc0mbank", "vcb"] },
            { name: "Techcombank", keys: ["techcombank", "tcb"] },
            { name: "MBBank", keys: ["mbbank", "mb-bank", "mbbnk"] },
            { name: "Shopee", keys: ["shopee", "sh0pee"] },
            { name: "VNeID", keys: ["vneid", "dinhdanh"] },
            { name: "MoMo", keys: ["momo-pay", "momo-vn"] }
        ];

        const riskyTlds = [".xyz", ".top", ".site", ".cc", ".icu", ".vip", ".club", ".space", ".work", ".cfd"];
        const hasRiskyTld = riskyTlds.some(tld => domain.endsWith(tld));

        for (const b of brands) {
            for (const k of b.keys) {
                if (lower.includes(k)) {
                    if (!domain.endsWith(".com.vn") && !domain.endsWith(".vn") && !domain.endsWith(".techcombank.com")) {
                        score = 92;
                        category = "PHISHING";
                        reasons.push(`Phát hiện dấu hiệu mạo danh (Typosquatting) thương hiệu ${b.name}`);
                        if (hasRiskyTld) {
                            score = 98;
                            reasons.push("Sử dụng đuôi tên miền giá rẻ rủi ro cao thường thấy trong các đợt tấn công lừa đảo.");
                        }
                        break;
                    }
                }
            }
        }
    }

    // 5. Cấu trúc lừa đảo bẫy OTP
    if (score < 70 && (lower.includes("dang-nhap-otp") || lower.includes("nhantien-hotro") || lower.includes("treo-thuong-tet"))) {
        score = 95;
        category = "PHISHING";
        reasons.push("Đường dẫn chứa cấu trúc giả mạo thu thập mã OTP hoặc bẫy nhận tiền hỗ trợ.");
    }

    return {
        is_malicious: score >= 70,
        risk_score: score,
        risk_level: score >= 70 ? "DANGEROUS" : (score >= 40 ? "SUSPICIOUS" : "SAFE"),
        category: category,
        reasons: reasons
    };
}

// Kiểm tra trang web với PATAWARE Backend API
async function checkUrlWithPataware(url) {
    const domain = getDomainFromUrl(url);

    if (scanCache.has(domain)) {
        return scanCache.get(domain);
    }

    let result = null;

    try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 1800);

        const res = await fetch(API_ENDPOINT, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ input_type: "url", content: url }),
            signal: controller.signal
        });
        clearTimeout(timeoutId);

        if (res.ok) {
            const data = await res.json();
            // Trích xuất category nếu có
            let cat = "PHISHING";
            const indStr = (data.scam_indicators || []).join(" ").toLowerCase();
            if (indStr.includes("cờ bạc") || indStr.includes("cá cược") || indStr.includes("gambling")) {
                cat = "GAMBLING";
            } else if (indStr.includes("người lớn") || indStr.includes("parental") || indStr.includes("adult")) {
                cat = "ADULT";
            }

            result = {
                is_malicious: (data.risk_score >= 70),
                risk_score: data.risk_score || 0,
                risk_level: data.risk_level || "SAFE",
                category: cat,
                reasons: data.scam_indicators || []
            };
        }
    } catch {
        // Fallback sang Heuristics
    }

    if (!result) {
        result = analyzeHeuristics(url, domain);
    }

    scanCache.set(domain, result);
    return result;
}

// Chặn điều hướng trước khi tải trang
chrome.webNavigation.onBeforeNavigate.addListener(async (details) => {
    if (details.frameId !== 0) return;

    const url = details.url;
    if (isExcludedUrl(url)) return;

    const domain = getDomainFromUrl(url);
    if (tempAllowedDomains.has(domain)) return;

    const storage = await chrome.storage.local.get(["isShieldActive", "isParentalActive", "blockedCount"]);
    if (storage.isShieldActive === false) return;

    const result = await checkUrlWithPataware(url);

    if (result && result.is_malicious) {
        // Nếu là trang cờ bạc hoặc người lớn nhưng người dùng tắt Parental Control thì bỏ qua
        if ((result.category === "GAMBLING" || result.category === "ADULT") && storage.isParentalActive === false) {
            return;
        }

        const newCount = (storage.blockedCount || 0) + 1;
        chrome.storage.local.set({ blockedCount: newCount });

        chrome.action.setBadgeText({ tabId: details.tabId, text: "!" });
        chrome.action.setBadgeBackgroundColor({ tabId: details.tabId, color: "#EF4444" });

        const warningUrl = chrome.runtime.getURL("warning.html") + 
            `?url=${encodeURIComponent(url)}` +
            `&domain=${encodeURIComponent(domain)}` +
            `&score=${encodeURIComponent(result.risk_score)}` +
            `&level=${encodeURIComponent(result.risk_level)}` +
            `&category=${encodeURIComponent(result.category || "PHISHING")}` +
            `&reasons=${encodeURIComponent(JSON.stringify(result.reasons))}`;

        chrome.tabs.update(details.tabId, { url: warningUrl });
    } else {
        chrome.action.setBadgeText({ tabId: details.tabId, text: "" });
    }
});

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === "ALLOW_TEMPORARY") {
        if (request.domain) {
            tempAllowedDomains.add(request.domain.toLowerCase());
            sendResponse({ success: true });
        }
    } else if (request.action === "CHECK_CURRENT_TAB") {
        chrome.tabs.query({ active: true, currentWindow: true }, async (tabs) => {
            if (tabs && tabs[0] && tabs[0].url) {
                const url = tabs[0].url;
                const domain = getDomainFromUrl(url);
                const isExcluded = isExcludedUrl(url);
                const check = isExcluded ? { is_malicious: false, risk_score: 5, risk_level: "SAFE", category: "NONE", reasons: ["Trang web an toàn mặc định."] } : await checkUrlWithPataware(url);
                sendResponse({ url, domain, ...check });
            } else {
                sendResponse({ error: "Không lấy được thông tin tab" });
            }
        });
        return true;
    }
});
