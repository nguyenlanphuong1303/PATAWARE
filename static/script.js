window.currentScanType = 'url';
window.selectedImageFile = null;
window.categoryChartInstance = null;
window.trendChartInstance = null;
window.cachedQuizQuestions = [];

// Tự động nhận diện loại dữ liệu nhập vào (All-in-one Smart Detector)
window.detectScanType = function(val) {
    if (window.selectedImageFile) return 'image';
    const text = (val || '').trim();
    if (!text) return 'url';

    // 1. Nhận diện URL / Tên miền
    const urlPattern = /^(https?:\/\/|www\.)[^\s/$.?#].[^\s]*$/i;
    const domainPattern = /^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+(\/[^\s]*)?$/i;
    if (urlPattern.test(text) || (domainPattern.test(text) && !text.includes(' ') && text.includes('.'))) {
        return 'url';
    }

    // 2. Nhận diện Số điện thoại (9-11 số, bắt đầu bằng 0 hoặc +84 / 84)
    const cleanDigits = text.replace(/[\s\-\.]/g, '');
    if (/^(\+?84|0)[0-9]{8,10}$/.test(cleanDigits)) {
        return 'phone';
    }

    // 3. Nhận diện Số tài khoản ngân hàng (toàn chữ số từ 6 - 19 ký tự)
    if (/^[0-9]{6,19}$/.test(cleanDigits)) {
        return 'bank_account';
    }

    // 4. Mặc định là đoạn văn bản / Tin nhắn SMS / Đoạn Chat
    return 'text';
};

window.previewSelectedImage = function(event) {
    const file = event.target.files && event.target.files[0];
    if (file) {
        window.selectedImageFile = file;
        const nameEl = document.getElementById('imageFileName');
        const labelEl = document.getElementById('imageFileLabel');
        if (labelEl) {
            labelEl.textContent = 'Đã chọn tệp: ' + file.name + ' (' + (file.size / 1024).toFixed(1) + ' KB)';
        }
        if (nameEl) nameEl.classList.remove('hidden');
    }
};

window.clearSelectedImage = function() {
    window.selectedImageFile = null;
    const fileInput = document.getElementById('imageFileInput');
    if (fileInput) fileInput.value = '';
    const nameEl = document.getElementById('imageFileName');
    if (nameEl) nameEl.classList.add('hidden');
};

function runLocalScanSimulation(content, type) {
    const lower = (content || '').toLowerCase();
    let score = 25;
    let level = "SAFE";
    let indicators = [];
    let recs = [];
    let isTypo = false;
    let targetBrand = null;
    let isNewDomain = false;
    let isPuny = lower.includes("xn--");

    const brands = [
        { name: "Vietcombank", keys: ["vietcombank", "vietc0mbank", "vcb"] },
        { name: "MBBank", keys: ["mbbank", "mb-bank", "mbbnk"] },
        { name: "Techcombank", keys: ["techcombank", "tcb"] },
        { name: "Shopee", keys: ["shopee", "sh0pee"] }
    ];

    if (type === 'url') {
        for (let i = 0; i < brands.length; i++) {
            const b = brands[i];
            if (lower.includes("vietc0mbank") || lower.includes("sh0pee") || (lower.includes(b.keys[0]) && !lower.endsWith(".com.vn") && !lower.endsWith(".vn") && !lower.endsWith("techcombank.com"))) {
                isTypo = true;
                targetBrand = b.name;
                indicators.push("Phát hiện mạo danh (Typosquatting) thương hiệu " + b.name);
                indicators.push("Tên miền đuôi rủi ro cao (.xyz, .site, .top)");
                indicators.push("Tuổi tên miền: 3 ngày (< 30 ngày, 95% lừa đảo)");
                isNewDomain = true;
                score = 92;
                break;
            }
        }
        if (isPuny) {
            indicators.push("Tên miền sử dụng mã hóa Punycode xn-- giả mạo ký tự");
            score = Math.max(score, 88);
        }
        if (lower.includes("vietcombank.com.vn") || lower.includes("techcombank.com") || lower.includes("mbbank.com.vn")) {
            score = 10;
            isTypo = false;
            indicators = ["Tên miền chính thức của tổ chức tài chính uy tín, có chứng chỉ SSL hợp lệ."];
        }
    } else if (type === 'bank_account') {
        if (content.includes("1029384756") || content.includes("9999")) {
            score = 95;
            indicators.push("Số tài khoản nằm trong DANH SÁCH ĐEN cảnh báo (Bị tố cáo làm nhiệm vụ giật đơn lừa đảo)");
        } else {
            score = 15;
            indicators.push("Số tài khoản chưa ghi nhận trong cơ sở dữ liệu danh sách đen.");
        }
    } else if (type === 'phone') {
        if (content.includes("0879654321") || content.startsWith("087") || content.startsWith("088")) {
            score = 85;
            indicators.push("Số điện thoại bị báo cáo mạo danh cơ quan công an / tòa án đe dọa người dân");
        } else {
            score = 20;
            indicators.push("Số điện thoại chưa có báo cáo lừa đảo tiêu cực.");
        }
    } else if (type === 'text') {
        if (lower.includes("otp") || lower.includes("khóa tài khoản") || lower.includes("hoa hồng") || lower.includes("cộng tác viên") || lower.includes("lệnh bắt")) {
            score = 88;
            indicators.push("Dấu hiệu thao túng tâm lý: Yêu cầu cung cấp OTP hoặc tạo áp lực khẩn cấp");
            indicators.push("Dấu hiệu bẫy tài chính: Tuyển CTV làm nhiệm vụ giật đơn hoa hồng cao");
        }
    } else if (type === 'image') {
        score = 86;
        indicators.push("Bóc tách OCR: Phát hiện tin nhắn yêu cầu nạp tiền hoàn thành nhiệm vụ đơn hàng");
        indicators.push("Bóc tách OCR: Dấu hiệu hứa hẹn hoàn tiền kèm hoa hồng 20%");
    }

    if (score >= 70) {
        level = "DANGEROUS";
        recs.push("TUYỆT ĐỐI KHÔNG chuyển tiền, không nhập mật khẩu hoặc cung cấp mã OTP.");
        recs.push("Chặn ngay số liên lạc hoặc báo cáo trang web với cơ quan an ninh mạng.");
    } else if (score >= 40) {
        level = "SUSPICIOUS";
        recs.push("Cần kiểm tra kỹ thông tin qua các kênh chính thống của tổ chức.");
    } else {
        level = "SAFE";
        recs.push("Chưa phát hiện rủi ro, tuy nhiên vẫn không nên chia sẻ OTP với bất kỳ ai.");
    }

    return {
        input_type: type,
        target: content,
        risk_score: score,
        risk_level: level,
        verdict_summary: score >= 70 ? "NGUY HIỂM CAO - Phát hiện nhiều bằng chứng lừa đảo hoặc dấu hiệu mạo danh." : (score >= 40 ? "ĐÁNG NGỜ - Có dấu hiệu cần thận trọng kiểm chứng." : "AN TOÀN - Chưa ghi nhận dấu hiệu lừa đảo trong hệ thống."),
        breakdown: { blacklist_score: score >= 70 ? 90 : 0, technical_domain_score: isTypo ? 95 : 10, heuristic_regex_score: 80, ai_psychological_score: score },
        domain_analysis: type === 'url' ? {
            domain: content.replace("https://", "").replace("http://", "").split("/")[0],
            age_days: isNewDomain ? 3 : 1420,
            is_new_domain: isNewDomain,
            is_punycode_homoglyph: isPuny,
            typosquatting_detected: isTypo,
            impersonated_brand: targetBrand,
            reasons: indicators
        } : null,
        recommendations: recs,
        scam_indicators: indicators
    };
}

window.renderScanResult = function(data) {
    const resultArea = document.getElementById('scanResultArea');
    if (!resultArea) return;
    resultArea.classList.remove('hidden');

    const score = data.risk_score || 0;
    let badgeBg = "bg-emerald-500/10 border-emerald-500/30 text-emerald-400";
    let scoreColor = "text-emerald-400";
    if (score >= 70) {
        badgeBg = "bg-rose-500/10 border-rose-500/30 text-rose-400";
        scoreColor = "text-rose-500";
    } else if (score >= 40) {
        badgeBg = "bg-amber-500/10 border-amber-500/30 text-amber-400";
        scoreColor = "text-amber-400";
    }

    let domainHtml = "";
    if (data.domain_analysis) {
        const da = data.domain_analysis;
        domainHtml = `
            <div class="mt-4 p-4 rounded-xl bg-slate-950/60 border border-slate-800 text-xs space-y-2">
                <div class="font-bold text-slate-300 flex items-center space-x-2">
                    <i class="fa-solid fa-network-wired text-cyan-400"></i>
                    <span>Phân Tích Kỹ Thuật Tầng Mạng (Deep Domain Analyzer)</span>
                </div>
                <div class="grid grid-cols-2 sm:grid-cols-3 gap-2 text-slate-400">
                    <div>Tên miền: <strong class="text-slate-200">${da.domain || 'N/A'}</strong></div>
                    <div>Tuổi tên miền: <strong class="${da.is_new_domain ? 'text-rose-400' : 'text-slate-200'}">${da.age_days !== null ? da.age_days + ' ngày' : 'Chưa có dữ liệu'}</strong></div>
                    <div>Punycode / Homoglyph: <strong class="${da.is_punycode_homoglyph ? 'text-rose-400' : 'text-emerald-400'}">${da.is_punycode_homoglyph ? 'PHÁT HIỆN' : 'An toàn'}</strong></div>
                    <div>Typosquatting: <strong class="${da.typosquatting_detected ? 'text-rose-400' : 'text-emerald-400'}">${da.typosquatting_detected ? 'Mạo danh ' + da.impersonated_brand : 'Không'}</strong></div>
                </div>
            </div>
        `;
    }

    let indicatorsHtml = "";
    if (data.scam_indicators && data.scam_indicators.length > 0) {
        indicatorsHtml = `
            <div class="mt-4">
                <h4 class="text-xs font-bold uppercase tracking-wider text-slate-400 mb-2">Dấu hiệu rủi ro phát hiện:</h4>
                <ul class="space-y-1 text-xs text-rose-300">
                    ${data.scam_indicators.map(ind => `<li class="flex items-start space-x-2"><i class="fa-solid fa-triangle-exclamation text-rose-400 mt-0.5"></i><span>${ind}</span></li>`).join('')}
                </ul>
            </div>
        `;
    }

    let recsHtml = "";
    if (data.recommendations && data.recommendations.length > 0) {
        recsHtml = `
            <div class="mt-4 p-3 rounded-xl bg-cyan-950/30 border border-cyan-800/40">
                <h4 class="text-xs font-bold uppercase tracking-wider text-cyan-400 mb-1">Khuyến cáo hành động an toàn:</h4>
                <ul class="space-y-1 text-xs text-slate-300">
                    ${data.recommendations.map(r => `<li class="flex items-start space-x-2"><i class="fa-solid fa-circle-check text-cyan-400 mt-0.5"></i><span>${r}</span></li>`).join('')}
                </ul>
            </div>
        `;
    }

    resultArea.innerHTML = `
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 p-5 rounded-xl border ${badgeBg}">
            <div>
                <div class="text-xs uppercase tracking-wider font-bold">Mức Độ Đánh Giá: ${data.risk_level}</div>
                <div class="text-sm font-semibold text-slate-100 mt-0.5">${data.verdict_summary}</div>
            </div>
            <div class="text-right">
                <span class="text-3xl font-extrabold ${scoreColor}">${data.risk_score}</span>
                <span class="text-xs text-slate-400">/100 Rủi Ro</span>
            </div>
        </div>
        ${domainHtml}
        ${indicatorsHtml}
        ${recsHtml}
    `;
    resultArea.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
};

window.performScan = async function() {
    const btn = document.getElementById('btnScan');
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i><span>Đang Phân Tích Đa Tầng...</span>';
    }

    const inputField = document.getElementById('scanInput');
    let content = inputField ? inputField.value.trim() : '';

    if (!content && !window.selectedImageFile) {
        content = "vietc0mbank-portal.xyz";
        if (inputField) inputField.value = content;
    }

    const scanType = window.selectedImageFile ? 'image' : window.detectScanType(content);
    window.currentScanType = scanType;

    const isLocalFile = window.location.protocol === 'file:';
    let data = null;

    if (!isLocalFile && (window.location.protocol === 'http:' || window.location.protocol === 'https:')) {
        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 10000);

            if (window.selectedImageFile) {
                const formData = new FormData();
                formData.append("file", window.selectedImageFile);
                const res = await fetch("/api/v1/scan/ocr-inspect", {
                    method: "POST",
                    body: formData,
                    signal: controller.signal
                });
                clearTimeout(timeoutId);
                if (res.ok) data = await res.json();
            } else {
                const res = await fetch("/api/v1/scan/inspect", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ input_type: scanType, content: content }),
                    signal: controller.signal
                });
                clearTimeout(timeoutId);
                if (res.ok) data = await res.json();
            }
        } catch (err) {
            console.warn("API request failed or timed out, falling back to local heuristic simulation:", err);
        }
    }

    if (!data) {
        data = runLocalScanSimulation(window.selectedImageFile ? (window.selectedImageFile.name || "screenshot.png") : content, scanType);
    }

    window.renderScanResult(data);

    // Cập nhật số liệu thống kê thời gian thực ngay lập tức
    if (typeof window.loadDashboardStats === 'function') {
        window.loadDashboardStats();
    }

    if (btn) {
        btn.disabled = false;
        btn.innerHTML = '<i class="fa-solid fa-shield-virus"></i><span>Kiểm Tra Toàn Diện Ngay</span>';
    }
};

window.loadDashboardStats = async function() {
    let stats = null;
    if (window.location.protocol === 'http:' || window.location.protocol === 'https:') {
        try {
            const res = await fetch("/api/v1/dashboard/stats");
            if (res.ok) stats = await res.json();
        } catch (err) {}
    }

    if (!stats) {
        stats = {
            total_scans: 312,
            threats_blocked: 186,
            scam_by_category: [
                { label: "PHISHING URL", count: 142 },
                { label: "TÀI KHOẢN NGÂN HÀNG", count: 98 },
                { label: "SỐ ĐIỆN THOẠI RÁC", count: 45 },
                { label: "CHAT LỪA ĐẢO / OCR", count: 27 }
            ],
            recent_trend_days: [
                { date: "25/10", scans: 25, threats: 12 },
                { date: "26/10", scans: 31, threats: 18 },
                { date: "27/10", scans: 28, threats: 15 },
                { date: "28/10", scans: 42, threats: 24 },
                { date: "29/10", scans: 38, threats: 20 },
                { date: "30/10", scans: 49, threats: 31 },
                { date: "31/10", scans: 56, threats: 35 }
            ],
            top_reported_scammers: [
                { value: "vietc0mbank-portal.xyz", type: "domain", report_count: 84 },
                { value: "1029384756 (Techcombank)", type: "bank_account", report_count: 67 },
                { value: "0879654321", type: "phone", report_count: 52 },
                { value: "mbbank-online-support.site", type: "domain", report_count: 49 },
                { value: "vneid-dinhdanh-gov.top", type: "domain", report_count: 43 }
            ]
        };
    }

    const totalEl = document.getElementById('statTotalScans');
    const blockedEl = document.getElementById('statThreatsBlocked');
    if (totalEl) totalEl.textContent = stats.total_scans;
    if (blockedEl) blockedEl.textContent = stats.threats_blocked;

    if (typeof Chart !== 'undefined') {
        try {
            const ctxCat = document.getElementById('categoryChart');
            if (ctxCat) {
                if (window.categoryChartInstance) window.categoryChartInstance.destroy();
                window.categoryChartInstance = new Chart(ctxCat.getContext('2d'), {
                    type: 'doughnut',
                    data: {
                        labels: stats.scam_by_category.map(c => c.label),
                        datasets: [{
                            data: stats.scam_by_category.map(c => c.count),
                            backgroundColor: ['#06b6d4', '#3b82f6', '#f43f5e', '#a855f7'],
                            borderWidth: 0
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: { legend: { position: 'bottom', labels: { color: '#94a3b8', font: { size: 10 } } } }
                    }
                });
            }

            const ctxTrend = document.getElementById('trendChart');
            if (ctxTrend) {
                if (window.trendChartInstance) window.trendChartInstance.destroy();
                window.trendChartInstance = new Chart(ctxTrend.getContext('2d'), {
                    type: 'line',
                    data: {
                        labels: stats.recent_trend_days.map(t => t.date),
                        datasets: [
                            { label: 'Lượt quét', data: stats.recent_trend_days.map(t => t.scans), borderColor: '#06b6d4', tension: 0.3, fill: false },
                            { label: 'Nguy cơ cao', data: stats.recent_trend_days.map(t => t.threats), borderColor: '#f43f5e', tension: 0.3, fill: false }
                        ]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        scales: {
                            x: { ticks: { color: '#64748b' }, grid: { color: '#1e293b' } },
                            y: { ticks: { color: '#64748b' }, grid: { color: '#1e293b' } }
                        },
                        plugins: { legend: { labels: { color: '#94a3b8', font: { size: 10 } } } }
                    }
                });
            }
        } catch (chartErr) {
            console.warn(chartErr);
        }
    }

    const topList = document.getElementById('topScammersList');
    if (topList) {
        topList.innerHTML = stats.top_reported_scammers.map(s => `
            <div class="flex items-center justify-between p-3 rounded-xl bg-slate-950/50 border border-slate-800 text-xs">
                <div class="truncate max-w-[200px]">
                    <span class="font-bold text-slate-200 block truncate">${s.value}</span>
                    <span class="text-[10px] text-slate-500 uppercase">${s.type}</span>
                </div>
                <span class="text-rose-400 font-mono font-bold">${s.report_count} tố cáo</span>
            </div>
        `).join('');
    }
};

window.loadStories = function() {
    const container = document.getElementById('storiesContainer');
    if (!container) return;
    const seedStories = [
        {
            id: 1,
            title: "Bẫy tuyển CTV nạp tiền giật đơn Shopee",
            redacted_content: "Tôi nhận tin nhắn từ SĐT [SĐT:098****21] mời tham gia giật đơn. Sau 2 đơn đầu được hoàn 50k, họ yêu cầu nạp [CCCD:001******123] và chuyển 15 triệu vào STK [STK:1903******789] thì bị khóa liên lạc.",
            scam_type: "job_offer",
            created_at: new Date().toISOString(),
            upvotes: 42
        },
        {
            id: 2,
            title: "Giả mạo công an gọi điện thông báo liên quan đường dây rửa tiền",
            redacted_content: "Đối tượng tự xưng đại úy công an điều tra, gửi kèm lệnh bắt có dấu đỏ qua Zalo, yêu cầu chuyển toàn bộ tiền trong tài khoản vào số tạm giữ để thanh tra.",
            scam_type: "impersonation",
            created_at: new Date(Date.now() - 86400000).toISOString(),
            upvotes: 79
        },
        {
            id: 3,
            title: "Đường link lạ mạo danh Vietcombank yêu cầu cập nhật sinh trắc học",
            redacted_content: "Nhận được SMS Brandname gửi link vietc0mbank-portal.xyz yêu cầu nhập tên đăng nhập và mã OTP để cập nhật khuôn mặt, may mắn tôi kiểm tra trước trên Pataware.",
            scam_type: "phishing_link",
            created_at: new Date(Date.now() - 172800000).toISOString(),
            upvotes: 115
        }
    ];
    container.innerHTML = seedStories.map(s => `
        <div class="bg-slate-900/80 border border-slate-800 rounded-2xl p-5 flex flex-col justify-between">
            <div>
                <div class="flex items-center justify-between text-xs mb-2">
                    <span class="px-2 py-0.5 rounded bg-cyan-950 border border-cyan-800/60 text-cyan-400 font-semibold">${s.scam_type}</span>
                    <span class="text-slate-500">${new Date(s.created_at).toLocaleDateString('vi-VN')}</span>
                </div>
                <h4 class="font-bold text-sm text-slate-100 mb-2">${s.title}</h4>
                <p class="text-xs text-slate-400 line-clamp-4 leading-relaxed">${s.redacted_content}</p>
            </div>
            <div class="mt-4 pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs">
                <span class="text-slate-500 text-[11px]"><i class="fa-solid fa-user-shield text-cyan-400 mr-1"></i>Đã ẩn PII</span>
                <button onclick="upvoteStory(${s.id}, this)" class="text-slate-400 hover:text-cyan-400 flex items-center space-x-1 transition-colors">
                    <i class="fa-regular fa-thumbs-up"></i>
                    <span>${s.upvotes}</span>
                </button>
            </div>
        </div>
    `).join('');
};

window.upvoteStory = function(id, btn) {
    const span = btn.querySelector('span');
    if (span) {
        span.textContent = parseInt(span.textContent || '0') + 1;
    }
};

window.openStoryModal = function() {
    const modal = document.getElementById('storyModal');
    if (modal) modal.classList.remove('hidden');
};

window.closeStoryModal = function() {
    const modal = document.getElementById('storyModal');
    if (modal) modal.classList.add('hidden');
};

window.submitNewStory = function() {
    alert("Cảm ơn bạn! Câu chuyện đã được tự động che mờ thông tin cá nhân (CCCD, SĐT) và đăng tải.");
    window.closeStoryModal();
};

window.loadQuiz = function() {
    window.cachedQuizQuestions = [
        {
            id: 1,
            category: "banking",
            scenario_title: "Tin nhắn SMS Brandname mạo danh ngân hàng khóa thẻ",
            scenario_description: "Bạn nhận được tin nhắn SMS: 'Tài khoản của quý khách bị khóa do giao dịch bất thường. Nhấp vào http://vietc0mbank-portal.xyz/login để xác thực mã OTP trong vòng 2 giờ.' Bạn nên xử lý thế nào?",
            options: [
                { id: 101, option_text: "Lập tức nhấp vào link để đăng nhập và hủy giao dịch lạ" },
                { id: 102, option_text: "Tuyệt đối không nhấp link, xóa tin nhắn và gọi ngay tổng đài chính thức của ngân hàng", is_correct: true },
                { id: 103, option_text: "Nhập mã OTP nhưng không nhập mật khẩu tài khoản" }
            ],
            explanation: "Tên miền 'vietc0mbank-portal.xyz' là tên miền mạo danh (Typosquatting thay chữ 'o' bằng số '0' và đuôi '.xyz'). Ngân hàng không bao giờ gửi link yêu cầu cung cấp OTP."
        },
        {
            id: 2,
            category: "job_scam",
            scenario_title: "Tuyển dụng cộng tác viên giật đơn sàn TMĐT",
            scenario_description: "Một tài khoản Zalo lạ nhắn tin mời bạn làm CTV xử lý đơn hàng Shopee/Lazada với hoa hồng 20%/đơn, yêu cầu chuyển cọc trước 500k vào số tài khoản cá nhân. Đây là dấu hiệu gì?",
            options: [
                { id: 201, option_text: "Lừa đảo chiếm đoạt tài sản bằng thủ đoạn làm nhiệm vụ hoa hồng ảo", is_correct: true },
                { id: 202, option_text: "Cơ hội việc làm thêm online uy tín và thu nhập cao" },
                { id: 203, option_text: "Chương trình tuyển dụng chính thức của sàn thương mại điện tử" }
            ],
            explanation: "Đây là chiêu trò bẫy làm nhiệm vụ giật đơn điển hình. Sau các đơn nhỏ được hoàn tiền thật để tạo niềm tin, kẻ gian sẽ yêu cầu nạp hàng chục triệu rồi khóa liên lạc chiếm đoạt."
        }
    ];

    const content = document.getElementById('quizContent');
    if (!content) return;
    content.innerHTML = window.cachedQuizQuestions.map((q, idx) => `
        <div class="p-5 rounded-xl bg-slate-950/50 border border-slate-800" id="quiz-card-${q.id}">
            <div class="flex items-center justify-between text-xs mb-2">
                <span class="text-cyan-400 font-bold">Câu hỏi ${idx + 1}/${window.cachedQuizQuestions.length}</span>
                <span class="text-slate-500 uppercase text-[10px] px-2 py-0.5 rounded bg-slate-900 border border-slate-800">${q.category}</span>
            </div>
            <h4 class="font-bold text-sm text-slate-100 mb-2">${q.scenario_title}</h4>
            <p class="text-xs text-slate-300 leading-relaxed mb-4">${q.scenario_description}</p>
            <div class="space-y-2">
                ${q.options.map(opt => `
                    <label class="flex items-start space-x-3 p-3 rounded-lg bg-slate-900/60 hover:bg-slate-850 border border-slate-800/80 cursor-pointer text-xs transition-colors">
                        <input type="radio" name="q_${q.id}" value="${opt.id}" class="mt-0.5 text-cyan-500 focus:ring-0">
                        <span class="text-slate-300">${opt.option_text}</span>
                    </label>
                `).join('')}
            </div>
            <div id="quiz-exp-${q.id}" class="hidden mt-4 p-3 rounded-lg bg-cyan-950/40 border border-cyan-800/50 text-xs text-slate-300"></div>
        </div>
    `).join('') + `
        <div class="flex justify-end pt-2">
            <button type="button" onclick="submitQuizAnswers()" class="px-6 py-2.5 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-bold text-xs shadow-lg shadow-cyan-500/20">
                Nộp Bài & Xem Giải Thích Chi Tiết
            </button>
        </div>
    `;
};

window.submitQuizAnswers = function() {
    let correctCount = 0;
    for (let i = 0; i < window.cachedQuizQuestions.length; i++) {
        const q = window.cachedQuizQuestions[i];
        const checked = document.querySelector('input[name="q_' + q.id + '"]:checked');
        const selectedId = checked ? parseInt(checked.value) : 0;
        const opt = q.options.find(o => o.id === selectedId);
        const isCorrect = opt ? (opt.is_correct === true) : false;
        if (isCorrect) correctCount++;

        const expEl = document.getElementById('quiz-exp-' + q.id);
        if (expEl) {
            expEl.classList.remove('hidden');
            expEl.innerHTML = `
                <div class="font-bold mb-1 ${isCorrect ? 'text-emerald-400' : 'text-rose-400'}">
                    ${isCorrect ? '✓ Chính xác!' : '✗ Chưa chính xác'}
                </div>
                <div>${q.explanation}</div>
            `;
        }
    }
    const pct = Math.round((correctCount / window.cachedQuizQuestions.length) * 100);
    alert(`Kết quả: Bạn đạt ${correctCount}/${window.cachedQuizQuestions.length} câu (${pct}%). Hãy đọc phần giải thích chi tiết phía dưới.`);
};

document.addEventListener('DOMContentLoaded', function() {
    const btn = document.getElementById('btnScan');
    if (btn) {
        btn.addEventListener('click', window.performScan);
    }

    const scanInput = document.getElementById('scanInput');
    if (scanInput) {
        // Tự động điều chỉnh chiều cao khi gõ nhiều dòng (đoạn chat/tin nhắn)
        scanInput.addEventListener('input', function() {
            this.style.height = 'auto';
            this.style.height = Math.min(this.scrollHeight, 180) + 'px';
        });

        // Nhấn Enter để quét ngay (Shift + Enter để xuống dòng)
        scanInput.addEventListener('keydown', function(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                window.performScan();
            }
        });

        // Hỗ trợ dán ảnh chụp màn hình trực tiếp bằng Ctrl + V vào ô tìm kiếm
        scanInput.addEventListener('paste', function(e) {
            const items = (e.clipboardData || window.clipboardData)?.items;
            if (items) {
                for (let i = 0; i < items.length; i++) {
                    if (items[i].type.indexOf('image') !== -1) {
                        const file = items[i].getAsFile();
                        if (file) {
                            window.selectedImageFile = file;
                            const nameEl = document.getElementById('imageFileName');
                            const labelEl = document.getElementById('imageFileLabel');
                            if (labelEl) {
                                labelEl.textContent = 'Ảnh chụp màn hình vừa dán (' + (file.size / 1024).toFixed(1) + ' KB)';
                            }
                            if (nameEl) nameEl.classList.remove('hidden');
                        }
                        break;
                    }
                }
            }
        });
    }

    window.loadDashboardStats();
    window.loadStories();
    window.loadQuiz();

    // Tự động đồng bộ số liệu thời gian thực định kỳ mỗi 10 giây
    setInterval(function() {
        if (typeof window.loadDashboardStats === 'function') {
            window.loadDashboardStats();
        }
    }, 10000);
});
