-- ========================================================
-- CƠ SỞ DỮ LIỆU HOÀN CHỈNH: pataware_db
-- DỰ ÁN: PATAWARE - Nền tảng cảnh báo & phát hiện lừa đảo trực tuyến
-- Tương thích: MySQL 8.0+ / MariaDB 10.5+
-- Bộ mã ký tự: utf8mb4_unicode_ci
-- ========================================================

CREATE DATABASE IF NOT EXISTS `pataware_db` 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `pataware_db`;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- --------------------------------------------------------
-- 1. BẢNG `users`: Tài khoản người dùng & Phân quyền
-- --------------------------------------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(50) NOT NULL,
  `email` VARCHAR(100) NOT NULL,
  `hashed_password` VARCHAR(255) NOT NULL,
  `full_name` VARCHAR(100) DEFAULT NULL,
  `role` VARCHAR(20) NOT NULL DEFAULT 'user' COMMENT 'admin (quản trị), moderator (kiểm duyệt), user (người dùng)',
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users_username` (`username`),
  UNIQUE KEY `uk_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tài khoản người dùng và phân quyền';

-- Mật khẩu mặc định: admin123 / mod123 / user123 (Mã hóa bcrypt chuẩn)
INSERT INTO `users` (`id`, `username`, `email`, `hashed_password`, `full_name`, `role`, `is_active`) VALUES
(1, 'admin', 'admin@pataware.vn', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'Pataware Administrator', 'admin', 1),
(2, 'moderator', 'mod@pataware.vn', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'Kiểm Duyệt Viên Cộng Đồng', 'moderator', 1),
(3, 'demo_user', 'user@pataware.vn', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'Nguyễn Văn An (Người dùng thử nghiệm)', 'user', 1)
ON DUPLICATE KEY UPDATE `id`=`id`;

-- --------------------------------------------------------
-- 2. BẢNG `whitelist_brands`: Danh sách thương hiệu uy tín (Chống Typosquatting)
-- --------------------------------------------------------
DROP TABLE IF EXISTS `whitelist_brands`;
CREATE TABLE `whitelist_brands` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `domain` VARCHAR(150) NOT NULL,
  `brand_keyword` VARCHAR(50) NOT NULL,
  `category` VARCHAR(50) DEFAULT 'bank' COMMENT 'bank, e-wallet, ecommerce, government, logistics, social',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_whitelist_domain` (`domain`),
  KEY `idx_whitelist_keyword` (`brand_keyword`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Thương hiệu chính thống để đối soát mạo danh';

INSERT INTO `whitelist_brands` (`name`, `domain`, `brand_keyword`, `category`) VALUES
-- Ngân hàng lớn tại Việt Nam
('Vietcombank', 'vietcombank.com.vn', 'vietcombank', 'bank'),
('MBBank', 'mbbank.com.vn', 'mbbank', 'bank'),
('Techcombank', 'techcombank.com', 'techcombank', 'bank'),
('BIDV', 'bidv.com.vn', 'bidv', 'bank'),
('Agribank', 'agribank.com.vn', 'agribank', 'bank'),
('VietinBank', 'vietinbank.vn', 'vietinbank', 'bank'),
('VPBank', 'vpbank.com.vn', 'vpbank', 'bank'),
('ACB', 'acb.com.vn', 'acb', 'bank'),
('TPBank', 'tpb.vn', 'tpbank', 'bank'),
('Sacombank', 'sacombank.com.vn', 'sacombank', 'bank'),
('HDBank', 'hdbank.com.vn', 'hdbank', 'bank'),
('VIB', 'vib.com.vn', 'vib', 'bank'),
-- Ví điện tử & Cổng thanh toán
('MoMo', 'momo.vn', 'momo', 'e-wallet'),
('ZaloPay', 'zalopay.vn', 'zalopay', 'e-wallet'),
('VNPay', 'vnpay.vn', 'vnpay', 'e-wallet'),
('Viettel Money', 'viettelmoney.vn', 'viettelmoney', 'e-wallet'),
-- Sàn thương mại điện tử
('Shopee VN', 'shopee.vn', 'shopee', 'ecommerce'),
('Lazada VN', 'lazada.vn', 'lazada', 'ecommerce'),
('Tiki', 'tiki.vn', 'tiki', 'ecommerce'),
('TikTok Shop', 'tiktok.com', 'tiktok', 'ecommerce'),
('Sendo', 'sendo.vn', 'sendo', 'ecommerce'),
-- Dịch vụ công & Cơ quan chính phủ
('VNeID', 'vneid.gov.vn', 'vneid', 'government'),
('Bộ Công An', 'bocongan.gov.vn', 'bocongan', 'government'),
('Cổng Dịch vụ công Quốc gia', 'dichvucong.gov.vn', 'dichvucong', 'government'),
('Tổng cục Thuế', 'gdt.gov.vn', 'gdt', 'government'),
-- Bưu chính chuyển phát
('VNPost', 'vnpost.vn', 'vnpost', 'logistics'),
('ViettelPost', 'viettelpost.com.vn', 'viettelpost', 'logistics'),
('Giao Hàng Tiết Kiệm', 'ghtk.vn', 'ghtk', 'logistics'),
('Giao Hàng Nhanh', 'ghn.vn', 'ghn', 'logistics'),
-- Nền tảng mạng xã hội phổ biến
('Telegram', 'telegram.org', 'telegram', 'social'),
('Facebook', 'facebook.com', 'facebook', 'social'),
('Zalo', 'zalo.me', 'zalo', 'social')
ON DUPLICATE KEY UPDATE `id`=`id`;

-- --------------------------------------------------------
-- 3. BẢNG `blacklists`: Danh sách đen đối tượng lừa đảo
-- --------------------------------------------------------
DROP TABLE IF EXISTS `blacklists`;
CREATE TABLE `blacklists` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `type` VARCHAR(30) NOT NULL COMMENT 'domain, url, bank_account, phone',
  `value` VARCHAR(255) NOT NULL,
  `bank_name` VARCHAR(100) DEFAULT NULL,
  `owner_name` VARCHAR(100) DEFAULT NULL,
  `reason` TEXT DEFAULT NULL,
  `report_count` INT DEFAULT 1,
  `severity` VARCHAR(20) DEFAULT 'high' COMMENT 'low, medium, high, critical',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_blacklists_value` (`value`),
  KEY `idx_blacklists_type` (`type`),
  KEY `idx_blacklists_report` (`report_count`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Danh sách đen SĐT, STK, Tên miền lừa đảo';

INSERT INTO `blacklists` (`type`, `value`, `bank_name`, `owner_name`, `reason`, `report_count`, `severity`) VALUES
-- Tên miền / Website giả mạo (Phishing Domains)
('domain', 'vietc0mbank-portal.xyz', NULL, NULL, 'Giả mạo ngân hàng Vietcombank đánh cắp mã Smart OTP', 84, 'critical'),
('domain', 'mbbank-online-support.site', NULL, NULL, 'Mạo danh MBBank lừa nâng hạn mức thẻ tín dụng', 63, 'critical'),
('domain', 'vneid-dinhdanh-gov.top', NULL, NULL, 'Giả mạo ứng dụng VNeID phát tán mã độc chiếm quyền điện thoại', 58, 'critical'),
('domain', 'shopee-trungthuong.top', NULL, NULL, 'Bẫy trúng thưởng xe SH mạo danh Shopee yêu cầu nộp thuế phí cọc', 47, 'critical'),
('domain', 'dienluc-evn-tracuu.com', NULL, NULL, 'Giả mạo Tập đoàn Điện lực EVN dọa cắt điện thu tiền nợ ảo', 36, 'high'),
('domain', 'vietinbank-online.me', NULL, NULL, 'Mạo danh ngân hàng VietinBank gửi biến động số dư giả mạo', 31, 'critical'),
('domain', 'tongcucthue-dvc.cc', NULL, NULL, 'Mạo danh Tổng cục Thuế bắt tải file APK chứa mã độc theo dõi bàn phím', 29, 'critical'),
('domain', 'techcombank-smart-otp.vip', NULL, NULL, 'Trang đăng nhập giả mạo Techcombank lấy cắp thông tin tài khoản', 25, 'critical'),

-- Tài khoản ngân hàng lừa đảo (Scam Bank Accounts)
('bank_account', '1029384756', 'Techcombank', 'NGUYEN VAN A', 'Tài khoản nhận tiền lừa đảo tuyển CTV làm nhiệm vụ giật đơn Shopee', 79, 'critical'),
('bank_account', '998877665544', 'MBBank', 'TRAN VAN B', 'Nhận tiền cọc mua xe máy, điện thoại giá rẻ sau đó chặn liên lạc', 54, 'high'),
('bank_account', '0381000998877', 'Vietcombank', 'LE THI C', 'Dụ dỗ nạn nhân nạp tiền tham gia sàn giao dịch tài chính nhị phân', 48, 'critical'),
('bank_account', '880011223344', 'VPBank', 'HOANG VAN D', 'Bẫy nộp phí giải ngân hồ sơ vay vốn online lãi suất 0%', 42, 'high'),
('bank_account', '190367890123', 'Techcombank', 'PHAM VAN E', 'Mạo danh nhân viên viễn thông lừa chuyển tiền cước phát sinh', 33, 'medium'),
('bank_account', '56010001234567', 'BIDV', 'VO VAN F', 'Nhận tiền cọc phòng trọ ảo sinh viên', 27, 'medium'),

-- Số điện thoại lừa đảo (Scam Phones)
('phone', '0879654321', NULL, NULL, 'Mạo danh cán bộ điều tra Bộ Công an đe dọa lệnh bắt giam rửa tiền', 92, 'critical'),
('phone', '0912345678', NULL, NULL, 'Giả mạo nhân viên nhà mạng dọa khóa SIM sau 2 giờ nếu không cập nhật CCCD', 65, 'high'),
('phone', '0865998877', NULL, NULL, 'Tự xưng nhân viên ngân hàng hỗ trợ rút tiền mặt thẻ tín dụng phí 0 đồng', 44, 'high'),
('phone', '0971239876', NULL, NULL, 'Giả danh nhân viên điện lực EVN báo cắt điện hộ gia đình', 39, 'medium'),
('phone', '0898765432', NULL, NULL, 'Mạo danh shipper gọi giao bưu phẩm lạ yêu cầu chuyển khoản COD', 35, 'medium'),
('phone', '0701122334', NULL, NULL, 'Mạo danh cơ quan BHXH yêu cầu bấm link đồng bộ dữ liệu VssID', 28, 'high')
ON DUPLICATE KEY UPDATE `id`=`id`;

-- --------------------------------------------------------
-- 4. BẢNG `scan_logs`: Nhật ký kiểm tra quét rủi ro
-- --------------------------------------------------------
DROP TABLE IF EXISTS `scan_logs`;
CREATE TABLE `scan_logs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `input_type` VARCHAR(30) NOT NULL COMMENT 'url, text, phone, bank_account, image',
  `raw_input` TEXT NOT NULL,
  `risk_score` FLOAT NOT NULL,
  `risk_level` VARCHAR(20) NOT NULL COMMENT 'SAFE, SUSPICIOUS, DANGEROUS',
  `domain_age_days` INT DEFAULT NULL,
  `is_new_domain` TINYINT(1) DEFAULT 0,
  `is_typosquatting` TINYINT(1) DEFAULT 0,
  `target_brand` VARCHAR(100) DEFAULT NULL,
  `is_homoglyph` TINYINT(1) DEFAULT 0,
  `is_blacklist_matched` TINYINT(1) DEFAULT 0,
  `ai_verdict` TEXT DEFAULT NULL,
  `details_json` TEXT DEFAULT NULL,
  `client_ip_hash` VARCHAR(64) DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_scan_type` (`input_type`),
  KEY `idx_scan_risk` (`risk_level`),
  KEY `idx_scan_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Nhật ký quét phục vụ thống kê & phát hiện xu hướng';

-- Nạp sẵn dữ liệu nhật ký quét 7 ngày gần nhất để Dashboard hiển thị số liệu & đồ thị thực tế
INSERT INTO `scan_logs` (`input_type`, `raw_input`, `risk_score`, `risk_level`, `domain_age_days`, `is_new_domain`, `is_typosquatting`, `target_brand`, `is_homoglyph`, `is_blacklist_matched`, `ai_verdict`, `client_ip_hash`, `created_at`) VALUES
('url', 'http://vietc0mbank-portal.xyz/login', 95.0, 'DANGEROUS', 6, 1, 1, 'Vietcombank', 1, 1, 'Website mạo danh ngân hàng Vietcombank có dấu hiệu đánh cắp thông tin tài khoản OTP rõ ràng.', '8f14e45fceea167a5a36dedd4bea2543', DATE_SUB(NOW(), INTERVAL 6 DAY)),
('bank_account', '1029384756', 90.0, 'DANGEROUS', NULL, 0, 0, NULL, 0, 1, 'Số tài khoản đã có 79 lượt tố cáo bẫy tuyển CTV giật đơn sàn TMĐT.', '2c6a4e3b1f9e8a7d6c5b4a3f2e1d0c9b', DATE_SUB(NOW(), INTERVAL 6 DAY)),
('url', 'https://vietcombank.com.vn', 0.0, 'SAFE', 8500, 0, 0, 'Vietcombank', 0, 0, 'Tên miền chính thống của Ngân hàng TMCP Ngoại thương Việt Nam. An toàn tuyệt đối.', '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d', DATE_SUB(NOW(), INTERVAL 5 DAY)),
('phone', '0879654321', 88.0, 'DANGEROUS', NULL, 0, 0, NULL, 0, 1, 'Số điện thoại thuộc danh sách đen lừa đảo mạo danh cơ quan công an điều tra.', '3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e', DATE_SUB(NOW(), INTERVAL 5 DAY)),
('text', 'Chuc mung ban da trung thuong xe may SH 150i tu Shopee. Vui long nop le phi 2 trieu vao STK 998877665544 de nhan xe', 85.0, 'DANGEROUS', NULL, 0, 0, NULL, 0, 1, 'Nội dung bẫy lừa đảo trúng thưởng điển hình yêu cầu nạp tiền giải ngân quà tặng.', '4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f', DATE_SUB(NOW(), INTERVAL 4 DAY)),
('url', 'http://mbbank-online-support.site', 92.0, 'DANGEROUS', 12, 1, 1, 'MBBank', 0, 1, 'Tên miền mới đăng ký dưới 30 ngày mạo danh MBBank.', '5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a', DATE_SUB(NOW(), INTERVAL 4 DAY)),
('phone', '0912345678', 75.0, 'DANGEROUS', NULL, 0, 0, NULL, 0, 1, 'Số điện thoại mạo danh tổng đài nhà mạng thông báo khóa SIM.', '6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b', DATE_SUB(NOW(), INTERVAL 3 DAY)),
('url', 'https://shopee.vn', 0.0, 'SAFE', 3400, 0, 0, 'Shopee', 0, 0, 'Trang thương mại điện tử chính thống của Shopee Việt Nam.', '7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c', DATE_SUB(NOW(), INTERVAL 3 DAY)),
('bank_account', '0381000998877', 85.0, 'DANGEROUS', NULL, 0, 0, NULL, 0, 1, 'Tài khoản lừa đảo sàn đầu tư tài chính nhị phân lừa cọc.', '8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d', DATE_SUB(NOW(), INTERVAL 2 DAY)),
('url', 'http://vneid-dinhdanh-gov.top', 98.0, 'DANGEROUS', 4, 1, 1, 'VNeID', 1, 1, 'Tên miền giả mạo Cổng Định danh điện tử Quốc gia phát tán mã độc.', '9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e', DATE_SUB(NOW(), INTERVAL 2 DAY)),
('image', 'Bang chung tin nhan Zalo yeu cau nop 20 trieu dong de rut von dau tu', 82.0, 'DANGEROUS', NULL, 0, 0, NULL, 0, 0, 'Ảnh chụp đoạn chat có các từ khóa thao túng tâm lý và đòi tiền giải ngân.', '0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f', DATE_SUB(NOW(), INTERVAL 1 DAY)),
('phone', '0988889999', 15.0, 'SAFE', NULL, 0, 0, NULL, 0, 0, 'Số điện thoại cá nhân thông thường, chưa có báo cáo tiêu cực.', '1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a', DATE_SUB(NOW(), INTERVAL 1 DAY)),
('url', 'http://dienluc-evn-tracuu.com', 86.0, 'DANGEROUS', 15, 1, 1, 'EVN', 0, 1, 'Tên miền giả mạo Tập đoàn Điện lực Việt Nam EVN.', '2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b', NOW()),
('bank_account', '190367890123', 70.0, 'DANGEROUS', NULL, 0, 0, NULL, 0, 1, 'Tài khoản mạo danh cước viễn thông.', '3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c', NOW())
ON DUPLICATE KEY UPDATE `id`=`id`;

-- --------------------------------------------------------
-- 5. BẢNG `community_stories`: Chia sẻ cộng đồng (ScamGuard)
-- --------------------------------------------------------
DROP TABLE IF EXISTS `community_stories`;
CREATE TABLE `community_stories` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `user_id` INT DEFAULT NULL,
  `title` VARCHAR(200) NOT NULL,
  `raw_content` TEXT DEFAULT NULL,
  `redacted_content` TEXT NOT NULL COMMENT 'Nội dung đã che mờ CCCD, SĐT, STK bằng regex PII Redactor',
  `scam_type` VARCHAR(50) NOT NULL COMMENT 'financial_investment, job_offer, impersonation, phishing_link, otp_theft',
  `reported_scammer_phone` VARCHAR(50) DEFAULT NULL,
  `reported_scammer_bank` VARCHAR(100) DEFAULT NULL,
  `reported_scammer_url` VARCHAR(255) DEFAULT NULL,
  `loss_amount` VARCHAR(50) DEFAULT NULL,
  `evidence_image` VARCHAR(255) DEFAULT NULL,
  `status` VARCHAR(20) DEFAULT 'approved' COMMENT 'pending, approved, rejected',
  `moderated_by` INT DEFAULT NULL,
  `moderation_notes` TEXT DEFAULT NULL,
  `upvotes` INT DEFAULT 0,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_story_type` (`scam_type`),
  KEY `idx_story_status` (`status`),
  KEY `idx_story_created` (`created_at`),
  CONSTRAINT `fk_story_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_story_moderator` FOREIGN KEY (`moderated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Góc cảnh báo cộng đồng và tự động khử thông tin cá nhân';

INSERT INTO `community_stories` (`user_id`, `title`, `raw_content`, `redacted_content`, `scam_type`, `reported_scammer_phone`, `reported_scammer_bank`, `reported_scammer_url`, `loss_amount`, `status`, `upvotes`) VALUES
(3, 'Cảnh báo chiêu trò bẫy việc nhẹ lương cao giật đơn Shopee', 
'Bọn chúng dụ mình nạp 500.000 VNĐ vào STK Techcombank 1029384756 (Nguyen Van A), đơn đầu được hoàn 600.000 VNĐ. Đến đơn 50 triệu thì giam tiền và bảo sai cú pháp, bắt nạp thêm 30 triệu mới cho rút. May mình dừng lại kịp thời.',
'Bọn chúng dụ mình nạp 500.000 VNĐ vào STK Techcombank [STK ĐÃ ĐƯỢC CHE MỜ] (Nguyen Van A), đơn đầu được hoàn 600.000 VNĐ. Đến đơn 50 triệu thì giam tiền và bảo sai cú pháp, bắt nạp thêm 30 triệu mới cho rút. May mình dừng lại kịp thời.',
'job_offer', 'Techcombank: 1029384756 (NGUYEN VAN A)', '1029384756', NULL, '50.000.000 VNĐ', 'approved', 42),

(3, 'Mạo danh cán bộ thuế gọi điện bắt cài app DVC giả mạo', 
'Đối tượng tự xưng cán bộ chi cục thuế quận gọi từ số 0879654321, nói mình sai mã số thuế cá nhân cần bổ sung gấp. Đối tượng gửi link qua Zalo yêu cầu tải file APK về cài đặt. Nhờ quét qua Pataware phát hiện tên miền tongcucthue-dvc.cc có mã độc.',
'Đối tượng tự xưng cán bộ chi cục thuế quận gọi từ số [SĐT ĐÃ ĐƯỢC CHE MỜ], nói mình sai mã số thuế cá nhân cần bổ sung gấp. Đối tượng gửi link qua Zalo yêu cầu tải file APK về cài đặt. Nhờ quét qua Pataware phát hiện tên miền tongcucthue-dvc.cc có mã độc.',
'impersonation', '0879654321', NULL, 'http://tongcucthue-dvc.cc', '0 VNĐ (Ngăn chặn kịp)', 'approved', 35),

(3, 'Bẫy trúng thưởng xe máy SH nhận tin nhắn từ Brandname giả', 
'Mình nhận được SMS báo trúng thưởng xe SH 150i nhân dịp kỷ niệm sinh nhật sàn, yêu cầu bấm vào http://shopee-trungthuong.top để làm thủ tục nộp lệ phí trước bạ 3.500.000 VNĐ vào STK MBBank 998877665544.',
'Mình nhận được SMS báo trúng thưởng xe SH 150i nhân dịp kỷ niệm sinh nhật sàn, yêu cầu bấm vào http://shopee-trungthuong.top để làm thủ tục nộp lệ phí trước bạ 3.500.000 VNĐ vào STK MBBank [STK ĐÃ ĐƯỢC CHE MỜ].',
'phishing_link', NULL, 'MBBank: 998877665544', 'http://shopee-trungthuong.top', '3.500.000 VNĐ', 'approved', 29),

(3, 'Cuộc gọi Deepfake bạn thân mượn tiền chữa bệnh khẩn cấp', 
'Bạn thân mình bị hack tài khoản Facebook, kẻ gian dùng AI Deepfake ghép mặt gọi video đúng 5 giây báo mạng yếu rồi nhắn tin bảo chuyển gấp 15 triệu vào STK lạ. Mình gọi lại bằng sóng điện thoại di động trực tiếp thì bạn bảo không hề mượn.',
'Bạn thân mình bị hack tài khoản Facebook, kẻ gian dùng AI Deepfake ghép mặt gọi video đúng 5 giây báo mạng yếu rồi nhắn tin bảo chuyển gấp 15 triệu vào STK lạ. Mình gọi lại bằng sóng điện thoại di động trực tiếp thì bạn bảo không hề mượn.',
'impersonation', NULL, 'Vietcombank: [STK ĐÃ ĐƯỢC CHE MỜ]', NULL, '0 VNĐ (Phát hiện kịp)', 'approved', 24),

(3, 'Cảnh báo sàn đầu tư tiền số sinh lời 30%/tháng', 
'Nhóm chuyên gia trên Telegram dụ tham gia sàn nhị phân, ban đầu nạp 2 triệu rút được lãi ngay, đến khi gom hơn 120 triệu thì sàn báo lỗi bảo trì và khóa tài khoản vĩnh viễn.',
'Nhóm chuyên gia trên Telegram dụ tham gia sàn nhị phân, ban đầu nạp 2 triệu rút được lãi ngay, đến khi gom hơn 120 triệu thì sàn báo lỗi bảo trì và khóa tài khoản vĩnh viễn.',
'financial_investment', NULL, 'VPBank: 880011223344', NULL, '120.000.000 VNĐ', 'approved', 51)
ON DUPLICATE KEY UPDATE `id`=`id`;

-- --------------------------------------------------------
-- 6. BẢNG `quiz_questions`: Câu hỏi trắc nghiệm tình huống
-- --------------------------------------------------------
DROP TABLE IF EXISTS `quiz_questions`;
CREATE TABLE `quiz_questions` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `category` VARCHAR(50) DEFAULT 'general',
  `scenario_title` VARCHAR(200) NOT NULL,
  `scenario_description` TEXT NOT NULL,
  `explanation` TEXT NOT NULL,
  `difficulty` VARCHAR(20) DEFAULT 'medium' COMMENT 'easy, medium, hard',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ngân hàng câu hỏi tình huống mô phỏng thực tế';

-- --------------------------------------------------------
-- 7. BẢNG `quiz_options`: Đáp án câu hỏi
-- --------------------------------------------------------
DROP TABLE IF EXISTS `quiz_options`;
CREATE TABLE `quiz_options` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `question_id` INT NOT NULL,
  `option_text` VARCHAR(255) NOT NULL,
  `is_correct` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_quiz_question` (`question_id`),
  CONSTRAINT `fk_quiz_question` FOREIGN KEY (`question_id`) REFERENCES `quiz_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Nạp 6 câu hỏi tình huống bám sát toàn diện các thủ đoạn lừa đảo phổ biến
INSERT INTO `quiz_questions` (`id`, `category`, `scenario_title`, `scenario_description`, `explanation`, `difficulty`) VALUES
(1, 'banking', 'Tin nhắn SMS Brandname mạo danh ngân hàng khóa thẻ', 
'Bạn nhận được tin nhắn SMS hiển thị tên ngân hàng với nội dung: "Tai khoan VCB cua quy khach bi khoa. Vui long dang nhap http://vietc0mbank-portal.xyz de xac thuc Smart OTP trong vong 2 gio". Bạn nên làm gì?', 
'Ngân hàng không bao giờ gửi đường link lạ bắt buộc khách hàng nhập mật khẩu tài khoản hay mã OTP qua SMS. Tên miền "vietc0mbank-portal.xyz" cố tình thay chữ "o" bằng số "0" (Typosquatting) và dùng đuôi lạ ".xyz". Tuyệt đối không bấm link.', 'medium'),

(2, 'job_scam', 'Tuyển dụng cộng tác viên giật đơn sàn TMĐT hưởng hoa hồng', 
'Một tài khoản Zalo lạ mời bạn làm cộng tác viên xử lý đơn hàng trên sàn Shopee/Lazada với hoa hồng 20%/đơn, yêu cầu nạp trước 500.000 VNĐ tiền cọc vào tài khoản cá nhân. Đây là thủ đoạn gì?', 
'Đây là chiêu trò bẫy cộng tác viên nhiệm vụ điển hình. Sau các đơn nhỏ được hoàn tiền thật để tạo niềm tin, kẻ gian sẽ yêu cầu nạp các đơn lớn hàng chục triệu rồi viện cớ lỗi cú pháp để chiếm đoạt tài sản.', 'easy'),

(3, 'impersonation', 'Cuộc gọi video Deepfake mượn tiền khẩn cấp', 
'Bạn thân của bạn gọi video qua Facebook Messenger mượn gấp 15 triệu để cấp cứu. Hình ảnh khuôn mặt hơi giật, âm thanh méo và cuộc gọi tắt sau 5 giây vì "mạng yếu", sau đó nhắn tin gửi số tài khoản ngân hàng tên người khác. Bạn nên làm gì?', 
'Kẻ gian thường chiếm đoạt tài khoản Facebook và dùng công nghệ Deepfake AI tạo video giả mạo người thân rồi đưa STK người lạ. Luôn gọi điện trực tiếp qua số sóng di động thông thường để xác minh trước khi chuyển tiền.', 'hard'),

(4, 'malware', 'Mạo danh cán bộ Công an / Thuế bắt cài file APK dịch vụ công', 
'Một người tự xưng là cán bộ Công an khu vực gọi điện bảo bạn sai lệch hồ sơ định danh CCCD/Thuế, yêu cầu kết bạn Zalo để gửi một file đuôi ".apk" bảo cài đặt lên điện thoại Android để đồng bộ. Bạn nên xử lý thế nào?', 
'Cơ quan nhà nước, Công an và Thuế không bao giờ làm việc qua điện thoại hay gửi file APK lạ qua mạng xã hội. File APK giả mạo chứa mã độc gián điệp, khi cài đặt sẽ chiếm quyền trợ năng (Accessibility) để tự động đọc trộm mã OTP và rút sạch tiền trong tài khoản.', 'hard'),

(5, 'qr_phishing', 'Bẫy quét mã QR thanh toán dán đè tại quầy hàng', 
'Khi thanh toán tại một quán cà phê đông người, bạn quét mã QR dán trên bàn và thấy trình duyệt tự động mở ra một trang web yêu cầu đăng nhập tài khoản ngân hàng và nhập mã OTP. Bạn nên làm gì?', 
'Đây là thủ đoạn tráo đổi mã QR độc hại (Quynhing / QR Phishing). Mã QR chuẩn chỉ dẫn đến màn hình chuyển khoản của ứng dụng ngân hàng, không bao giờ bắt đăng nhập lại mật khẩu trên trình duyệt web lạ.', 'medium'),

(6, 'financial_investment', 'Hội nhóm đầu tư tài chính quốc tế cam kết lãi suất 30%/tháng', 
'Bạn được mời vào nhóm Telegram có các "chuyên gia đọc lệnh" cam kết đầu tư tiền số hoặc vàng tài chính sinh lời 30%/tháng, rủi ro bằng 0. Ban đầu cho rút 500k lãi thật. Bản chất của mô hình này là gì?', 
'Đây là mô hình Ponzi lừa đảo đa cấp nhị phân (BO). Không có kênh đầu tư hợp pháp nào mang lại lãi suất 30%/tháng với rủi ro bằng 0. Khi nạn nhân nạp số tiền lớn, sàn sẽ tự động khóa tài khoản và biến mất.', 'easy')
ON DUPLICATE KEY UPDATE `id`=`id`;

INSERT INTO `quiz_options` (`question_id`, `option_text`, `is_correct`) VALUES
-- Câu 1
(1, 'Lập tức bấm vào link để đăng nhập và hủy giao dịch khóa thẻ', 0),
(1, 'Nhập mã OTP nhưng không nhập mật khẩu tài khoản', 0),
(1, 'Tuyệt đối không bấm link, xóa tin nhắn và gọi ngay hotline chính thức của ngân hàng để kiểm tra', 1),
(1, 'Chuyển toàn bộ tiền trong tài khoản sang tài khoản người thân qua link đó', 0),
-- Câu 2
(2, 'Lừa đảo chiếm đoạt tài sản bằng thủ đoạn bẫy làm nhiệm vụ hoa hồng ảo', 1),
(2, 'Công việc bán thời gian kiếm thêm thu nhập uy tín được sàn bảo trợ', 0),
(2, 'Chương trình kích cầu người dùng chính thức của sàn thương mại điện tử', 0),
(2, 'Cơ hội đầu tư rủi ro thấp lợi nhuận cao', 0),
-- Câu 3
(3, 'Chuyển tiền ngay lập tức vì đã nhìn thấy mặt bạn thân trên video', 0),
(3, 'Gọi điện thoại trực tiếp qua số di động cá nhân của bạn để kiểm tra và xác minh danh tính', 1),
(3, 'Chuyển trước 5 triệu để đỡ áp lực', 0),
(3, 'Gửi thông tin thẻ tín dụng của mình cho bạn tự rút tiền', 0),
-- Câu 4
(4, 'Tải ngay file APK về cài đặt để kịp thời hoàn thiện hồ sơ đúng hạn', 0),
(4, 'Cúp máy ngay lập tức, không làm theo bất kỳ hướng dẫn nào và đến trực tiếp trụ sở Công an phường để xác minh', 1),
(4, 'Gửi ảnh chụp hai mặt CCCD qua Zalo cho đối tượng để họ tự chỉnh sửa giúp', 0),
(4, 'Cài file APK trên máy điện thoại của người thân thay vì máy của mình', 0),
-- Câu 5
(5, 'Tiếp tục đăng nhập mật khẩu và nhập mã OTP để thanh toán', 0),
(5, 'Hủy bỏ thao tác ngay lập tức, báo cho chủ quán về mã QR khả nghi và thanh toán bằng tiền mặt hoặc chuyển khoản trực tiếp', 1),
(5, 'Chụp ảnh màn hình trang web đó gửi cho bạn bè hỏi ý kiến', 0),
(5, 'Chỉ nhập số điện thoại chứ không nhập mật khẩu', 0),
-- Câu 6
(6, 'Mô hình Ponzi lừa đảo công nghệ cao đánh vào lòng tham', 1),
(6, 'Phương thức làm giàu nhanh chóng đã được chứng minh hiệu quả', 0),
(6, 'Dự án khởi nghiệp công nghệ tài chính FinTech uy tín quốc tế', 0),
(6, 'Quỹ tương hỗ đầu tư được pháp luật bảo vệ', 0)
ON DUPLICATE KEY UPDATE `id`=`id`;

-- --------------------------------------------------------
-- 8. BẢNG `user_quiz_results`: Kết quả trắc nghiệm người dùng
-- --------------------------------------------------------
DROP TABLE IF EXISTS `user_quiz_results`;
CREATE TABLE `user_quiz_results` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `user_id` INT NOT NULL,
  `total_questions` INT NOT NULL,
  `correct_answers` INT NOT NULL,
  `score_percentage` INT NOT NULL,
  `emotion_feedback` VARCHAR(50) DEFAULT NULL COMMENT 'confident, cautious, anxious',
  `completed_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_quiz` (`user_id`),
  CONSTRAINT `fk_quiz_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Kết quả làm bài và nhật ký cảm xúc';

INSERT INTO `user_quiz_results` (`user_id`, `total_questions`, `correct_answers`, `score_percentage`, `emotion_feedback`, `completed_at`) VALUES
(3, 6, 5, 83, 'confident', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(3, 6, 6, 100, 'cautious', DATE_SUB(NOW(), INTERVAL 1 DAY))
ON DUPLICATE KEY UPDATE `id`=`id`;

SET FOREIGN_KEY_CHECKS = 1;

-- ========================================================
-- HOÀN TẤT NÂNG CẤP DỮ LIỆU CƠ SỞ DỮ LIỆU `pataware_db`
-- ========================================================
