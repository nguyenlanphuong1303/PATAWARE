// ==============================================================================
// PATAWARE BROWSER EXTENSION - REAL-TIME INTERCEPTION BACKGROUND SERVICE WORKER
// Bảo vệ thời gian thực: Chặn Lừa đảo, Cờ bạc/Cá độ & Nội dung người lớn (Parental Control)
// ==============================================================================

const API_QUICK_CHECK = "http://localhost:8000/api/v1/scan/quick-check";
const API_ENDPOINT = "http://localhost:8000/api/v1/scan/inspect";

// Bộ nhớ đệm kết quả kiểm tra (RAM Map + Storage Local)
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
    console.log("[PATAWARE] Tiện ích Chống Lừa Đảo & Real-time Interception đã sẵn sàng.");
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

// Thuật toán khoảng cách Levenshtein chạy trực tiếp trên Client (0ms)
function levenshteinDist(s1, s2) {
    if (s1 === s2) return 0;
    const l1 = s1.length, l2 = s2.length;
    if (l1 === 0) return l2;
    if (l2 === 0) return l1;
    
    const d = [];
    for (let i = 0; i <= l1; i++) {
        d[i] = [i];
    }
    for (let j = 0; j <= l2; j++) {
        d[0][j] = j;
    }
    for (let i = 1; i <= l1; i++) {
        for (let j = 1; j <= l2; j++) {
            const cost = s1[i - 1] === s2[j - 1] ? 0 : 1;
            d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost);
        }
    }
    return d[l1][l2];
}

// TẦNG 1: Phân tích Client-side Heuristics tức thì (Độ trễ 0ms)
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

    // 3. Kiểm tra Punycode & Ký tự đồng hình (Homoglyph)
    if (score < 70 && domain.includes("xn--")) {
        score = 90;
        category = "PHISHING";
        reasons.push("Tên miền sử dụng mã hóa Punycode xn-- (dấu hiệu giả mạo ký tự đồng hình).");
    }

    // 4. Mạo danh thương hiệu (Typosquatting & Leetspeak & Levenshtein)
    if (score < 70) {
        const brands = [
            { name: "Vietcombank", keys: ["vietcombank", "vcb"], official: "vietcombank.com.vn" },
            { name: "Techcombank", keys: ["techcombank", "tcb"], official: "techcombank.com" },
            { name: "MBBank", keys: ["mbbank", "mb-bank"], official: "mbbank.com.vn" },
            { name: "BIDV", keys: ["bidv"], official: "bidv.com.vn" },
            { name: "VietinBank", keys: ["vietinbank"], official: "vietinbank.vn" },
            { name: "VPBank", keys: ["vpbank"], official: "vpbank.com.vn" },
            { name: "ACB", keys: ["acbbank", "acb-bank"], official: "acb.com.vn" },
            { name: "Shopee", keys: ["shopee"], official: "shopee.vn" },
            { name: "VNeID", keys: ["vneid", "dinhdanh"], official: "vneid.gov.vn" },
            { name: "Bộ Công An", keys: ["bocongan", "dichvucong-bca"], official: "bocongan.gov.vn" },
            { name: "MoMo", keys: ["momo-pay", "momo-vn"], official: "momo.vn" },
            { name: "ZaloPay", keys: ["zalopay"], official: "zalopay.vn" },
            { name: "Điện Lực EVN", keys: ["dienluc-evn", "evn-tracuu"], official: "evn.com.vn" }
        ];

        // Chuẩn hóa Leetspeak (0 -> o, 1 -> l/i, 3 -> e, 5 -> s)
        const leetClean = clean.replace(/0/g, 'o').replace(/1/g, 'l').replace(/3/g, 'e').replace(/5/g, 's');
        const riskyTlds = [".xyz", ".top", ".site", ".cc", ".icu", ".vip", ".club", ".space", ".work", ".cfd", ".online", ".me"];
        const hasRiskyTld = riskyTlds.some(tld => domain.endsWith(tld));

        for (const b of brands) {
            const isOfficial = domain === b.official || domain.endsWith("." + b.official);
            if (isOfficial) continue;

            for (const k of b.keys) {
                // Xuất hiện từ khóa hoặc qua Leetspeak
                if (lower.includes(k) || leetClean.includes(k)) {
                    score = hasRiskyTld ? 98 : 92;
                    category = "PHISHING";
                    reasons.push(`Phát hiện dấu hiệu mạo danh thương hiệu ${b.name} (Typosquatting/Leetspeak).`);
                    if (hasRiskyTld) {
                        reasons.push("Sử dụng đuôi tên miền giá rẻ rủi ro cao thường thấy trong các chiến dịch lừa đảo.");
                    }
                    break;
                }

                // Khoảng cách Levenshtein trên token
                const tokens = domain.split(/[-.]/);
                for (const tok of tokens) {
                    if (tok.length >= 4 && Math.abs(tok.length - k.length) <= 2) {
                        const dist = levenshteinDist(tok, k);
                        if (dist === 1 || dist === 2) {
                            score = 88;
                            category = "PHISHING";
                            reasons.push(`Cụm từ '${tok}' có độ tương đồng rất cao (${dist} ký tự sai khác) với '${b.name}'.`);
                            break;
                        }
                    }
                }
            }
            if (score >= 70) break;
        }
    }

    // 5. Cấu trúc lừa đảo bẫy OTP / giải ngân / nhận quà
    if (score < 70 && (
        lower.includes("dang-nhap-otp") || 
        lower.includes("xac-thuc-smart-otp") || 
        lower.includes("nhantien-hotro") || 
        lower.includes("treo-thuong-tet") || 
        lower.includes("nhan-qua-tri-an")
    )) {
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

// TẦNG 2: Kiểm tra ngầm bất đồng bộ với Pataware Backend API (/quick-check)
async function checkUrlWithBackend(url) {
    const domain = getDomainFromUrl(url);

    if (scanCache.has(domain)) {
        return scanCache.get(domain);
    }

    let result = null;

    try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 1200); // 1.2s timeout

        const res = await fetch(API_QUICK_CHECK, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ url: url }),
            signal: controller.signal
        });
        clearTimeout(timeoutId);

        if (res.ok) {
            const data = await res.json();
            result = {
                is_malicious: Boolean(data.is_malicious),
                risk_score: data.risk_score || 0,
                risk_level: data.risk_level || "SAFE",
                category: data.category || "PHISHING",
                reasons: data.reasons || []
            };
        }
    } catch (e) {
        // Nếu API backend offline, không làm gián đoạn người dùng
    }

    if (result) {
        scanCache.set(domain, result);
        // Lưu persistent cache
        chrome.storage.local.set({ [domain]: result });
    }

    return result;
}

// Hàm kích hoạt chuyển hướng cảnh báo đỏ (Warning Page)
function triggerWarning(tabId, url, domain, result) {
    chrome.action.setBadgeText({ tabId: tabId, text: "!" });
    chrome.action.setBadgeBackgroundColor({ tabId: tabId, color: "#EF4444" });

    const warningUrl = chrome.runtime.getURL("warning.html") + 
        `?url=${encodeURIComponent(url)}` +
        `&domain=${encodeURIComponent(domain)}` +
        `&score=${encodeURIComponent(result.risk_score)}` +
        `&level=${encodeURIComponent(result.risk_level)}` +
        `&category=${encodeURIComponent(result.category || "PHISHING")}` +
        `&reasons=${encodeURIComponent(JSON.stringify(result.reasons))}`;

    chrome.tabs.update(tabId, { url: warningUrl });
}

// ==============================================================================
// REAL-TIME INTERCEPTION PIPELINE: CHẶN TRƯỚC KHI TRANG TẢI (0MS LATENCY)
// ==============================================================================
chrome.webNavigation.onBeforeNavigate.addListener(async (details) => {
    if (details.frameId !== 0) return; // Chỉ áp dụng cho khung chính (Main Frame)

    const url = details.url;
    if (isExcludedUrl(url)) return;

    const domain = getDomainFromUrl(url);
    if (tempAllowedDomains.has(domain)) return;

    const storage = await chrome.storage.local.get(["isShieldActive", "isParentalActive", "blockedCount"]);
    if (storage.isShieldActive === false) return;

    // --- BƯỚC 1: KIỂM TRA BỘ NHỚ ĐỆM (CACHE) TRƯỚC (0ms) ---
    if (scanCache.has(domain)) {
        const cached = scanCache.get(domain);
        if (cached && cached.is_malicious) {
            if ((cached.category === "GAMBLING" || cached.category === "ADULT") && storage.isParentalActive === false) {
                return;
            }
            triggerWarning(details.tabId, url, domain, cached);
            return;
        }
    }

    // --- BƯỚC 2: CHẠY HEURISTIC TỨC THÌ TRÊN CLIENT-SIDE (0ms ĐỘ TRỄ) ---
    const localResult = analyzeHeuristics(url, domain);
    if (localResult.is_malicious) {
        if ((localResult.category === "GAMBLING" || localResult.category === "ADULT") && storage.isParentalActive === false) {
            return;
        }

        const newCount = (storage.blockedCount || 0) + 1;
        chrome.storage.local.set({ blockedCount: newCount });
        scanCache.set(domain, localResult);

        // Chặn và điều hướng sang trang cảnh báo NGAY LẬP TỨC (0ms) trước khi mạng tải xong!
        triggerWarning(details.tabId, url, domain, localResult);
        return;
    }

    // --- BƯỚC 3: GỬI NGẦM VỀ API BACKEND KIỂM TRA ĐA TẦNG (ASYNC CHECK) ---
    checkUrlWithBackend(url).then(async (backendResult) => {
        if (backendResult && backendResult.is_malicious) {
            if ((backendResult.category === "GAMBLING" || backendResult.category === "ADULT") && storage.isParentalActive === false) {
                return;
            }

            // Kiểm tra xem tab hiện tại có còn đang ở domain đó không
            try {
                const currentTab = await chrome.tabs.get(details.tabId);
                if (currentTab && getDomainFromUrl(currentTab.url) === domain) {
                    const newCount = (storage.blockedCount || 0) + 1;
                    chrome.storage.local.set({ blockedCount: newCount });
                    triggerWarning(details.tabId, url, domain, backendResult);
                }
            } catch {
                // Tab đã đóng
            }
        }
    });
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
                if (isExcluded) {
                    sendResponse({ url, domain, is_malicious: false, risk_score: 5, risk_level: "SAFE", category: "NONE", reasons: ["Trang web an toàn mặc định."] });
                } else {
                    // Ưu tiên Heuristic + Backend
                    const local = analyzeHeuristics(url, domain);
                    if (local.is_malicious) {
                        sendResponse({ url, domain, ...local });
                    } else {
                        const backend = await checkUrlWithBackend(url);
                        sendResponse({ url, domain, ...(backend || local) });
                    }
                }
            } else {
                sendResponse({ error: "Không lấy được thông tin tab" });
            }
        });
        return true;
    }
});
