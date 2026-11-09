document.addEventListener('DOMContentLoaded', () => {
    const params = new URLSearchParams(window.location.search);
    const originalUrl = params.get('url') || '';
    const domain = params.get('domain') || 'Trang web không xác định';
    const score = params.get('score') || '95';
    const category = params.get('category') || 'PHISHING';
    let reasons = [];

    try {
        reasons = JSON.parse(params.get('reasons') || '[]');
    } catch {
        reasons = [];
    }

    // Tùy biến tiêu đề và giao diện theo Category (Cờ bạc, Người lớn, Lừa đảo)
    const warningIcon = document.getElementById('warningIcon');
    const warningBadgeIcon = document.getElementById('warningBadgeIcon');
    const warningBadgeText = document.getElementById('warningBadgeText');
    const warningTitle = document.getElementById('warningTitle');
    const warningSubtitle = document.getElementById('warningSubtitle');

    if (category === 'GAMBLING') {
        if (warningIcon) warningIcon.className = "fa-solid fa-dice text-4xl sm:text-5xl text-rose-500";
        if (warningBadgeIcon) warningBadgeIcon.className = "fa-solid fa-ban";
        if (warningBadgeText) warningBadgeText.textContent = "PHÒNG CHỐNG TỆ NẠN • CHẶN CỜ BẠC & CÁ CƯỢC";
        if (warningTitle) warningTitle.textContent = "Cảnh Báo: Trang Web Cờ Bạc / Cá Độ Đã Bị Chặn!";
        if (warningSubtitle) warningSubtitle.textContent = "Hệ thống PATAWARE đã tự động ngăn chặn trang web cờ bạc trực tuyến, cá cược bóng đá, game bài đổi thưởng này nhằm bảo vệ tài chính và tuân thủ pháp luật.";
    } else if (category === 'ADULT') {
        if (warningIcon) warningIcon.className = "fa-solid fa-user-shield text-4xl sm:text-5xl text-rose-500";
        if (warningBadgeIcon) warningBadgeIcon.className = "fa-solid fa-child-reaching";
        if (warningBadgeText) warningBadgeText.textContent = "BẢO VỆ TRẺ EM (PARENTAL CONTROL) • NỘI DUNG 18+ BỊ CHẶN";
        if (warningTitle) warningTitle.textContent = "Nội Dung Người Lớn Đã Bị Ngăn Chặn!";
        if (warningSubtitle) warningSubtitle.textContent = "Chế độ Bảo Vệ Trẻ Em (Parental Control) của PATAWARE đã chặn trang web này nhằm bảo vệ học sinh và trẻ nhỏ khỏi các nội dung nhạy cảm, độc hại.";
    }

    // Hiển thị domain và điểm số
    const domainEl = document.getElementById('targetDomainDisplay');
    if (domainEl) domainEl.textContent = domain;

    const scoreEl = document.getElementById('riskScoreDisplay');
    if (scoreEl) scoreEl.textContent = score;

    // Hiển thị danh sách lý do phát hiện
    const reasonsListEl = document.getElementById('reasonsList');
    if (reasonsListEl && reasons.length > 0) {
        reasonsListEl.innerHTML = reasons.map(r => `
            <li class="flex items-start space-x-2">
                <i class="fa-solid fa-circle-xmark text-rose-500 mt-0.5"></i>
                <span>${r}</span>
            </li>
        `).join('');
    }

    // Nút Quay lại an toàn
    const btnGoBack = document.getElementById('btnGoBack');
    if (btnGoBack) {
        btnGoBack.addEventListener('click', () => {
            if (window.history.length > 1) {
                window.history.back();
            } else {
                window.location.href = 'https://www.google.com';
            }
        });
    }

    // Nút Bật/Tắt khu vực nâng cao
    const btnToggleAdvanced = document.getElementById('btnToggleAdvanced');
    const advancedSection = document.getElementById('advancedSection');
    if (btnToggleAdvanced && advancedSection) {
        btnToggleAdvanced.addEventListener('click', () => {
            advancedSection.classList.toggle('hidden');
        });
    }

    // Nút Bỏ qua cảnh báo và tiếp tục truy cập
    const btnProceedAnyway = document.getElementById('btnProceedAnyway');
    if (btnProceedAnyway && originalUrl) {
        btnProceedAnyway.addEventListener('click', () => {
            chrome.runtime.sendMessage({ action: 'ALLOW_TEMPORARY', domain: domain }, () => {
                window.location.href = originalUrl;
            });
        });
    }
});
