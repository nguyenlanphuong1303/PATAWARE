document.addEventListener('DOMContentLoaded', () => {
    const shieldToggle = document.getElementById('shieldToggle');
    const parentalToggle = document.getElementById('parentalToggle');
    const blockedCountDisplay = document.getElementById('blockedCountDisplay');
    const currentTabDomain = document.getElementById('currentTabDomain');
    const currentTabScore = document.getElementById('currentTabScore');
    const tabStatusBadge = document.getElementById('tabStatusBadge');
    const btnOpenDashboard = document.getElementById('btnOpenDashboard');
    const btnReportCurrent = document.getElementById('btnReportCurrent');

    // Tải cấu hình và số lượt đã chặn
    chrome.storage.local.get(['isShieldActive', 'isParentalActive', 'blockedCount'], (res) => {
        if (shieldToggle) {
            shieldToggle.checked = res.isShieldActive !== false;
        }
        if (parentalToggle) {
            parentalToggle.checked = res.isParentalActive !== false;
        }
        if (blockedCountDisplay) {
            blockedCountDisplay.textContent = res.blockedCount || 0;
        }
    });

    // Lắng nghe thay đổi bật/tắt bảo vệ chính
    if (shieldToggle) {
        shieldToggle.addEventListener('change', (e) => {
            chrome.storage.local.set({ isShieldActive: e.target.checked });
        });
    }

    // Lắng nghe thay đổi bật/tắt chế độ Parental Control
    if (parentalToggle) {
        parentalToggle.addEventListener('change', (e) => {
            chrome.storage.local.set({ isParentalActive: e.target.checked });
        });
    }

    // Yêu cầu background kiểm tra tab hiện tại
    chrome.runtime.sendMessage({ action: 'CHECK_CURRENT_TAB' }, (res) => {
        if (!res || res.error) {
            currentTabDomain.textContent = 'Trang nội bộ trình duyệt';
            tabStatusBadge.className = 'px-2 py-0.5 rounded text-[10px] font-bold bg-slate-800 text-slate-400';
            tabStatusBadge.textContent = 'Nội bộ';
            currentTabScore.textContent = '0/100';
            return;
        }

        currentTabDomain.textContent = res.domain || res.url;
        const score = res.risk_score || 0;
        currentTabScore.textContent = `${score}/100`;

        if (score >= 70) {
            tabStatusBadge.className = 'px-2 py-0.5 rounded text-[10px] font-bold bg-rose-950 text-rose-400 border border-rose-800/60';
            if (res.category === 'GAMBLING') {
                tabStatusBadge.textContent = 'CỜ BẠC';
            } else if (res.category === 'ADULT') {
                tabStatusBadge.textContent = '18+ NGUY HIỂM';
            } else {
                tabStatusBadge.textContent = 'LỪA ĐẢO';
            }
            currentTabScore.className = 'font-extrabold text-rose-500';
        } else if (score >= 40) {
            tabStatusBadge.className = 'px-2 py-0.5 rounded text-[10px] font-bold bg-amber-950 text-amber-400 border border-amber-800/60';
            tabStatusBadge.textContent = 'CẦN CHÚ Ý';
            currentTabScore.className = 'font-extrabold text-amber-400';
        } else {
            tabStatusBadge.className = 'px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-950 text-emerald-400 border border-emerald-800/60';
            tabStatusBadge.textContent = 'AN TOÀN';
            currentTabScore.className = 'font-extrabold text-emerald-400';
        }
    });

    // Nút mở dashboard
    if (btnOpenDashboard) {
        btnOpenDashboard.addEventListener('click', () => {
            chrome.tabs.create({ url: 'http://localhost:8000' });
        });
    }

    // Nút báo cáo
    if (btnReportCurrent) {
        btnReportCurrent.addEventListener('click', () => {
            chrome.tabs.create({ url: 'http://localhost:8000/#community' });
        });
    }
});
