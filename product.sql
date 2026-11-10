-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               8.4.3 - MySQL Community Server - GPL
-- Server OS:                    Win64
-- HeidiSQL Version:             12.8.0.6908
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

drop DATABASE IF EXISTS `handmade_shop`;
-- Dumping database structure for handmade_shop
CREATE DATABASE IF NOT EXISTS `handmade_shop` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `handmade_shop`;

-- Dumping structure for table handmade_shop.addresses
CREATE TABLE IF NOT EXISTS `addresses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `district` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `ward` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `address_line` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `address_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'Nhà Riêng',
  `is_default` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `addresses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.addresses: ~4 rows (approximately)
INSERT INTO `addresses` (`id`, `user_id`, `name`, `phone`, `email`, `city`, `district`, `ward`, `address_line`, `address_type`, `is_default`, `created_at`) VALUES
	(1, 3, 'Chu Hoàng Khánh Hân', '0964325348', '', 'Thành phố Hồ Chí Minh', 'Thành phố Thủ Đức', 'Phường Tăng Nhơn Phú B', '34 Tân lập 1', 'Nhà Riêng', 0, '2026-04-15 04:19:12'),
	(2, 3, 'Khánh Hân', '0964325348', '', 'Tỉnh Lâm Đồng', 'Thành phố Bảo Lộc', 'Phường Lộc Tiến', '60/49 Phan Chu Trinh', 'Nhà Riêng', 0, '2026-04-15 09:49:18'),
	(4, 5, 'Nguyễn Lan Phương', '0382613031', '', 'Thành phố Hồ Chí Minh', 'Huyện Củ Chi', 'Xã Phước Thạnh', '60/6, Trương Thị Khét', 'Nhà Riêng', 1, '2026-04-21 02:53:12'),
	(6, 18, 'ádgssgd', '0123456789', '', 'Thành phố Hà Nội', 'Quận Ba Đình', 'Phường Phúc Xá', '456456', '', 0, '2026-05-23 05:25:41');

-- Dumping structure for table handmade_shop.admin_revenue
CREATE TABLE IF NOT EXISTS `admin_revenue` (
  `id` int NOT NULL AUTO_INCREMENT,
  `transaction_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Mã giao dịch duy nhất',
  `order_id` int NOT NULL COMMENT 'FK → orders.id',
  `order_detail_id` int NOT NULL COMMENT 'FK → order_detail.id',
  `seller_id` int NOT NULL COMMENT 'FK → user.id (seller)',
  `gross_amount` decimal(12,2) NOT NULL COMMENT 'Tổng giá trị mặt hàng (đơn giá * số lượng)',
  `commission_percent` decimal(5,2) NOT NULL DEFAULT '10.00' COMMENT 'Tỷ lệ hoa hồng',
  `admin_fee` decimal(12,2) NOT NULL COMMENT 'Số tiền admin nhận (10%)',
  `seller_receive` decimal(12,2) NOT NULL COMMENT 'Số tiền seller nhận (90%)',
  `status` enum('pending','settled','refunded') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'settled',
  `note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_rev_txn_code` (`transaction_code`),
  KEY `idx_rev_order` (`order_id`),
  KEY `idx_rev_order_detail` (`order_detail_id`),
  KEY `idx_rev_seller` (`seller_id`),
  KEY `idx_rev_created` (`created_at`),
  CONSTRAINT `fk_rev_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`),
  CONSTRAINT `fk_rev_order_detail` FOREIGN KEY (`order_detail_id`) REFERENCES `order_detail` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rev_seller` FOREIGN KEY (`seller_id`) REFERENCES `user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Doanh thu hoa hồng của admin từ mỗi mặt hàng hoàn thành';

-- Dumping data for table handmade_shop.admin_revenue: ~7 rows (approximately)
INSERT INTO `admin_revenue` (`id`, `transaction_code`, `order_id`, `order_detail_id`, `seller_id`, `gross_amount`, `commission_percent`, `admin_fee`, `seller_receive`, `status`, `note`, `created_at`) VALUES
	(1, 'REV-20260518-80908-40', 35, 40, 18, 55555.00, 10.00, 5555.50, 49999.50, 'settled', 'Phí hoa hồng 10% từ sản phẩm #47 (đơn hàng #35)', '2026-05-18 11:07:51'),
	(2, 'REV-20260520-71529-42', 37, 42, 11, 30000.00, 10.00, 3000.00, 27000.00, 'settled', 'Phí hoa hồng 10% từ sản phẩm #50 (đơn hàng #37)', '2026-05-20 17:08:23'),
	(3, 'REV-20260523-97890-43', 38, 43, 5, 375000.00, 10.00, 37500.00, 337500.00, 'settled', 'Phí hoa hồng 10% từ sản phẩm #27 (đơn hàng #38)', '2026-05-23 12:42:10'),
	(4, 'REV-20260523-10317-32', 29, 32, 5, 29100.00, 10.00, 2910.00, 26190.00, 'settled', 'Phí hoa hồng 10% từ sản phẩm #39 (đơn hàng #29)', '2026-05-23 12:43:40'),
	(5, 'REV-20260523-77206-44', 39, 44, 5, 75000.00, 10.00, 7500.00, 67500.00, 'settled', 'Phí hoa hồng 10% từ sản phẩm #27 (đơn hàng #39)', '2026-05-23 12:43:46'),
	(6, 'REV-20260523-26893-45', 40, 45, 11, 118000.00, 10.00, 11800.00, 106200.00, 'settled', 'Phí hoa hồng 10% từ sản phẩm #50 (đơn hàng #40)', '2026-05-23 13:17:05'),
	(7, 'REV-20260523-98968-46', 40, 46, 18, 90000.00, 10.00, 9000.00, 81000.00, 'settled', 'Phí hoa hồng 10% từ sản phẩm #53 (đơn hàng #40)', '2026-05-23 13:17:05');

-- Dumping structure for table handmade_shop.banners
CREATE TABLE IF NOT EXISTS `banners` (
  `id` int NOT NULL AUTO_INCREMENT,
  `image` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `section` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'hero',
  `qr_image` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `qr_position` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'bottom-center',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.banners: ~3 rows (approximately)
INSERT INTO `banners` (`id`, `image`, `created_at`, `section`, `qr_image`, `qr_position`) VALUES
	(29, '1778156115_-1.png', '2026-05-07 12:15:15', 'hero', 'qr_1778156907_z7801340884693_19028e4dd8f73f6daf1290e2d803e720.jpg', 'bottom-center'),
	(30, '1778156115_-2.png', '2026-05-07 12:15:16', 'hero', NULL, 'bottom-center'),
	(31, '1778156116_-3.png', '2026-05-07 12:15:16', 'hero', NULL, 'bottom-center');

-- Dumping structure for table handmade_shop.cart_items
CREATE TABLE IF NOT EXISTS `cart_items` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `product_id` int NOT NULL,
  `variant_id` int DEFAULT '0',
  `quantity` int NOT NULL DEFAULT '1',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_product_variant` (`user_id`,`product_id`,`variant_id`)
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.cart_items: ~8 rows (approximately)
INSERT INTO `cart_items` (`id`, `user_id`, `product_id`, `variant_id`, `quantity`, `updated_at`) VALUES
	(3, 12, 22, 0, 1, '2026-04-17 11:55:33'),
	(5, 13, 5, 0, 1, '2026-04-17 12:21:08'),
	(41, 19, 5, 1, 1, '2026-05-13 06:14:26'),
	(44, 22, 27, 0, 1, '2026-05-18 01:30:38'),
	(56, 3, 40, 0, 1, '2026-05-31 07:42:47'),
	(57, 3, 7, 3, 3, '2026-05-31 08:43:19'),
	(58, 3, 11, 3, 3, '2026-05-31 08:45:51'),
	(59, 3, 10, 11, 3, '2026-05-31 08:46:45');

-- Dumping structure for table handmade_shop.category
CREATE TABLE IF NOT EXISTS `category` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `parent_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `parent_id` (`parent_id`),
  CONSTRAINT `category_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `category` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.category: ~14 rows (approximately)
INSERT INTO `category` (`id`, `name`, `description`, `parent_id`) VALUES
	(1, 'Kim móc các loại', 'Kim móc nhiều kích thước', NULL),
	(3, 'Phụ kiện hỗ trợ đan móc len', 'Kéo, thước, đánh dấu mũi', NULL),
	(4, 'Búp bê len', 'Búp bê thủ công', NULL),
	(5, 'Thú bông len', 'Gấu bông len', NULL),
	(6, 'Túi len', 'Túi vải, túi len', NULL),
	(7, 'Nón, khăn len', 'Nón thời trang', NULL),
	(8, 'Đồ gia dụng', 'Đồ dùng handmade', NULL),
	(9, 'Hoa lẻ ', 'Hoa đơn ', NULL),
	(10, 'Hoa bó', 'Hoa bó ', NULL),
	(11, 'Hoa mix ngẫu nhiên', 'Hoa mix', NULL),
	(12, 'Sợi tự nhiên', 'natural', NULL),
	(13, 'Sợi tổng hợp ', 'Synthetic fibre', NULL),
	(14, 'Sợi chuyên móc thú bông', 'Sợi móc thú bông', NULL),
	(15, 'Móc khóa', '', NULL),
	(16, 'Trang Sức Handmade', 'Vòng tay, khuyên tai đính đá thủ công tinh xảo', NULL);

-- Dumping structure for table handmade_shop.chat_messages
CREATE TABLE IF NOT EXISTS `chat_messages` (
  `id` int NOT NULL AUTO_INCREMENT,
  `conversation_id` int NOT NULL,
  `sender_id` int NOT NULL,
  `message_type` enum('text','image','video','sticker','product','order') COLLATE utf8mb4_unicode_ci DEFAULT 'text',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `attachment_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=162 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.chat_messages: ~117 rows (approximately)
INSERT INTO `chat_messages` (`id`, `conversation_id`, `sender_id`, `message_type`, `content`, `attachment_url`, `is_read`, `created_at`) VALUES
	(1, 1, 3, 'text', 'e', NULL, 1, '2026-04-30 10:01:47'),
	(2, 1, 3, 'text', 'r', NULL, 1, '2026-04-30 10:01:52'),
	(3, 1, 3, 'text', 'alo alo alo', NULL, 1, '2026-04-30 10:02:00'),
	(27, 1, 3, 'text', '[P]:{"id":"43","name":"Len Milk Cotton 2mm 50g","price":"15.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ceaba30_1777539278.jpg"}', NULL, 1, '2026-05-01 04:05:03'),
	(28, 4, 3, 'order', '{"id":"30","status_label":"confirmed","name":"Len sợi Acrylic Paintbox Yarns Simply DK","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f30741ba86a_1777534785.jpg","total":"59.100 đ","date":"30/04/2026 15:50","quantity":"1"}', NULL, 1, '2026-05-01 04:24:21'),
	(29, 4, 3, 'product', '{"id":"43","name":"Len Milk Cotton 2mm 50g","price":"15.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ceaba30_1777539278.jpg"}', NULL, 1, '2026-05-01 04:28:04'),
	(30, 4, 3, 'product', '{"id":"43","name":"Len Milk Cotton 2mm 50g","price":"15.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ceaba30_1777539278.jpg"}', NULL, 1, '2026-05-01 04:28:09'),
	(31, 4, 3, 'product', '{"id":"43","name":"Len Milk Cotton 2mm 50g","price":"15.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ceaba30_1777539278.jpg"}', NULL, 1, '2026-05-01 04:30:03'),
	(32, 4, 3, 'product', '{"id":"43","name":"Len Milk Cotton 2mm 50g","price":"15.000₫","old_price":"","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ceaba30_1777539278.jpg"}', NULL, 1, '2026-05-01 04:55:05'),
	(33, 5, 16, 'product', '{"id":"43","name":"Len Milk Cotton 2mm 50g","price":"15.000₫","old_price":"","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ceaba30_1777539278.jpg"}', NULL, 1, '2026-05-01 05:03:20'),
	(34, 5, 16, 'product', '{"id":"43","name":"Len Milk Cotton 2mm 50g","price":"15.000₫","old_price":"","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ceaba30_1777539278.jpg"}', NULL, 1, '2026-05-01 05:06:39'),
	(35, 5, 16, 'product', '{"id":"42","name":"len sợi pha","price":"24.250₫","old_price":"25.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ae6d5da_1777539246.jpg"}', NULL, 1, '2026-05-01 05:07:21'),
	(36, 5, 3, 'product', '{"id":"42","name":"len sợi pha","price":"24.250₫","old_price":"25.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ae6d5da_1777539246.jpg"}', NULL, 1, '2026-05-01 05:20:33'),
	(37, 5, 3, 'product', '{"id":"42","name":"len sợi pha","price":"24.250₫","old_price":"25.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ae6d5da_1777539246.jpg"}', NULL, 1, '2026-05-01 05:20:37'),
	(38, 5, 3, 'product', '{"id":"41","name":"Sợi Ni lông 70D - Salud Style","price":"56.400₫","old_price":"60.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318905070f_1777539216.jpg"}', NULL, 1, '2026-05-01 05:47:43'),
	(39, 4, 6, 'product', '{"id":"41","name":"Sợi Ni lông 70D - Salud Style","price":"56.400₫","old_price":"60.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318905070f_1777539216.jpg"}', NULL, 1, '2026-05-01 05:48:59'),
	(40, 4, 6, 'text', 'e', NULL, 1, '2026-05-01 05:49:04'),
	(41, 4, 3, 'text', 'sao', NULL, 1, '2026-05-01 05:50:38'),
	(42, 4, 3, 'product', '{"id":"41","name":"Sợi Ni lông 70D - Salud Style","price":"56.400₫","old_price":"60.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318905070f_1777539216.jpg"}', NULL, 1, '2026-05-01 05:50:54'),
	(43, 4, 3, 'text', 'sao', NULL, 1, '2026-05-01 05:53:56'),
	(44, 5, 16, 'product', '{"id":"42","name":"len sợi pha","price":"24.250₫","old_price":"25.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ae6d5da_1777539246.jpg"}', NULL, 1, '2026-05-01 06:00:47'),
	(45, 5, 3, 'product', '{"id":"41","name":"Sợi Ni lông 70D - Salud Style","price":"56.400₫","old_price":"60.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318905070f_1777539216.jpg"}', NULL, 1, '2026-05-01 06:06:06'),
	(46, 5, 3, 'text', 'e', NULL, 1, '2026-05-01 06:06:10'),
	(47, 5, 3, 'product', '{"id":"41","name":"Sợi Ni lông 70D - Salud Style","price":"56.400₫","old_price":"60.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318905070f_1777539216.jpg"}', NULL, 1, '2026-05-01 06:08:51'),
	(48, 5, 3, 'order', '{"id":"30","status_label":"confirmed","name":"Len sợi Acrylic Paintbox Yarns Simply DK","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f30741ba86a_1777534785.jpg","total":"59.100 đ","date":"30/04/2026 15:50","quantity":"1"}', NULL, 1, '2026-05-01 06:08:58'),
	(49, 5, 3, 'product', '{"id":"41","name":"Sợi Ni lông 70D - Salud Style","price":"56.400₫","old_price":"60.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318905070f_1777539216.jpg"}', NULL, 1, '2026-05-01 06:11:13'),
	(50, 5, 3, 'text', 'e', NULL, 1, '2026-05-01 06:13:21'),
	(51, 5, 3, 'text', 'ee e eaksfkasjfh aksfjha ksjfhaskjfh askjfha ksjf', NULL, 1, '2026-05-01 06:13:26'),
	(52, 5, 3, 'order', '{"id":"28","status_label":"Đã hoàn thành","name":"Len sợi Acrylic Paintbox Yarns Simply DK","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f30741ba86a_1777534785.jpg","total":"59.100 đ","date":"30/04/2026 14:42","quantity":"1"}', NULL, 1, '2026-05-01 06:13:57'),
	(53, 6, 17, 'order', '{"id":"31","status_label":"confirmed","name":"Thú bông len hình thỏ","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/d07933460b5dedc29a720c19381eaf76.jpg","total":"310.000 đ","date":"01/05/2026 13:30","quantity":"1"}', NULL, 1, '2026-05-01 06:31:26'),
	(54, 6, 3, 'order', '{"id":"30","status_label":"confirmed","name":"Len sợi Acrylic Paintbox Yarns Simply DK","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f30741ba86a_1777534785.jpg","total":"59.100 đ","date":"30/04/2026 15:50","quantity":"1"}', NULL, 1, '2026-05-01 06:42:46'),
	(55, 6, 3, 'product', '{"id":"43","name":"Len Milk Cotton 2mm 50g","price":"15.000₫","old_price":"","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ceaba30_1777539278.jpg"}', NULL, 1, '2026-05-01 06:42:59'),
	(56, 6, 3, 'order', '{"id":"30","status_label":"confirmed","name":"Len sợi Acrylic Paintbox Yarns Simply DK","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f30741ba86a_1777534785.jpg","total":"59.100 đ","date":"30/04/2026 15:50","quantity":"1"}', NULL, 1, '2026-05-01 06:43:03'),
	(57, 6, 3, 'order', '{"id":"17","status_label":"Chờ xác nhận","name":"Móc khóa thú len handmade","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/vn-11134207-820l4-mhs7hbm2vwg209.png","total":"130.000 đ","date":"17/04/2026 21:34","quantity":"1"}', NULL, 1, '2026-05-01 06:45:23'),
	(58, 6, 3, 'product', '{"id":"39","name":"Len sợi Acrylic Paintbox Yarns Simply DK","price":"29.100₫","old_price":"","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f30741ba86a_1777534785.jpg"}', NULL, 1, '2026-05-01 06:45:41'),
	(59, 6, 3, 'order', '{"id":"30","status_label":"confirmed","name":"Len sợi Acrylic Paintbox Yarns Simply DK","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f30741ba86a_1777534785.jpg","total":"59.100 đ","date":"30/04/2026 15:50","quantity":"1"}', NULL, 1, '2026-05-01 06:55:49'),
	(60, 6, 3, 'product', '{"id":"39","name":"Len sợi Acrylic Paintbox Yarns Simply DK","price":"29.100₫","old_price":"","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f30741ba86a_1777534785.jpg"}', NULL, 1, '2026-05-01 07:06:15'),
	(61, 6, 3, 'order', '{"id":"30","status_label":"confirmed","name":"Len sợi Acrylic Paintbox Yarns Simply DK","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f30741ba86a_1777534785.jpg","total":"59.100 đ","date":"30/04/2026 15:50","quantity":"1"}', NULL, 1, '2026-05-01 07:06:51'),
	(62, 1, 5, 'text', 'hif', NULL, 1, '2026-05-06 15:45:41'),
	(63, 1, 5, 'text', 'cái này riêng bạn mình không bán ạ', NULL, 1, '2026-05-06 15:45:58'),
	(64, 1, 5, 'image', '', 'public/uploads/chat/chat_1778145587_69fc5933b92d7.png', 1, '2026-05-07 09:19:47'),
	(65, 1, 5, 'text', 'hì', NULL, 1, '2026-05-07 09:21:22'),
	(66, 8, 7, 'text', 'e', NULL, 1, '2026-05-12 04:48:17'),
	(67, 8, 7, 'text', 'ưerfasfasf', NULL, 1, '2026-05-12 04:48:22'),
	(68, 8, 3, 'text', 'gì', NULL, 1, '2026-05-12 04:58:16'),
	(69, 1, 3, 'text', 'ágfasfg', NULL, 1, '2026-05-12 04:58:27'),
	(70, 8, 3, 'text', 'asfasfasfdas\\', NULL, 1, '2026-05-12 04:59:00'),
	(71, 8, 7, 'text', 'ádasd', NULL, 1, '2026-05-12 05:00:51'),
	(72, 6, 3, 'text', 'ád', NULL, 1, '2026-05-12 05:02:31'),
	(73, 8, 7, 'text', 'ok', NULL, 1, '2026-05-12 05:02:47'),
	(74, 8, 3, 'text', 'gì', NULL, 1, '2026-05-12 05:06:00'),
	(75, 8, 3, 'text', 'ádf', NULL, 1, '2026-05-12 05:06:04'),
	(76, 8, 3, 'text', 'ầ', NULL, 1, '2026-05-12 05:06:14'),
	(77, 8, 3, 'text', 'àd', NULL, 1, '2026-05-12 05:06:14'),
	(78, 8, 3, 'text', 'àd', NULL, 1, '2026-05-12 05:06:14'),
	(79, 8, 3, 'text', 'ád', NULL, 1, '2026-05-12 05:06:14'),
	(80, 8, 3, 'text', 'ád', NULL, 1, '2026-05-12 05:06:15'),
	(81, 8, 3, 'text', 'ád', NULL, 1, '2026-05-12 05:06:15'),
	(82, 8, 3, 'text', 'ád', NULL, 1, '2026-05-12 05:06:15'),
	(83, 8, 3, 'text', 'ád', NULL, 1, '2026-05-12 05:06:22'),
	(84, 8, 3, 'text', 'e', NULL, 1, '2026-05-12 05:07:07'),
	(85, 8, 7, 'text', 'asdasdawrq;kqjnwr', NULL, 1, '2026-05-12 05:07:29'),
	(86, 8, 7, 'text', 'e', NULL, 1, '2026-05-12 05:11:03'),
	(87, 9, 7, 'text', 'e', NULL, 1, '2026-05-12 05:11:17'),
	(88, 9, 7, 'text', 'qưeqwe', NULL, 1, '2026-05-12 05:11:25'),
	(89, 9, 7, 'text', 'qư', NULL, 1, '2026-05-12 05:11:25'),
	(90, 9, 7, 'text', 'eq', NULL, 1, '2026-05-12 05:11:25'),
	(91, 9, 7, 'text', 'e', NULL, 1, '2026-05-12 05:11:25'),
	(92, 9, 7, 'text', 'ưe', NULL, 1, '2026-05-12 05:11:26'),
	(93, 9, 7, 'text', 'qư', NULL, 1, '2026-05-12 05:11:26'),
	(94, 9, 7, 'text', 'e', NULL, 1, '2026-05-12 05:11:26'),
	(95, 9, 7, 'text', 'ưe', NULL, 1, '2026-05-12 05:11:26'),
	(96, 9, 7, 'text', 'qư', NULL, 1, '2026-05-12 05:11:26'),
	(97, 9, 7, 'text', 'e', NULL, 1, '2026-05-12 05:11:27'),
	(98, 8, 3, 'text', '?', NULL, 1, '2026-05-13 04:44:52'),
	(101, 11, 19, 'product', '{"id":5,"name":"Móc khóa thú len handmade","price":"100.000₫","image":"public/uploads/vn-11134207-820l4-mhs7hbm2vwg209.png"}', NULL, 1, '2026-05-13 06:17:56'),
	(102, 12, 19, 'product', '{"id":39,"name":"Len sợi Acrylic Paintbox Yarns Simply DK","price":"30.000₫","image":"public/uploads/prod_69f30741ba86a_1777534785.jpg"}', NULL, 1, '2026-05-13 06:26:31'),
	(106, 11, 19, 'product', '{"id":42,"name":"len sợi pha","price":"24.250₫","old_price":"25.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ae6d5da_1777539246.jpg"}', NULL, 1, '2026-05-13 06:39:18'),
	(109, 11, 19, 'product', '{"id":41,"name":"Sợi Ni lông 70D - Salud Style","price":"56.400₫","old_price":"60.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318905070f_1777539216.jpg"}', NULL, 1, '2026-05-13 06:44:58'),
	(110, 11, 19, 'text', 'ee', NULL, 1, '2026-05-13 06:45:07'),
	(111, 11, 19, 'text', 'e', NULL, 1, '2026-05-13 06:45:07'),
	(112, 11, 19, 'text', 'e', NULL, 1, '2026-05-13 06:45:08'),
	(113, 11, 19, 'text', 'e', NULL, 1, '2026-05-13 06:45:10'),
	(114, 11, 19, 'product', '{"id":5,"name":"Móc khóa thú len handmade","price":"100.000₫","image":"public/uploads/vn-11134207-820l4-mhs7hbm2vwg209.png"}', NULL, 1, '2026-05-13 06:45:13'),
	(115, 11, 19, 'product', '{"id":41,"name":"Sợi Ni lông 70D - Salud Style","price":"60.000₫","image":"public/uploads/prod_69f318905070f_1777539216.jpg"}', NULL, 1, '2026-05-13 06:45:25'),
	(116, 11, 19, 'product', '{"id":42,"name":"len sợi pha","price":"24.250₫","old_price":"25.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ae6d5da_1777539246.jpg"}', NULL, 1, '2026-05-13 06:45:48'),
	(117, 11, 19, 'product', '{"id":5,"name":"Móc khóa thú len handmade","price":"100.000₫","image":"public/uploads/vn-11134207-820l4-mhs7hbm2vwg209.png"}', NULL, 1, '2026-05-13 06:49:05'),
	(118, 11, 19, 'text', '2', NULL, 1, '2026-05-13 06:49:05'),
	(119, 11, 19, 'text', 'Test 3', NULL, 1, '2026-05-13 06:49:05'),
	(120, 11, 3, 'text', 'ádsasd', NULL, 1, '2026-05-13 06:49:33'),
	(121, 11, 3, 'text', 'ád', NULL, 1, '2026-05-13 06:49:34'),
	(122, 11, 3, 'text', 'á', NULL, 1, '2026-05-13 06:49:35'),
	(123, 11, 3, 'text', 'da', NULL, 1, '2026-05-13 06:49:35'),
	(124, 11, 3, 'text', 'd', NULL, 1, '2026-05-13 06:49:36'),
	(125, 11, 3, 'product', '{"id":42,"name":"len sợi pha","price":"24.250₫","old_price":"25.000₫","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ae6d5da_1777539246.jpg"}', NULL, 1, '2026-05-13 06:49:40'),
	(126, 11, 3, 'product', '{"id":35,"name":"Thú treo xe, cặp","price":"45.000₫","old_price":"","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69e6f8ae5ccd3_1776744622.jpg"}', NULL, 1, '2026-05-13 06:49:43'),
	(127, 11, 19, 'text', 'Msg 1', NULL, 1, '2026-05-13 06:49:51'),
	(128, 11, 19, 'text', 'Msg 2', NULL, 1, '2026-05-13 06:49:54'),
	(129, 11, 19, 'text', 'Msg 3', NULL, 1, '2026-05-13 06:49:57'),
	(130, 9, 7, 'product', '{"id":43,"name":"Len Milk Cotton 2mm 50g","price":"15.000₫","old_price":"","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ceaba30_1777539278.jpg"}', NULL, 1, '2026-05-13 09:18:46'),
	(131, 9, 7, 'product', '{"id":43,"name":"Len Milk Cotton 2mm 50g","price":"15.000₫","old_price":"","image":"http://localhost:8080/QLBANDOHANDMADE/public/uploads/prod_69f318ceaba30_1777539278.jpg"}', NULL, 1, '2026-05-13 09:19:29'),
	(132, 14, 7, 'product', '{"id":27,"name":"Hoa hồng đơn","price":"75.000₫","image":"public/uploads/prod_69e702664c008_1776747110.jpg"}', NULL, 1, '2026-05-13 09:40:57'),
	(133, 9, 7, 'product', '{"id":39,"name":"Len sợi Acrylic Paintbox Yarns Simply DK","price":"30.000₫","image":"public/uploads/prod_69f30741ba86a_1777534785.jpg"}', NULL, 1, '2026-05-13 09:41:19'),
	(134, 9, 7, 'product', '{"id":39,"name":"Len sợi Acrylic Paintbox Yarns Simply DK","price":"30.000₫","image":"public/uploads/prod_69f30741ba86a_1777534785.jpg"}', NULL, 1, '2026-05-13 09:41:25'),
	(135, 9, 7, 'text', 'ss', NULL, 1, '2026-05-13 09:41:26'),
	(139, 16, 11, 'text', 'kkk', NULL, 1, '2026-05-13 13:07:51'),
	(147, 20, 18, 'text', 'alo', NULL, 1, '2026-05-14 06:21:34'),
	(148, 21, 18, 'text', '.', NULL, 1, '2026-05-14 06:22:51'),
	(149, 20, 3, 'text', 'sao', NULL, 1, '2026-05-14 06:27:35'),
	(150, 21, 18, 'product', '{"id":27,"name":"Hoa hồng đơn","price":"75.000₫","image":"public/uploads/prod_69e702664c008_1776747110.jpg"}', NULL, 1, '2026-05-18 02:16:16'),
	(151, 21, 18, 'text', 'hahaa', NULL, 1, '2026-05-18 02:16:20'),
	(152, 18, 20, 'text', 'hi', NULL, 1, '2026-05-20 06:44:47'),
	(153, 18, 20, 'text', 'có bán mèo hong dạ', NULL, 1, '2026-05-20 06:45:09'),
	(154, 18, 5, 'text', 'hong', NULL, 1, '2026-05-20 06:45:31'),
	(155, 18, 20, 'text', '.', NULL, 1, '2026-05-20 06:54:22'),
	(156, 18, 5, 'text', 'hihi', NULL, 1, '2026-05-20 06:56:26'),
	(157, 16, 11, 'text', 'hé lô, này bán sao', NULL, 0, '2026-05-20 10:07:26'),
	(158, 22, 5, 'product', '{"id":53,"name":"Lục Lạc Vòng ","price":"90.000₫","old_price":"","image":"http://localhost:8080/public/uploads/"}', NULL, 1, '2026-05-23 06:33:54'),
	(159, 22, 5, 'product', '{"id":42,"name":"len sợi pha","price":"24.250₫","old_price":"25.000₫","image":"http://localhost:8080/public/uploads/prod_69f318ae6d5da_1777539246.jpg"}', NULL, 1, '2026-05-23 06:34:00'),
	(160, 22, 5, 'product', '{"id":53,"name":"Lục Lạc Vòng ","price":"90.000₫","old_price":"","image":"http://localhost:8080/public/uploads/"}', NULL, 1, '2026-05-23 06:37:15'),
	(161, 22, 5, 'product', '{"id":51,"name":"FTRB","price":"20.000₫","old_price":"","image":"http://localhost:8080/public/uploads/prod_6a1131aca5dbb_1779511724.jpg"}', NULL, 1, '2026-05-23 06:37:18');

-- Dumping structure for table handmade_shop.conversations
CREATE TABLE IF NOT EXISTS `conversations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_id` int NOT NULL,
  `seller_id` int NOT NULL DEFAULT '0',
  `last_message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `last_message_type` enum('text','image','video','sticker','product','order') COLLATE utf8mb4_unicode_ci DEFAULT 'text',
  `last_message_at` datetime DEFAULT NULL,
  `is_pinned` tinyint(1) DEFAULT '0',
  `is_muted` tinyint(1) DEFAULT '0',
  `unread_admin` int DEFAULT '0',
  `unread_customer` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.conversations: ~15 rows (approximately)
INSERT INTO `conversations` (`id`, `customer_id`, `seller_id`, `last_message`, `last_message_type`, `last_message_at`, `is_pinned`, `is_muted`, `unread_admin`, `unread_customer`, `created_at`, `updated_at`, `deleted_at`) VALUES
	(1, 3, 3, 'ágfasfg', 'text', '2026-05-12 11:58:27', 0, 0, 0, 0, '2026-04-30 10:01:43', '2026-05-12 04:58:27', NULL),
	(4, 6, 0, 'sao', 'text', '2026-05-01 12:53:56', 0, 0, 0, 0, '2026-05-01 04:05:07', '2026-05-01 05:53:56', NULL),
	(5, 16, 0, '[order]', 'order', '2026-05-01 13:13:57', 0, 0, 0, 0, '2026-05-01 05:02:56', '2026-05-01 06:13:57', NULL),
	(6, 17, 0, 'ád', 'text', '2026-05-12 12:02:31', 0, 0, 0, 0, '2026-05-01 06:28:56', '2026-05-12 05:02:31', NULL),
	(8, 7, 0, '?', 'text', '2026-05-13 11:44:52', 0, 0, 0, 0, '2026-05-12 04:46:56', '2026-05-13 04:44:52', NULL),
	(9, 7, 6, 'ss', 'text', '2026-05-13 16:41:26', 0, 0, 0, 0, '2026-05-12 05:11:15', '2026-05-13 09:41:26', NULL),
	(10, 19, 0, NULL, 'text', NULL, 0, 0, 0, 0, '2026-05-13 06:16:05', '2026-05-13 06:16:05', NULL),
	(11, 19, 3, 'Msg 3', 'text', '2026-05-13 13:49:57', 0, 0, 0, 0, '2026-05-13 06:17:37', '2026-05-13 06:49:57', NULL),
	(12, 19, 6, '[product]', 'product', '2026-05-13 13:26:31', 0, 0, 0, 0, '2026-05-13 06:26:30', '2026-05-13 06:26:31', NULL),
	(14, 7, 3, '[product]', 'product', '2026-05-13 16:40:57', 0, 0, 0, 0, '2026-05-13 09:20:00', '2026-05-13 09:40:57', NULL),
	(16, 11, 0, 'hé lô, này bán sao', 'text', '2026-05-20 17:07:26', 0, 0, 0, 0, '2026-05-13 13:07:46', '2026-05-20 10:07:26', NULL),
	(17, 20, 0, NULL, 'text', NULL, 0, 0, 0, 0, '2026-05-13 14:16:26', '2026-05-13 14:16:26', NULL),
	(18, 20, 3, 'hihi', 'text', '2026-05-20 13:56:26', 0, 0, 0, 0, '2026-05-13 14:16:26', '2026-05-20 06:56:26', NULL),
	(20, 18, 0, 'sao', 'text', '2026-05-14 13:27:35', 0, 0, 0, 0, '2026-05-14 06:21:30', '2026-05-14 06:27:35', NULL),
	(21, 18, 5, 'hahaa', 'text', '2026-05-18 09:16:20', 0, 0, 0, 0, '2026-05-14 06:22:48', '2026-05-18 02:16:20', NULL),
	(22, 5, 18, '[product]', 'product', '2026-05-23 13:37:18', 0, 0, 0, 0, '2026-05-23 06:33:19', '2026-05-23 06:37:18', NULL),
	(23, 3, 5, NULL, 'text', NULL, 0, 0, 0, 0, '2026-06-08 07:42:55', '2026-06-08 07:42:55', NULL),
	(24, 3, 11, NULL, 'text', NULL, 0, 0, 0, 0, '2026-06-08 07:43:47', '2026-06-08 07:43:47', NULL);

-- Dumping structure for table handmade_shop.notifications
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'system',
  `link` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=127 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.notifications: ~77 rows (approximately)
INSERT INTO `notifications` (`id`, `user_id`, `title`, `message`, `type`, `link`, `is_read`, `created_at`) VALUES
	(1, 3, NULL, 'Có đơn đặt hàng mới #28 trị giá 59.100 đ', 'system', 'index.php?url=Dashboard/orders', 1, '2026-04-30 07:42:01'),
	(2, 5, NULL, 'Có đơn đặt hàng mới #28 trị giá 59.100 đ', 'system', 'index.php?url=Dashboard/orders', 0, '2026-04-30 07:42:01'),
	(3, 3, NULL, 'Có đơn đặt hàng mới #29 trị giá 59.100 đ', 'system', 'index.php?url=Dashboard/orders', 1, '2026-04-30 07:50:07'),
	(4, 5, NULL, 'Có đơn đặt hàng mới #29 trị giá 59.100 đ', 'system', 'index.php?url=Dashboard/orders', 0, '2026-04-30 07:50:07'),
	(5, 3, NULL, 'Đơn hàng #29 của bạn đã được cập nhật thành: Đang giao', 'system', 'index.php?url=Page/orders', 1, '2026-04-30 07:54:54'),
	(6, 3, NULL, 'Yêu cầu trả hàng mới cho đơn hàng #19', 'system', 'index.php?url=Dashboard/returnDetail/1', 1, '2026-04-30 08:05:42'),
	(7, 5, NULL, 'Yêu cầu trả hàng mới cho đơn hàng #19', 'system', 'index.php?url=Dashboard/returnDetail/1', 0, '2026-04-30 08:05:42'),
	(8, 3, NULL, 'Đơn hàng #28 của bạn đã được cập nhật thành: Đã giao thành công', 'system', 'index.php?url=Page/orders', 1, '2026-04-30 08:22:00'),
	(9, 3, NULL, 'Đơn hàng #27 của bạn đã được cập nhật thành: Đã giao thành công', 'system', 'index.php?url=Page/orders', 1, '2026-04-30 08:22:01'),
	(10, 3, NULL, 'Yêu cầu trả hàng mới cho đơn hàng #28', 'system', 'index.php?url=Dashboard/returnDetail/2', 1, '2026-04-30 08:22:16'),
	(11, 5, NULL, 'Yêu cầu trả hàng mới cho đơn hàng #28', 'system', 'index.php?url=Dashboard/returnDetail/2', 0, '2026-04-30 08:22:16'),
	(12, 3, NULL, 'Yêu cầu trả hàng mới cho đơn hàng #27', 'system', 'index.php?url=Dashboard/returnDetail/3', 1, '2026-04-30 08:25:25'),
	(13, 5, NULL, 'Yêu cầu trả hàng mới cho đơn hàng #27', 'system', 'index.php?url=Dashboard/returnDetail/3', 0, '2026-04-30 08:25:25'),
	(14, 3, NULL, 'Có đơn đặt hàng mới #30 trị giá 59.100 đ', 'system', 'index.php?url=Dashboard/orders', 1, '2026-04-30 08:50:56'),
	(15, 5, NULL, 'Có đơn đặt hàng mới #30 trị giá 59.100 đ', 'system', 'index.php?url=Dashboard/orders', 0, '2026-04-30 08:50:56'),
	(16, 3, NULL, 'Có đơn đặt hàng mới #31 trị giá 310.000 đ', 'system', 'index.php?url=Dashboard/orders', 1, '2026-05-01 06:30:44'),
	(17, 5, NULL, 'Có đơn đặt hàng mới #31 trị giá 310.000 đ', 'system', 'index.php?url=Dashboard/orders', 0, '2026-05-01 06:30:44'),
	(18, 3, 'Yêu cầu đăng ký Seller mới', 'Người dùng Han Khanh vừa gửi yêu cầu mở shop: Hân Shop', 'seller_request', 'index.php?url=Admin/manageSellers', 1, '2026-05-09 06:21:00'),
	(19, 5, 'Yêu cầu đăng ký Seller mới', 'Người dùng Han Khanh vừa gửi yêu cầu mở shop: Hân Shop', 'seller_request', 'index.php?url=Admin/manageSellers', 0, '2026-05-09 06:21:00'),
	(20, 5, 'Thông báo hệ thống', 'Đơn hàng #21 của bạn đã được cập nhật thành: Đang giao', 'system', 'index.php?url=Page/orders', 0, '2026-05-09 06:31:19'),
	(21, 5, 'Thông báo hệ thống', 'Đơn hàng #21 của bạn đã được cập nhật thành: Đã giao thành công', 'system', 'index.php?url=Page/orders', 0, '2026-05-09 06:31:26'),
	(22, 5, 'Thông báo hệ thống', 'Đơn hàng #21 của bạn đã được cập nhật thành: Đã xác nhận', 'system', 'index.php?url=Page/orders', 0, '2026-05-09 06:31:28'),
	(23, 17, 'Thông báo hệ thống', 'Đơn hàng #31 của bạn đã được cập nhật thành: Đã giao thành công', 'system', 'index.php?url=Page/orders', 0, '2026-05-09 06:31:33'),
	(24, 17, 'Thông báo hệ thống', 'Đơn hàng #31 của bạn đã được cập nhật thành: Đã hủy', 'system', 'index.php?url=Page/orders', 0, '2026-05-09 06:31:36'),
	(25, 3, 'Thông báo hệ thống', 'Đơn hàng #27 của bạn đã được cập nhật thành: Đã hủy', 'system', 'index.php?url=Page/orders', 1, '2026-05-09 06:35:34'),
	(26, 5, 'Thông báo hệ thống', 'Đơn hàng #8 của bạn đã được cập nhật thành: Đang giao', 'system', 'index.php?url=Page/orders', 0, '2026-05-09 06:36:25'),
	(27, 3, 'Thông báo hệ thống', 'Đơn hàng #30 của bạn đã được cập nhật thành: Đã giao thành công', 'system', 'index.php?url=Page/orders', 1, '2026-05-09 06:38:10'),
	(28, 18, 'Yêu cầu lên Người bán bị từ chối', 'Rất tiếc, yêu cầu của bạn bị từ chối. Lý do: no', 'danger', 'index.php?url=Seller/register', 1, '2026-05-09 06:42:51'),
	(29, 3, 'Yêu cầu đăng ký Seller mới', 'Người dùng Han Khanh vừa gửi yêu cầu mở shop: Han Shop', 'seller_request', 'index.php?url=Admin/manageSellers', 1, '2026-05-09 07:54:02'),
	(30, 5, 'Yêu cầu đăng ký Seller mới', 'Người dùng Han Khanh vừa gửi yêu cầu mở shop: Han Shop', 'seller_request', 'index.php?url=Admin/manageSellers', 0, '2026-05-09 07:54:02'),
	(31, 3, 'Yêu cầu đăng ký Seller mới', 'Người dùng Han Khanh vừa gửi yêu cầu mở shop: Han Shop', 'seller_request', 'index.php?url=Admin/manageSellers', 1, '2026-05-09 07:55:56'),
	(32, 5, 'Yêu cầu đăng ký Seller mới', 'Người dùng Han Khanh vừa gửi yêu cầu mở shop: Han Shop', 'seller_request', 'index.php?url=Admin/manageSellers', 0, '2026-05-09 07:55:56'),
	(33, 18, 'Yêu cầu lên Người bán được phê duyệt', 'Chúc mừng! Cửa hàng "Han Shop" của bạn đã được kích hoạt. Bạn có thể đăng sản phẩm ngay bây giờ.', 'success', 'index.php?url=Product/myProducts', 1, '2026-05-09 07:56:02'),
	(34, 3, 'Thông báo hệ thống', 'Có đơn đặt hàng mới #32 trị giá 97.500 đ', 'system', 'index.php?url=Dashboard/orders', 1, '2026-05-09 08:09:19'),
	(35, 5, 'Thông báo hệ thống', 'Có đơn đặt hàng mới #32 trị giá 97.500 đ', 'system', 'index.php?url=Dashboard/orders', 0, '2026-05-09 08:09:19'),
	(36, 3, 'Thông báo hệ thống', 'Đơn hàng #32 của bạn đã được cập nhật thành: Đã giao thành công', 'system', 'index.php?url=Page/orders', 1, '2026-05-09 08:09:49'),
	(37, 3, 'Thông báo hệ thống', 'Có đơn đặt hàng mới #33 trị giá 78.500 đ', 'system', 'index.php?url=Dashboard/orders', 1, '2026-05-09 08:10:30'),
	(38, 5, 'Thông báo hệ thống', 'Có đơn đặt hàng mới #33 trị giá 78.500 đ', 'system', 'index.php?url=Dashboard/orders', 0, '2026-05-09 08:10:30'),
	(39, 1, 'Thông báo hệ thống', 'Sản phẩm mới \' lấy trễ hơn giù\' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-05-09 08:21:06'),
	(40, 3, 'Thông báo hệ thống', 'Có đơn đặt hàng mới #34 trị giá 251.100 đ', 'system', 'index.php?url=Dashboard/orders', 1, '2026-05-13 05:51:22'),
	(41, 5, 'Thông báo hệ thống', 'Có đơn đặt hàng mới #34 trị giá 251.100 đ', 'system', 'index.php?url=Dashboard/orders', 0, '2026-05-13 05:51:22'),
	(42, 3, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shop yêu cầu cập nhật thông tin.', 'system', 'index.php?url=Dashboard/shopUpdates', 1, '2026-05-13 10:10:56'),
	(43, 5, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shop yêu cầu cập nhật thông tin.', 'system', 'index.php?url=Dashboard/shopUpdates', 0, '2026-05-13 10:10:56'),
	(44, 18, 'Cập nhật thông tin Shop thành công', 'Yêu cầu cập nhật thông tin cửa hàng của bạn đã được Admin phê duyệt.', 'success', 'index.php?url=Seller/settings', 1, '2026-05-13 10:11:03'),
	(45, 3, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shop yêu cầu cập nhật thông tin.', 'system', 'index.php?url=Dashboard/shopUpdates', 1, '2026-05-13 10:11:40'),
	(46, 5, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shop yêu cầu cập nhật thông tin.', 'system', 'index.php?url=Dashboard/shopUpdates', 1, '2026-05-13 10:11:40'),
	(47, 18, 'Cập nhật thông tin Shop thành công', 'Yêu cầu cập nhật thông tin cửa hàng của bạn đã được Admin phê duyệt.', 'success', 'index.php?url=Seller/settings', 1, '2026-05-13 10:11:54'),
	(48, 3, 'Thông báo hệ thống', 'Đơn hàng #34 của bạn đã được cập nhật thành: Đã giao thành công', 'system', 'index.php?url=Page/orders', 1, '2026-05-13 10:17:27'),
	(49, 1, 'Thông báo hệ thống', 'Sản phẩm mới \'Len sợi A\' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-05-14 03:42:48'),
	(50, 1, 'Thông báo hệ thống', 'Sản phẩm mới \'Lục Lạc Vòng Gỗ \' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-05-14 03:57:42'),
	(51, 3, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shop yêu cầu cập nhật thông tin.', 'system', 'index.php?url=Dashboard/shopUpdates', 1, '2026-05-14 04:02:27'),
	(52, 5, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shop yêu cầu cập nhật thông tin.', 'system', 'index.php?url=Dashboard/shopUpdates', 0, '2026-05-14 04:02:27'),
	(53, 18, 'Cập nhật thông tin Shop thành công', 'Yêu cầu cập nhật thông tin cửa hàng của bạn đã được Admin phê duyệt.', 'success', 'index.php?url=Seller/settings', 1, '2026-05-14 04:09:00'),
	(54, 3, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shop yêu cầu cập nhật thông tin.', 'system', 'index.php?url=Dashboard/shopUpdates', 1, '2026-05-14 04:37:36'),
	(55, 5, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shop yêu cầu cập nhật thông tin.', 'system', 'index.php?url=Dashboard/shopUpdates', 0, '2026-05-14 04:37:36'),
	(56, 18, 'Cập nhật thông tin Shop thành công', 'Yêu cầu cập nhật thông tin cửa hàng của bạn đã được Admin phê duyệt.', 'success', 'index.php?url=Seller/settings', 1, '2026-05-14 04:38:00'),
	(57, 3, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shoppp yêu cầu cập nhật thông tin.', 'system', 'index.php?url=Dashboard/shopUpdates', 1, '2026-05-14 04:53:57'),
	(58, 5, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shoppp yêu cầu cập nhật thông tin.', 'system', 'index.php?url=Dashboard/shopUpdates', 0, '2026-05-14 04:53:57'),
	(59, 18, 'Cập nhật thông tin Shop thành công', 'Yêu cầu cập nhật thông tin cửa hàng của bạn đã được Admin phê duyệt.', 'success', 'index.php?url=Seller/settings', 1, '2026-05-14 04:54:04'),
	(60, 3, 'Yêu cầu phân quyền Seller', 'Người dùng Khánh Hân muốn trở thành người bán (Seller).', 'seller_request', 'index.php?url=Admin/manageSellers', 1, '2026-05-14 07:58:38'),
	(61, 5, 'Yêu cầu phân quyền Seller', 'Người dùng Khánh Hân muốn trở thành người bán (Seller).', 'seller_request', 'index.php?url=Admin/manageSellers', 0, '2026-05-14 07:58:38'),
	(62, 3, 'Đơn hàng mới', 'Có đơn đặt hàng mới #35 trị giá 85.555 đ', 'order', 'index.php?url=Dashboard/orderDetail/35', 1, '2026-05-18 04:07:42'),
	(63, 5, 'Đơn hàng mới', 'Có đơn đặt hàng mới #35 trị giá 85.555 đ', 'order', 'index.php?url=Dashboard/orderDetail/35', 0, '2026-05-18 04:07:42'),
	(64, 3, 'Thông báo hệ thống', 'Đơn hàng #35 của bạn đã được cập nhật thành: Đã giao thành công', 'system', 'index.php?url=Page/orders', 0, '2026-05-18 04:07:51'),
	(65, 1, 'Thông báo hệ thống', 'Sản phẩm mới \'Gấu bông len handmade nhỏ xinh\' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-05-20 07:18:38'),
	(66, 1, 'Thông báo hệ thống', 'Sản phẩm mới \'Móc khoá mèo chột len\' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-05-20 07:21:27'),
	(67, 3, 'Đơn hàng mới', 'Có đơn đặt hàng mới #36 trị giá 104.000 đ', 'order', 'index.php?url=Dashboard/orderDetail/36', 0, '2026-05-20 07:31:18'),
	(68, 5, 'Đơn hàng mới', 'Có đơn đặt hàng mới #36 trị giá 104.000 đ', 'order', 'index.php?url=Dashboard/orderDetail/36', 1, '2026-05-20 07:31:18'),
	(69, 11, 'Yêu cầu chỉnh sửa sản phẩm', 'Sản phẩm \'Móc khoá mèo chột len\' cần được chỉnh sửa: thêm mô tả chỉ tiết', 'warning', 'index.php?url=Product/edit/49', 1, '2026-05-20 08:37:07'),
	(70, 3, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Nguyễn Huỳnh Minh Thư Shop yêu cầu cập nhật thông tin.', 'shop_update', 'index.php?url=Dashboard/shopUpdates', 1, '2026-05-20 09:13:11'),
	(71, 5, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Nguyễn Huỳnh Minh Thư Shop yêu cầu cập nhật thông tin.', 'shop_update', 'index.php?url=Dashboard/shopUpdates', 0, '2026-05-20 09:13:11'),
	(72, 3, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Nguyễn Huỳnh Minh Thư Shop yêu cầu cập nhật thông tin.', 'shop_update', 'index.php?url=Dashboard/shopUpdates', 1, '2026-05-20 09:21:39'),
	(73, 5, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Nguyễn Huỳnh Minh Thư Shop yêu cầu cập nhật thông tin.', 'shop_update', 'index.php?url=Dashboard/shopUpdates', 1, '2026-05-20 09:21:39'),
	(74, 1, 'Thông báo hệ thống', 'Sản phẩm mới \'Móc khoá mèo chột len\' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-05-20 09:37:39'),
	(75, 5, 'Thông báo hệ thống', 'Đơn hàng #36 của bạn đã được cập nhật thành: Đã hủy', 'system', 'index.php?url=Page/orders', 0, '2026-05-20 09:38:26'),
	(76, 3, 'Đơn hàng mới', 'Có đơn đặt hàng mới #37 trị giá 75.000 đ', 'order', 'index.php?url=Dashboard/orderDetail/37', 0, '2026-05-20 10:03:01'),
	(77, 5, 'Đơn hàng mới', 'Có đơn đặt hàng mới #37 trị giá 75.000 đ', 'order', 'index.php?url=Dashboard/orderDetail/37', 0, '2026-05-20 10:03:01'),
	(78, 5, 'Yêu thích sản phẩm', 'Chu Hoàng Khánh Hân đã thích sản phẩm: Thú treo xe, cặp', 'wishlist', 'index.php?url=Product/show/35', 1, '2026-05-23 03:51:11'),
	(79, 11, 'Cập nhật thông tin Shop thành công', 'Yêu cầu cập nhật thông tin cửa hàng của bạn đã được Admin phê duyệt.', 'success', 'index.php?url=Seller/settings', 0, '2026-05-23 03:52:43'),
	(80, 3, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shoppp yêu cầu cập nhật thông tin.', 'shop_update', 'index.php?url=Dashboard/shopUpdates', 1, '2026-05-23 04:47:09'),
	(81, 5, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shoppp yêu cầu cập nhật thông tin.', 'shop_update', 'index.php?url=Dashboard/shopUpdates', 1, '2026-05-23 04:47:09'),
	(82, 18, 'Yêu cầu chỉnh sửa thông tin Shop', 'Admin yêu cầu chỉnh sửa lại bản cập nhật thông tin Shop của bạn. Nội dung chi tiết: KO', 'warning', 'index.php?url=Seller/settings', 1, '2026-05-23 04:47:38'),
	(83, 1, 'Thông báo hệ thống', 'Sản phẩm mới \'FTRB\' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-05-23 04:48:44'),
	(84, 18, 'Yêu cầu chỉnh sửa sản phẩm', 'Sản phẩm \'FTRB\' cần được chỉnh sửa: XAU', 'warning', 'index.php?url=Product/edit/51', 1, '2026-05-23 04:49:04'),
	(85, 3, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shoppp yêu cầu cập nhật thông tin.', 'shop_update', 'index.php?url=Dashboard/shopUpdates', 1, '2026-05-23 04:54:28'),
	(86, 5, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shoppp yêu cầu cập nhật thông tin.', 'shop_update', 'index.php?url=Dashboard/shopUpdates', 0, '2026-05-23 04:54:28'),
	(87, 3, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shoppp yêu cầu cập nhật thông tin.', 'shop_update', 'index.php?url=Dashboard/shopUpdates', 1, '2026-05-23 04:58:18'),
	(88, 5, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shoppp yêu cầu cập nhật thông tin.', 'shop_update', 'index.php?url=Dashboard/shopUpdates', 1, '2026-05-23 04:58:18'),
	(89, 18, 'Yêu cầu chỉnh sửa thông tin Shop', 'Admin yêu cầu chỉnh sửa lại bản cập nhật thông tin Shop của bạn. Nội dung chi tiết: ko', 'warning', 'index.php?url=Seller/settings', 1, '2026-05-23 04:58:30'),
	(90, 1, 'Thông báo hệ thống', 'Sản phẩm mới \'ầ\' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-05-23 04:59:35'),
	(91, 3, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shoppp yêu cầu cập nhật thông tin.', 'shop_update', 'index.php?url=Dashboard/shopUpdates', 1, '2026-05-23 05:09:11'),
	(92, 5, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shoppp yêu cầu cập nhật thông tin.', 'shop_update', 'index.php?url=Dashboard/shopUpdates', 0, '2026-05-23 05:09:11'),
	(93, 18, 'Cập nhật thông tin Shop thành công', 'Yêu cầu cập nhật thông tin cửa hàng của bạn đã được Admin phê duyệt.', 'success', 'index.php?url=Seller/settings', 1, '2026-05-23 05:09:53'),
	(94, 3, 'Rút tiền tự động thành công', 'Seller Han Khanh vừa rút thành công 40.000 ₫ về ngân hàng.', 'withdrawal_request', 'index.php?url=Dashboard/manageWithdrawals', 1, '2026-05-23 05:12:35'),
	(95, 5, 'Rút tiền tự động thành công', 'Seller Han Khanh vừa rút thành công 40.000 ₫ về ngân hàng.', 'withdrawal_request', 'index.php?url=Dashboard/manageWithdrawals', 1, '2026-05-23 05:12:35'),
	(96, 1, 'Thông báo hệ thống', 'Sản phẩm mới \'Lục Lạc Vòng \' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-05-23 05:14:40'),
	(97, 3, 'Đơn hàng mới', 'Có đơn đặt hàng mới #38 trị giá 375.000 đ', 'order', 'index.php?url=Dashboard/orderDetail/38', 0, '2026-05-23 05:41:58'),
	(98, 3, 'Thông báo hệ thống', 'Đơn hàng #38 của bạn đã được cập nhật thành: Đã giao thành công', 'system', 'index.php?url=Page/orders', 0, '2026-05-23 05:42:10'),
	(99, 3, 'Đơn hàng mới', 'Có đơn đặt hàng mới #39 trị giá 105.000 đ', 'order', 'index.php?url=Dashboard/orderDetail/39', 0, '2026-05-23 05:43:07'),
	(100, 3, 'Thông báo hệ thống', 'Đơn hàng #29 của bạn đã được cập nhật thành: Đang giao', 'system', 'index.php?url=Page/orders', 0, '2026-05-23 05:43:37'),
	(101, 3, 'Thông báo hệ thống', 'Đơn hàng #29 của bạn đã được cập nhật thành: Đang giao', 'system', 'index.php?url=Page/orders', 0, '2026-05-23 05:43:39'),
	(102, 3, 'Thông báo hệ thống', 'Đơn hàng #29 của bạn đã được cập nhật thành: Đã giao thành công', 'system', 'index.php?url=Page/orders', 0, '2026-05-23 05:43:40'),
	(103, 3, 'Thông báo hệ thống', 'Đơn hàng #39 của bạn đã được cập nhật thành: Đã giao thành công', 'system', 'index.php?url=Page/orders', 0, '2026-05-23 05:43:46'),
	(104, 3, 'Rút tiền tự động thành công', 'Seller Nguyễn Lan Phương vừa rút thành công 100.000 ₫ về ngân hàng.', 'withdrawal_request', 'index.php?url=Dashboard/manageWithdrawals', 1, '2026-05-23 06:03:12'),
	(105, 3, 'Đơn hàng mới', 'Có đơn đặt hàng mới #40 trị giá 253.000 đ', 'order', 'index.php?url=Dashboard/orderDetail/40', 0, '2026-05-23 06:15:55'),
	(106, 5, 'Đơn hàng mới', 'Có đơn đặt hàng mới #40 trị giá 253.000 đ', 'order', 'index.php?url=Dashboard/orderDetail/40', 1, '2026-05-23 06:15:55'),
	(107, 5, 'Thông báo hệ thống', 'Đơn hàng #40 của bạn đã được cập nhật thành: Đã giao thành công', 'system', 'index.php?url=Page/orders', 0, '2026-05-23 06:17:05'),
	(108, 3, 'Đơn hàng mới', 'Có đơn đặt hàng mới #41 trị giá 135.000 đ', 'order', 'index.php?url=Dashboard/orderDetail/41', 1, '2026-05-23 06:20:27'),
	(109, 5, 'Đơn hàng mới', 'Có đơn đặt hàng mới #41 trị giá 135.000 đ', 'order', 'index.php?url=Dashboard/orderDetail/41', 0, '2026-05-23 06:20:27'),
	(110, 3, 'Đơn hàng mới', 'Có đơn đặt hàng mới #42 trị giá 84.250 đ', 'order', 'index.php?url=Dashboard/orderDetail/42', 1, '2026-05-23 06:26:07'),
	(111, 5, 'Đơn hàng mới', 'Có đơn đặt hàng mới #42 trị giá 84.250 đ', 'order', 'index.php?url=Dashboard/orderDetail/42', 1, '2026-05-23 06:26:07'),
	(112, 5, 'Yêu thích sản phẩm', 'Chu Hoàng Khánh Hân đã thích sản phẩm: Hoa hồng đơn', 'wishlist', 'index.php?url=Product/show/27', 0, '2026-05-31 10:00:13'),
	(113, 1, 'Thông báo hệ thống', 'Sản phẩm mới \'Bó hoa cưới – Hoa tulip, hoa chuông bằng len handmade\' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-06-08 10:34:16'),
	(114, 1, 'Thông báo hệ thống', 'Sản phẩm mới \'Bó hoa len thú viền hoa phối hoa hồng xinh xắn\' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-06-08 10:36:12'),
	(115, 1, 'Thông báo hệ thống', 'Sản phẩm mới \'MÓC KHOÁ CẦU LÔNG BẰNG LEN KÈM HOA BẮP MÀU XINH XẮN\' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-06-08 10:41:06'),
	(116, 1, 'Thông báo hệ thống', 'Sản phẩm mới \'Móc Khoá Hoa Linh Lan – Tinh Tế, Nhỏ Xinh, Treo Túi & Xe Ô Tô Siêu Dễ Thương\' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-06-08 10:47:04'),
	(117, 1, 'Thông báo hệ thống', 'Sản phẩm mới \'Gift Box Hộp Quà Hoa Len Handmade 6 Món – Món Quà Ý Nghĩa, Sang Trọng Và Tinh Tế\' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-06-08 10:49:58'),
	(118, 1, 'Thông báo hệ thống', 'Sản phẩm mới \'Hoa Thủy Tiên Vàng Handmade – Sắc Hoa May Mắn, Quà Tặng Ngọt Ngào\' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-06-08 10:51:19'),
	(119, 1, 'Thông báo hệ thống', 'Sản phẩm mới \'Kéo Cắt Len, Chỉ Cao Cấp Có Nắp Đậy – Dụng Cụ Đan Móc Len\' từ người bán đang chờ phê duyệt.', 'system', 'index.php?url=Dashboard/products', 0, '2026-06-08 10:54:26'),
	(120, 3, 'Yêu cầu chỉnh sửa sản phẩm', 'Cửa hàng Han Shoppp yêu cầu duyệt chỉnh sửa sản phẩm: Kéo Cắt Len, Chỉ Cao Cấp Có Nắp Đậy – Dụng Cụ Đan Móc Len', 'shop_update', 'index.php?url=Dashboard/pendingProducts#row-61', 1, '2026-06-08 11:13:24'),
	(121, 5, 'Yêu cầu chỉnh sửa sản phẩm', 'Cửa hàng Han Shoppp yêu cầu duyệt chỉnh sửa sản phẩm: Kéo Cắt Len, Chỉ Cao Cấp Có Nắp Đậy – Dụng Cụ Đan Móc Len', 'shop_update', 'index.php?url=Dashboard/pendingProducts#row-61', 0, '2026-06-08 11:13:24'),
	(122, 3, 'Yêu cầu duyệt sản phẩm mới', 'Cửa hàng Han Shoppp yêu cầu duyệt sản phẩm mới: Kim Khâu Len Sợi Inox Không Gỉ – Dụng Cụ Đan Móc Tiện Lợi', 'shop_update', 'index.php?url=Dashboard/pendingProducts#row-62', 1, '2026-06-08 11:17:41'),
	(123, 5, 'Yêu cầu duyệt sản phẩm mới', 'Cửa hàng Han Shoppp yêu cầu duyệt sản phẩm mới: Kim Khâu Len Sợi Inox Không Gỉ – Dụng Cụ Đan Móc Tiện Lợi', 'shop_update', 'index.php?url=Dashboard/pendingProducts#row-62', 0, '2026-06-08 11:17:41'),
	(124, 3, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shoppp yêu cầu cập nhật thông tin.', 'shop_update', 'index.php?url=Dashboard/shopUpdates', 1, '2026-06-08 11:19:49'),
	(125, 5, 'Yêu cầu cập nhật thông tin Shop', 'Cửa hàng Han Shoppp yêu cầu cập nhật thông tin.', 'shop_update', 'index.php?url=Dashboard/shopUpdates', 0, '2026-06-08 11:19:49'),
	(126, 18, 'Cập nhật thông tin Shop thành công', 'Yêu cầu cập nhật thông tin cửa hàng của bạn đã được Admin phê duyệt.', 'success', 'index.php?url=Seller/settings', 0, '2026-06-08 11:20:06');

-- Dumping structure for table handmade_shop.orders
CREATE TABLE IF NOT EXISTS `orders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `recipient_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `recipient_phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `recipient_address` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `user_id` int DEFAULT NULL,
  `total` decimal(10,2) DEFAULT NULL,
  `status` enum('pending','confirmed','shipping','completed','cancelled') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `payment_method` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'cod',
  `shipping_fee` decimal(10,2) DEFAULT '0.00',
  `commission_settled` tinyint(1) NOT NULL DEFAULT '0',
  `cancel_reason` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.orders: ~35 rows (approximately)
INSERT INTO `orders` (`id`, `recipient_name`, `recipient_phone`, `recipient_address`, `note`, `user_id`, `total`, `status`, `payment_method`, `shipping_fee`, `commission_settled`, `cancel_reason`, `created_at`) VALUES
	(1, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân Lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', NULL, 3, 180000.00, 'completed', 'cod', 0.00, 0, 'Tôi muốn cập nhật địa chỉ/sđt nhận hàng.', '2026-03-21 05:22:12'),
	(2, 'Nguyễn Lan Phương', '0382613031', '60/6, Trương Thị Khét, Xã Phước Thạnh, Huyện Củ Chi, Thành phố Hồ Chí Minh', NULL, 5, 2660000.00, 'completed', 'cod', 0.00, 0, NULL, '2026-03-24 04:11:20'),
	(3, 'Nguyễn Lan Phương', '0382613031', '60/6, Trương Thị Khét, Xã Phước Thạnh, Huyện Củ Chi, Thành phố Hồ Chí Minh', NULL, 5, 100000.00, 'completed', 'cod', 0.00, 0, NULL, '2026-04-04 17:08:28'),
	(4, 'Nguyễn Lan Phương', '0382613031', '60/6, Trương Thị Khét, Xã Phước Thạnh, Huyện Củ Chi, Thành phố Hồ Chí Minh', NULL, 5, 100000.00, 'cancelled', 'cod', 0.00, 0, NULL, '2026-04-04 17:16:04'),
	(5, 'Hân', '0964325331', '60/49 Phan Chu Trinh, Phường Lộc Tiến, Thành phố Bảo Lộc, Tỉnh Lâm Đồng', NULL, 8, 120000.00, 'pending', 'cod', 0.00, 0, NULL, '2026-04-08 05:05:37'),
	(6, 'Hân', '0964325344', '34 Tân Lập 1, Phường Hiệp Phú, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', NULL, 9, 1000000.00, 'pending', 'cod', 0.00, 0, NULL, '2026-04-10 09:16:01'),
	(7, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân Lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', NULL, 3, 180000.00, 'cancelled', 'cod', 0.00, 0, 'Tôi muốn thay đổi sản phẩm (kích thước, màu sắc, số lượng...)', '2026-04-10 09:17:50'),
	(8, 'Nguyễn Lan Phương', '0382613031', '60/6, Trương Thị Khét, Xã Phước Thạnh, Huyện Củ Chi, Thành phố Hồ Chí Minh', NULL, 5, 480000.00, 'shipping', 'cod', 0.00, 0, NULL, '2026-04-11 15:38:42'),
	(9, 'Nguyễn Lan Phương', '0382613031', '60/6, Trương Thị Khét, Xã Phước Thạnh, Huyện Củ Chi, Thành phố Hồ Chí Minh', NULL, 5, 390000.00, 'pending', 'cod', 0.00, 0, NULL, '2026-04-13 10:22:27'),
	(10, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân Lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 14, 130000.00, 'pending', 'cod', 0.00, 0, NULL, '2026-04-17 14:16:45'),
	(11, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân Lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 14, 340000.00, 'pending', 'cod', 0.00, 0, NULL, '2026-04-17 14:17:30'),
	(12, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân Lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 14, 550000.00, 'pending', 'cod', 0.00, 0, NULL, '2026-04-17 14:18:05'),
	(13, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân Lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 14, 270000.00, 'pending', 'cod', 0.00, 0, NULL, '2026-04-17 14:18:23'),
	(14, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân Lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 3, 310000.00, 'shipping', 'cod', 0.00, 0, NULL, '2026-04-17 14:23:16'),
	(15, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân Lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 3, 1110000.00, 'cancelled', 'cod', 0.00, 0, 'Thủ tục thanh toán rắc rối', '2026-04-17 14:24:59'),
	(16, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân Lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 3, 130000.00, 'pending', 'cod', 0.00, 0, NULL, '2026-04-17 14:28:00'),
	(17, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân Lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 3, 130000.00, 'pending', 'cod', 0.00, 0, NULL, '2026-04-17 14:34:56'),
	(18, 'Khánh Hân', '0964325348', '60/49 Phan Chu Trinh, Phường Lộc Tiến, Thành phố Bảo Lộc, Tỉnh Lâm Đồng', '', 3, 310000.00, 'cancelled', 'cod', 0.00, 0, NULL, '2026-04-17 14:41:43'),
	(19, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân Lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 3, 1110000.00, 'cancelled', 'cod', 0.00, 0, NULL, '2026-04-17 15:07:10'),
	(20, 'Nguyễn Lan Phương', '0382613031', '60/6, Trương Thị Khét, Xã Phước Thạnh, Huyện Củ Chi, Thành phố Hồ Chí Minh', '', 5, 165000.00, 'pending', 'cod', 0.00, 0, NULL, '2026-04-21 04:45:00'),
	(21, 'Nguyễn Lan Phương', '0382613031', '60/6, Trương Thị Khét, Xã Phước Thạnh, Huyện Củ Chi, Thành phố Hồ Chí Minh', '', 5, 105000.00, 'confirmed', 'cod', 0.00, 0, NULL, '2026-04-21 04:52:40'),
	(26, 'Nguyễn Lan Phương', '0382613031', '60/6, Trương Thị Khét, Xã Phước Thạnh, Huyện Củ Chi, Thành phố Hồ Chí Minh', '', 5, 80000.00, 'pending', 'cod', 0.00, 0, NULL, '2026-04-21 08:30:41'),
	(27, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 3, 59100.00, 'cancelled', 'cod', 30000.00, 0, NULL, '2026-04-30 07:40:55'),
	(28, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 3, 59100.00, 'completed', 'cod', 30000.00, 0, NULL, '2026-04-30 07:42:01'),
	(29, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 3, 59100.00, 'completed', 'cod', 30000.00, 1, NULL, '2026-04-30 07:50:07'),
	(30, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 3, 59100.00, 'completed', 'cod', 30000.00, 0, NULL, '2026-04-30 08:50:56'),
	(32, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 3, 97500.00, 'completed', 'cod', 30000.00, 0, NULL, '2026-05-09 08:09:19'),
	(33, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 3, 78500.00, 'completed', 'cod', 30000.00, 0, NULL, '2026-05-09 08:10:30'),
	(34, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 3, 251100.00, 'completed', 'cod', 30000.00, 0, NULL, '2026-05-13 05:51:22'),
	(35, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 3, 85555.00, 'completed', 'cod', 30000.00, 1, NULL, '2026-05-18 04:07:42'),
	(36, 'Nguyễn Lan Phương', '0382613031', '60/6, Trương Thị Khét, Xã Phước Thạnh, Huyện Củ Chi, Thành phố Hồ Chí Minh', '', 5, 104000.00, 'cancelled', 'cod', 45000.00, 0, NULL, '2026-05-20 07:31:18'),
	(37, 'Nguyễn Lan Phương', '0382613031', '60/6, Trương Thị Khét, Xã Phước Thạnh, Huyện Củ Chi, Thành phố Hồ Chí Minh', '', 5, 75000.00, 'completed', 'cod', 45000.00, 1, NULL, '2026-05-20 10:03:01'),
	(38, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 3, 375000.00, 'completed', 'cod', 0.00, 1, NULL, '2026-05-23 05:41:58'),
	(39, 'Chu Hoàng Khánh Hân', '0964325348', '34 Tân lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', '', 3, 105000.00, 'completed', 'cod', 30000.00, 1, NULL, '2026-05-23 05:43:07'),
	(40, 'Nguyễn Lan Phương', '0382613031', '60/6, Trương Thị Khét, Xã Phước Thạnh, Huyện Củ Chi, Thành phố Hồ Chí Minh', '', 5, 253000.00, 'completed', 'cod', 45000.00, 1, NULL, '2026-05-23 06:15:55'),
	(41, 'Nguyễn Lan Phương', '0382613031', '60/6, Trương Thị Khét, Xã Phước Thạnh, Huyện Củ Chi, Thành phố Hồ Chí Minh', '', 5, 135000.00, 'confirmed', 'cod', 45000.00, 0, NULL, '2026-05-23 06:20:27'),
	(42, 'ádgssgd', '0123456789', '456456, Phường Phúc Xá, Quận Ba Đình, Thành phố Hà Nội', '', 18, 84250.00, 'confirmed', 'cod', 60000.00, 0, NULL, '2026-05-23 06:26:07');

-- Dumping structure for table handmade_shop.order_detail
CREATE TABLE IF NOT EXISTS `order_detail` (
  `id` int NOT NULL AUTO_INCREMENT,
  `order_id` int DEFAULT NULL,
  `product_id` int DEFAULT NULL,
  `variant_id` int DEFAULT '0',
  `quantity` int DEFAULT '1',
  `price` decimal(10,2) DEFAULT NULL,
  `commission_percent` decimal(5,2) NOT NULL DEFAULT '10.00',
  `admin_fee` decimal(12,2) NOT NULL DEFAULT '0.00',
  `seller_receive` decimal(12,2) NOT NULL DEFAULT '0.00',
  `commission_settled` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `order_id` (`order_id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `order_detail_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `order_detail_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.order_detail: ~41 rows (approximately)
INSERT INTO `order_detail` (`id`, `order_id`, `product_id`, `variant_id`, `quantity`, `price`, `commission_percent`, `admin_fee`, `seller_receive`, `commission_settled`) VALUES
	(1, 1, 1, 0, 1, 180000.00, 10.00, 0.00, 0.00, 0),
	(2, 2, 1, 0, 12, 180000.00, 10.00, 0.00, 0.00, 0),
	(3, 2, 2, 0, 1, 500000.00, 10.00, 0.00, 0.00, 0),
	(4, 3, 5, 0, 1, 100000.00, 10.00, 0.00, 0.00, 0),
	(5, 4, 5, 0, 1, 100000.00, 10.00, 0.00, 0.00, 0),
	(6, 5, 11, 0, 1, 120000.00, 10.00, 0.00, 0.00, 0),
	(7, 6, 1, 0, 2, 180000.00, 10.00, 0.00, 0.00, 0),
	(8, 6, 2, 0, 1, 400000.00, 10.00, 0.00, 0.00, 0),
	(9, 6, 6, 0, 2, 120000.00, 10.00, 0.00, 0.00, 0),
	(10, 7, 1, 0, 1, 180000.00, 10.00, 0.00, 0.00, 0),
	(11, 8, 22, 0, 1, 450000.00, 10.00, 0.00, 0.00, 0),
	(12, 9, 1, 0, 2, 180000.00, 10.00, 0.00, 0.00, 0),
	(13, 10, 5, 0, 1, 100000.00, 10.00, 0.00, 0.00, 0),
	(14, 11, 6, 0, 2, 120000.00, 10.00, 0.00, 0.00, 0),
	(15, 12, 6, 0, 2, 120000.00, 10.00, 0.00, 0.00, 0),
	(16, 12, 8, 0, 1, 280000.00, 10.00, 0.00, 0.00, 0),
	(17, 13, 6, 0, 2, 120000.00, 10.00, 0.00, 0.00, 0),
	(18, 14, 8, 0, 1, 280000.00, 10.00, 0.00, 0.00, 0),
	(19, 15, 6, 0, 2, 120000.00, 10.00, 0.00, 0.00, 0),
	(20, 15, 8, 0, 3, 280000.00, 10.00, 0.00, 0.00, 0),
	(21, 16, 5, 0, 1, 100000.00, 10.00, 0.00, 0.00, 0),
	(22, 17, 5, 0, 1, 100000.00, 10.00, 0.00, 0.00, 0),
	(23, 18, 8, 0, 1, 280000.00, 10.00, 0.00, 0.00, 0),
	(24, 19, 6, 0, 2, 120000.00, 10.00, 0.00, 0.00, 0),
	(25, 19, 8, 0, 3, 280000.00, 10.00, 0.00, 0.00, 0),
	(26, 20, 35, 0, 3, 45000.00, 10.00, 0.00, 0.00, 0),
	(27, 21, 27, 0, 1, 75000.00, 10.00, 0.00, 0.00, 0),
	(28, 26, 36, 9, 1, 25000.00, 10.00, 0.00, 0.00, 0),
	(29, 26, 36, 10, 1, 25000.00, 10.00, 0.00, 0.00, 0),
	(30, 27, 39, 0, 1, 29100.00, 10.00, 0.00, 0.00, 0),
	(31, 28, 39, 0, 1, 29100.00, 10.00, 0.00, 0.00, 0),
	(32, 29, 39, 0, 1, 29100.00, 10.00, 2910.00, 26190.00, 1),
	(33, 30, 39, 0, 1, 29100.00, 10.00, 0.00, 0.00, 0),
	(35, 32, 39, 0, 1, 29100.00, 10.00, 0.00, 0.00, 0),
	(36, 32, 40, 0, 1, 38400.00, 10.00, 0.00, 0.00, 0),
	(38, 34, 39, 0, 1, 29100.00, 10.00, 0.00, 0.00, 0),
	(39, 34, 40, 0, 5, 38400.00, 10.00, 0.00, 0.00, 0),
	(40, 35, 47, 0, 1, 55555.00, 10.00, 5555.50, 49999.50, 1),
	(42, 37, 50, 15, 1, 30000.00, 10.00, 3000.00, 27000.00, 1),
	(43, 38, 27, 0, 5, 75000.00, 10.00, 37500.00, 337500.00, 1),
	(44, 39, 27, 0, 1, 75000.00, 10.00, 7500.00, 67500.00, 1),
	(45, 40, 50, 17, 2, 59000.00, 10.00, 11800.00, 106200.00, 1),
	(46, 40, 53, 0, 1, 90000.00, 10.00, 9000.00, 81000.00, 1),
	(47, 41, 53, 0, 1, 90000.00, 10.00, 0.00, 0.00, 0),
	(48, 42, 42, 0, 1, 24250.00, 10.00, 0.00, 0.00, 0);

-- Dumping structure for table handmade_shop.password_resets
CREATE TABLE IF NOT EXISTS `password_resets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `otp_code` varchar(6) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.password_resets: ~0 rows (approximately)
INSERT INTO `password_resets` (`id`, `email`, `otp_code`, `expires_at`, `created_at`) VALUES
	(1, 'hankhanh0901@gmail.com', '537854', '2026-05-12 04:42:23', '2026-05-12 04:37:23');

-- Dumping structure for table handmade_shop.product
CREATE TABLE IF NOT EXISTS `product` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `price` decimal(10,2) NOT NULL,
  `image` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `stock` int DEFAULT '0',
  `category_id` int DEFAULT NULL,
  `sold` int DEFAULT '0',
  `rating` decimal(3,1) DEFAULT '0.0',
  `rating_count` int DEFAULT '0',
  `is_featured` tinyint(1) DEFAULT '0',
  `display_order` int DEFAULT '0',
  `discount_percent` int DEFAULT '0',
  `location` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'Hà Nội',
  `user_id` int DEFAULT '1',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'approved',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `rejection_reason` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `likes` int DEFAULT '0',
  `related_images` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `category_id` (`category_id`),
  CONSTRAINT `product_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `category` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=63 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.product: ~44 rows (approximately)
INSERT INTO `product` (`id`, `name`, `description`, `price`, `image`, `stock`, `category_id`, `sold`, `rating`, `rating_count`, `is_featured`, `display_order`, `discount_percent`, `location`, `user_id`, `status`, `created_at`, `rejection_reason`, `likes`, `related_images`) VALUES
	(1, 'Lục Lạc Vòng Gỗ Handmade đồ chơi an toàn cho Bé', 'chiều cao 10cm\r\nchất liệu từ sợi cotton cao cấp, bền đẹp và an toàn cho bé,\r\nbên trong nhồi bông gòn nhân tạo không gây dị ứng cho bé yêu\r\nMắt được khâu thủ công đảm bảo an toàn', 180000.00, 'luc-lac-vong-go-handmade-do-choi-an-toan-cho-be-11-510x383.jpg', 0, 4, 5, 4.0, 1, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(2, 'Búp bê handmade Autumn', 'chiều cao 30cm\r\nchất liệu từ sợi cotton cao cấp, bền đẹp và an toàn cho bé, không gây dị ứng cho bé yêu\r\nmắt búp bê bằng nhựa, được gắn chốt, đẹp bền và an toàn cho bé trong quá trình sử dụng\r\nváy áo và mũ cũng được làm thủ công có thể tháo rời cho các tự do thay đổi', 400000.00, '61340911_1261004000732867_6425604364278169600_n-510x510.jpg', 0, 4, 1, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(3, 'Gấu bông len handmade nhỏ xinh', 'chiều cao 15cm\r\nchất liệu sợi cotton mềm mại, an toàn cho bé\r\nnhồi bông gòn nhân tạo không gây dị ứng', 150000.00, 'Gấu bông len handmade nhỏ xinh.jpg', 10, 5, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(4, 'Túi xách len handmade vintage', 'kích thước 25cm\r\nchất liệu len đan tay chắc chắn\r\nphong cách vintage thời trang', 250000.00, '65f1236083c7b91075b8d7ca0f5653c4.png', 5, 6, 0, 5.0, 1, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(5, 'Móc khóa thú len handmade', 'kích thước nhỏ gọn\r\nlen mềm nhiều màu sắc\r\nphù hợp làm quà tặng', 100000.00, 'vn-11134207-820l4-mhs7hbm2vwg209.png', 16, 15, 4, 5.0, 1, 1, 3, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(6, 'Nón len handmade mùa đông', 'giữ ấm tốt\r\nlen dày dặn cao cấp\r\nthiết kế dễ thương', 120000.00, 'OIP.png', 12, 7, 12, 0.0, 0, 1, 2, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(7, 'Búp bê len handmade bé gái', 'chiều cao 25cm\r\nváy áo tháo rời\r\nan toàn cho trẻ em', 400000.00, 'Búp bê len handmade bé gái.jpg', 3, 4, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(8, 'Thú bông len hình thỏ', 'cao 20cm\r\nmềm mại dễ thương\r\nphù hợp cho bé', 280000.00, 'd07933460b5dedc29a720c19381eaf76.jpg', 3, 5, 10, 3.0, 2, 1, 1, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 1, NULL),
	(9, ' Khăn len quàng cổ phối màu Pastel KH1', 'kích thước lớn\r\nchất liệu vải bố bền\r\ndùng đi học tiện lợi', 500000.00, '.png', 12, 7, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(10, 'Khăn len handmade', 'chiều dài 150cm\r\ngiữ ấm tốt\r\nlen cao cấp không xù', 660000.00, 'khan_len_pastel_4.jpg', 15, 7, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(11, 'Bộ kim móc len 8 cây', 'nhiều kích thước khác nhau\r\nkim nhẹ dễ sử dụng\r\nphù hợp người mới', 120000.00, 'OIP .png', 24, 1, 1, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(12, 'Kéo cắt len mini', 'thiết kế nhỏ gọn\r\nlưỡi kéo sắc bén\r\ntiện mang theo', 10000.00, 'prod_69e6ee466409f_1776741958.png', 30, 3, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 1, NULL),
	(13, 'Búp bê len handmade cặp đôi', 'gồm 2 búp bê\r\nthiết kế đáng yêu\r\nphù hợp làm quà', 600000.00, 'a77764815a5da21ca06e0c81a6a10c59.jpg', 2, 4, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 1, NULL),
	(14, 'Gấu bông len size lớn', 'chiều cao 40cm\r\nôm siêu thích\r\nlen mềm mại', 650000.00, 'giantshepe.png', 4, 5, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(15, 'Túi đeo chéo len unisex cỡ lớn họa tiết con mắt', 'dây đeo chắc chắn\r\nthiết kế trẻ trung\r\nphù hợp đi chơi', 270000.00, 'vn-11134201-7qukw-lhnet8bb1tc19f.png', 7, 6, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(16, 'Nón bucket handmade', 'phong cách thời trang\r\nlen mềm thoáng\r\nhot trend hiện nay', 150000.00, '1.png', 9, 7, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(17, 'Thảm lót ly handmade', 'đan len thủ công\r\nchịu nhiệt tốt\r\ntrang trí đẹp', 200000.00, '601fe975d579a5635ddb7579077cd6dd.jpg', 18, 8, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(18, 'Giỏ đựng đồ handmade', 'dùng trang trí\r\nđựng đồ tiện lợi\r\nthiết kế đẹp mắt', 220000.00, '8.png', 6, 8, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(20, 'Thú len hình mèo', 'thiết kế mèo dễ thương\r\nlen mềm mại\r\nphù hợp mọi lứa tuổi', 160000.00, 'OIP (1).png', 11, 5, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(21, 'Túi xách len mini', 'kích thước nhỏ gọn\r\nphong cách xinh xắn\r\ndễ phối đồ', 180000.00, 'OIP (2).png', 10, 6, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(22, 'Combo 3 búp bê len handmade Noel', 'chủ đề Giáng sinh\r\ntrang phục đặc biệt\r\nphù hợp trang trí', 450000.00, '0f14f6e3f5bff0be7cb56259a097f13b.jpg', 4, 4, 1, 5.0, 1, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 1, NULL),
	(23, 'Bó hoa len mix ngẫu nhiên tone xanh pastel', 'Shop phối màu ngẫu nhiên nhưng đảm bảo đẹp như hình', 335000.00, 'hoabo.jpg', 3, 11, 0, 5.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(24, 'Hoa bó mix ngẫu nhiên', 'Shop mix ngẫu nhiên như ảnh.', 350000.00, 'prod_69dcad81661ef_1776070017.png', 1, 11, 0, 0.0, 0, 1, 4, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(25, 'Hoa bó mix ngẫu nhiên', 'Shop mix hoa như trong ảnh.', 310000.00, 'prod_69dcadd11494d_1776070097.png', 1, 11, 0, 0.0, 0, 0, 0, 10, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(26, 'Hoa Hồng', '1 cành như mẫu', 20000.00, 'prod_69ddc68b96ca1_1776141963.jpg', 66, 9, 0, 5.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(27, 'Hoa hồng đơn', 'Bán theo cành như ảnh.', 75000.00, 'prod_69e702664c008_1776747110.jpg', 49, 9, 7, 5.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 2, NULL),
	(28, 'Đếm dòng', 'Kim đếm số hàng len\r\n', 2000.00, 'prod_69e6edda09704_1776741850.png', 1022, 3, 0, 5.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(29, 'Kéo cắt len kiểu', '', 33330.00, 'prod_69e6eec20affe_1776742082.png', 33, 3, 0, 5.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(30, 'Thước dây', '', 20000.00, 'prod_69e6ef8807e32_1776742280.png', 56, 3, 0, 5.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(31, 'Mát thú, mắt nhựa', 'Combo 1 hộp', 35000.00, 'prod_69e6f0d5c6f67_1776742613.png', 45, 3, 0, 5.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(32, 'Bông gòn nhồi thú', '', 33333.00, 'prod_69e6f31a0cd3c_1776743194.png', 0, 3, 0, 5.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(33, 'Kẽm - phụ kiện móc hoa len', '50 que, tặng kèm băng keo quấn kẽm', 45555.00, 'prod_69e6f39fd4557_1776743327.jpg', 0, 3, 0, 5.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(34, 'Nhíp nhồi bông', '', 5000.00, 'prod_69e6f4ce73d3b_1776743630.png', 654, 3, 0, 5.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(35, 'Thú treo xe, cặp', '', 45000.00, 'prod_69e6f8ae5ccd3_1776744622.jpg', 85, 15, 3, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 2, NULL),
	(36, 'Hướng dương', 'so beautiful', 25000.00, 'prod_69e7317f1e843_1776759167.png', 56, 15, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 06:38:36', NULL, 0, NULL),
	(39, 'Len sợi Acrylic Paintbox Yarns Simply DK', 'so beautiful ', 30000.00, 'prod_69f30741ba86a_1777534785.jpg', 10, 13, 0, 0.0, 0, 0, 0, 3, 'Bình Định', 5, 'approved', '2026-04-30 07:39:45', NULL, 0, NULL),
	(40, 'Cuộn Len Sợi Microp Polyester 100% 100g', '', 40000.00, 'prod_69f31845ac951_1777539141.jpg', 10, 13, 0, 0.0, 0, 0, 0, 4, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 08:52:21', NULL, 1, NULL),
	(41, 'Sợi Ni lông 70D - Salud Style', '', 60000.00, 'prod_69f318905070f_1777539216.jpg', 5, 12, 0, 5.0, 0, 0, 0, 6, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 08:53:36', NULL, 0, NULL),
	(42, 'len sợi pha', '', 25000.00, 'prod_69f318ae6d5da_1777539246.jpg', 6, 12, 1, 5.0, 0, 0, 0, 3, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 08:54:06', NULL, 0, NULL),
	(43, 'Len Milk Cotton 2mm 50g', '', 15000.00, 'prod_69f318ceaba30_1777539278.jpg', 5, 12, 0, 5.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 5, 'approved', '2026-04-30 08:54:38', NULL, 1, NULL),
	(45, ' lấy trễ hơn giù', 'ss', 65555.00, 'prod_69feee72bc994_1778314866.jpg', 6, 13, 0, 5.0, 0, 0, 0, 2, 'Tp. Hồ Chí Minh', 5, 'rejected', '2026-05-09 08:21:06', 'no', 0, NULL),
	(47, 'Lục Lạc Vòng Gỗ ', 'd', 55555.00, 'prod_6a05503a952d0_1778733114.jpg', 1, 13, 1, 5.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 18, 'rejected', '2026-05-14 03:57:42', 'ko', 0, NULL),
	(50, 'Móc khoá mèo chột len', '', 30000.00, 'prod_6a0d80e3a7da3_1779269859.png', 51, 15, 4, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 11, 'approved', '2026-05-20 09:37:39', NULL, 0, NULL),
	(51, 'FTRB', 'CD', 20000.00, 'prod_6a1131aca5dbb_1779511724.jpg', 2, 14, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 18, 'rejected', '2026-05-23 04:48:44', 'XAU', 0, NULL),
	(52, 'ầ', 'ád', 55555.00, '', 2, 13, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 18, 'rejected', '2026-05-23 04:59:35', 'ko', 0, NULL),
	(53, 'Lục Lạc Vòng ', 'ád', 90000.00, '', 20, 10, 2, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 18, 'rejected', '2026-05-23 05:14:40', '.', 0, NULL),
	(55, 'Bó hoa cưới – Hoa tulip, hoa chuông bằng len handmade', '', 890000.00, 'prod_6a269aa89ba1f_1780914856.jpg', 4, 10, 0, 0.0, 0, 0, 0, 5, 'Tp. Hồ Chí Minh', 18, 'approved', '2026-06-08 10:34:16', NULL, 0, NULL),
	(56, 'Bó hoa len thú viền hoa phối hoa hồng xinh xắn', '', 270000.00, 'prod_6a269bd136f67_1780915153.jpg', 10, 10, 0, 0.0, 0, 0, 0, 4, 'Tp. Hồ Chí Minh', 18, 'approved', '2026-06-08 10:36:12', NULL, 0, NULL),
	(57, 'MÓC KHOÁ CẦU LÔNG BẰNG LEN KÈM HOA BẮP MÀU XINH XẮN', 'Móc khóa cầu lông siêu đáng yêu được móc tay hoàn toàn bằng len cao cấp, kết hợp hình cầu lông và hoa bắp màu pastel nổi bật. Thiết kế tinh tế, màu sắc hài hòa, thích hợp làm quà tặng cho bạn bè, thành viên CLB cầu lông, hoặc đơn giản để trang trí balo, túi xách, chìa khoá thêm phần dễ thương', 40000.00, 'prod_6a269c42d2791_1780915266.png', 10, 15, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 18, 'approved', '2026-06-08 10:41:06', NULL, 0, NULL),
	(58, 'Móc Khoá Hoa Linh Lan – Tinh Tế, Nhỏ Xinh, Treo Túi &amp;amp; Xe Ô Tô Siêu Dễ Thương', '✨Hoa linh lan tượng trưng cho sự thuần khiết, may mắn và hạnh phúc trọn vẹn. Với hình dáng nhỏ nhắn, trong sáng, hoa còn mang thông điệp về tình yêu chân thành và niềm tin vào những điều tốt đẹp.\r\n\r\n✨Móc khoá hoa linh đan là điểm nhấn trang trí hoàn hảo cho xe của bạn, mang đến không gian xanh tươi mới. Sản phẩm được làm thủ công 100% từ len tự nhiên, kích thước phù hợp với nhiều không gian như cửa phòng, quán cafe, phòng làm việc và làm phụ kiện thời trang cho giỏ xách.\r\n\r\n👉 Móc khóa hoa linh lan handmade không chỉ là phụ kiện xinh xắn, mà còn là lá bùa may mắn luôn đồng hành cùng bạn, mang lại năng lượng tích cực và niềm vui trong cuộc sống. ✨', 48000.00, 'prod_6a269da80a244_1780915624.png', 10, 15, 0, 0.0, 0, 0, 0, 3, 'Tp. Hồ Chí Minh', 18, 'approved', '2026-06-08 10:47:04', NULL, 0, NULL),
	(59, 'Gift Box Hộp Quà Hoa Len Handmade 6 Món – Món Quà Ý Nghĩa, Sang Trọng Và Tinh Tế', 'Gift Box Hộp quà hoa len handmade là lựa chọn hoàn hảo dành cho những ai yêu thích sự độc đáo và tinh tế. Mỗi bông hoa được móc thủ công tỉ mỉ, từ sợi len cao cấp, mềm mại và bền đẹp, mang đến vẻ đẹp tự nhiên mà không lo héo úa theo thời gian.\r\n\r\nHộp quà được thiết kế sang trọng, phối màu hài hòa, sẵn sàng để trao tặng mà không cần gói thêm. Đây là món quà ý nghĩa thể hiện sự quan tâm, yêu thương và tinh tế của người tặng.\r\n\r\n🌸 Phù hợp cho nhiều dịp đặc biệt:\r\n\r\nQuà tặng 8/3, 20/10, Valentine, sinh nhật, tốt nghiệp, kỷ niệm ngày yêu\r\n\r\nTặng mẹ, bạn bè, đồng nghiệp, người yêu hoặc thầy cô giáo\r\n\r\nDùng để trang trí góc làm việc, phòng ngủ, mang lại cảm giác dễ chịu và ấm áp\r\n\r\n🎀 Gift Box Hộp quà hoa len handmade không chỉ là một món quà, mà còn là cách gửi gắm yêu thương, sự trân trọng và lời chúc tốt đẹp đến người nhận.', 129000.00, 'prod_6a269e56bd5df_1780915798.png', 10, 8, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 18, 'approved', '2026-06-08 10:49:58', NULL, 0, NULL),
	(60, 'Hoa Thủy Tiên Vàng Handmade – Sắc Hoa May Mắn, Quà Tặng Ngọt Ngào', '🌼 Hoa Thủy Tiên Vàng Handmade – được tạo nên từ từng mũi móc tỉ mỉ, mang sắc vàng rực rỡ như ánh nắng, biểu tượng cho sự may mắn, hạnh phúc và khởi đầu mới. Với vẻ đẹp bền lâu, hoa len này không chỉ là món decor tô điểm bàn học, bàn làm việc thêm tươi sáng, mà còn là quà tặng ý nghĩa gửi gắm lời chúc tốt lành đến người thân, bạn bè.', 70000.00, 'prod_6a269ea720e72_1780915879.jpg', 10, 9, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 18, 'approved', '2026-06-08 10:51:19', NULL, 0, NULL),
	(61, 'Kéo Cắt Len, Chỉ Cao Cấp Có Nắp Đậy – Dụng Cụ Đan Móc Len', 'Kéo cắt được thiết kế nhỏ gọn, tiện lợi, chiếc kéo này là trợ thủ đắc lực cho chị em trong việc cắt len, chỉ, vải hay giấy một cách nhanh gọn, sắc bén. Cán kéo bằng nhựa ABS chắc chắn, lưỡi kim loại cao cấp bền đẹp, kèm nắp đậy an toàn, dễ dàng mang theo hoặc cất giữ. Đây là dụng cụ cần thiết trong mọi bộ đồ nghề đan móc và handmade', 16000.00, 'prod_6a269fafad4dd_1780916143.png', 10, 3, 0, 0.0, 0, 0, 0, 2, 'Tp. Hồ Chí Minh', 18, 'approved', '2026-06-08 10:54:26', NULL, 1, '["prod_6a26a22426ddb_1780916772.png","prod_6a26a224272fc_1780916772.png"]'),
	(62, 'Kim Khâu Len Sợi Inox Không Gỉ – Dụng Cụ Đan Móc Tiện Lợi', 'Kim khâu len sợi inox tiện lợi, an toàn, thích hợp cho người mới học móc len hoặc làm thủ công handmade. Với chất liệu inox, đầu kim trơn nhẵn, dễ xỏ len, giúp bạn khâu ráp chi tiết thú len, búp bê, móc khóa hoặc giấu sợi len thừa gọn gàng.\r\n\r\n👉 Kim khâu len sợi nhỏ gọn, dễ mang theo, là dụng cụ không thể thiếu trong hộp đồ nghề đan móc của bạn.', 10000.00, 'prod_6a26a4d571035_1780917461.jpg', 10, 1, 0, 0.0, 0, 0, 0, 0, 'Tp. Hồ Chí Minh', 18, 'approved', '2026-06-08 11:17:41', NULL, 0, NULL);

-- Dumping structure for table handmade_shop.product_likes
CREATE TABLE IF NOT EXISTS `product_likes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `product_id` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_product` (`user_id`,`product_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.product_likes: ~4 rows (approximately)
INSERT INTO `product_likes` (`id`, `user_id`, `product_id`, `created_at`) VALUES
	(1, 3, 35, '2026-05-23 03:51:11'),
	(2, 5, 35, '2026-05-23 04:45:46'),
	(3, 5, 27, '2026-05-23 04:57:03'),
	(4, 3, 27, '2026-05-31 10:00:13'),
	(6, 18, 61, '2026-06-08 11:20:18');

-- Dumping structure for table handmade_shop.product_reviews
CREATE TABLE IF NOT EXISTS `product_reviews` (
  `id` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `user_id` int NOT NULL,
  `rating` int NOT NULL DEFAULT '5',
  `comment` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `product_user_uq` (`product_id`,`user_id`),
  KEY `fk_review_user` (`user_id`),
  CONSTRAINT `fk_review_product` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_review_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.product_reviews: ~6 rows (approximately)
INSERT INTO `product_reviews` (`id`, `product_id`, `user_id`, `rating`, `comment`, `created_at`) VALUES
	(1, 4, 5, 5, 'ê cái túi dễ thw lắm á mn, đang giá tiền nha!', '2026-04-04 17:02:58'),
	(2, 5, 5, 5, '100k 2 con mua cặp với người iu là hết sẫy lun', '2026-04-04 17:04:12'),
	(3, 22, 5, 5, 'dễ thw nhaaa\r\n', '2026-04-11 15:38:11'),
	(4, 1, 5, 4, 'cũng ok\r\n', '2026-04-13 10:19:52'),
	(5, 8, 7, 5, 'đẹp', '2026-05-13 04:55:30'),
	(6, 8, 18, 1, 'duyệt\r\n', '2026-05-14 04:30:37');

-- Dumping structure for table handmade_shop.product_variants
CREATE TABLE IF NOT EXISTS `product_variants` (
  `id` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `image` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `price` decimal(15,2) DEFAULT '0.00',
  `stock` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `product_variants_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.product_variants: ~13 rows (approximately)
INSERT INTO `product_variants` (`id`, `product_id`, `name`, `image`, `price`, `stock`, `created_at`) VALUES
	(1, 1, 'Bunny', 'luc-lac-vong-go-handmade-do-choi-an-toan-cho-be-4-1.jpg', 0.00, 0, '2026-04-10 12:14:27'),
	(2, 26, 'Hoa hồng trắng', 'prod_69de5b9baa940_1776180123.jpg', 0.00, 0, '2026-04-14 15:22:03'),
	(3, 35, 'Gà', 'prod_69e6f8ae63073_1776744622.png', 45000.00, 63, '2026-04-21 04:10:22'),
	(4, 35, 'Chuột', 'prod_69e6f8ae6466e_1776744622.jpg', 50000.00, 51, '2026-04-21 04:10:22'),
	(5, 35, 'Hoa trắng', 'prod_69e6ff09e586e_1776746249.png', 40000.00, 3, '2026-04-21 04:37:29'),
	(6, 35, 'Hoa vàng', 'prod_69e6ff48cf850_1776746312.png', 40000.00, 6, '2026-04-21 04:38:32'),
	(7, 35, 'Hoa xanh', 'prod_69e6ff9359898_1776746387.png', 40000.00, 6, '2026-04-21 04:39:47'),
	(8, 35, 'Ong', 'prod_69e7007d39dc2_1776746621.jpg', 40000.00, 9, '2026-04-21 04:43:41'),
	(9, 36, 'Vàng nhạt', 'prod_69e7317f283ff_1776759167.png', 25000.00, 9, '2026-04-21 08:12:47'),
	(10, 36, 'Nâu ', 'prod_69e7317f298ec_1776759167.png', 29000.00, 14, '2026-04-21 08:12:47'),
	(15, 50, 'Mèo đen', '', 30000.00, 51, '2026-05-20 09:37:39'),
	(16, 50, 'Mèo trắng', '', 30000.00, 33, '2026-05-20 09:37:39'),
	(17, 50, 'Cả 2', 'prod_6a0d80e3ac894_1779269859.png', 59000.00, 55, '2026-05-20 09:37:39'),
	(20, 56, 'Hồng', 'prod_6a269b1c58626_1780914972.jpg', 0.00, 5, '2026-06-08 10:36:12'),
	(21, 56, 'Vàng', 'prod_6a269bd138495_1780915153.jpg', 0.00, 5, '2026-06-08 10:39:13'),
	(22, 57, 'Cam', 'prod_6a269c42d34e1_1780915266.png', 0.00, 10, '2026-06-08 10:41:06'),
	(23, 57, 'Đỏ', 'prod_6a269c7a54e43_1780915322.png', 0.00, 10, '2026-06-08 10:42:02'),
	(24, 57, 'Xanh', 'prod_6a269c7a55b5b_1780915322.png', 0.00, 10, '2026-06-08 10:42:02'),
	(25, 58, 'Trắng', 'prod_6a269e084d7a6_1780915720.png', 0.00, 10, '2026-06-08 10:48:40'),
	(26, 58, 'Vàng', 'prod_6a269e084e58c_1780915720.png', 0.00, 10, '2026-06-08 10:48:40'),
	(27, 58, 'Tím', 'prod_6a269e084ee85_1780915720.png', 0.00, 10, '2026-06-08 10:48:40');

-- Dumping structure for table handmade_shop.returns
CREATE TABLE IF NOT EXISTS `returns` (
  `id` int NOT NULL AUTO_INCREMENT,
  `order_id` int NOT NULL,
  `user_id` int NOT NULL,
  `reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `amount` decimal(10,2) NOT NULL,
  `status` enum('pending','reviewing','approved','rejected','refunded') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `order_id` (`order_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `returns_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `returns_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.returns: ~3 rows (approximately)
INSERT INTO `returns` (`id`, `order_id`, `user_id`, `reason`, `description`, `amount`, `status`, `created_at`, `updated_at`) VALUES
	(1, 19, 3, 'Sản phẩm khác với mô tả', 'no', 1110000.00, 'refunded', '2026-04-30 08:05:42', '2026-05-18 01:39:06'),
	(2, 28, 3, 'Giao sai sản phẩm', 'no', 59100.00, 'approved', '2026-04-30 08:22:16', '2026-04-30 09:42:31'),
	(3, 27, 3, 'Giao thiếu sản phẩm', 'l', 59100.00, 'approved', '2026-04-30 08:25:25', '2026-05-13 05:33:32');

-- Dumping structure for table handmade_shop.return_history
CREATE TABLE IF NOT EXISTS `return_history` (
  `id` int NOT NULL AUTO_INCREMENT,
  `return_id` int NOT NULL,
  `status` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `return_id` (`return_id`),
  CONSTRAINT `return_history_ibfk_1` FOREIGN KEY (`return_id`) REFERENCES `returns` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.return_history: ~26 rows (approximately)
INSERT INTO `return_history` (`id`, `return_id`, `status`, `note`, `created_at`) VALUES
	(1, 1, 'pending', 'Yêu cầu trả hàng đã được gửi.', '2026-04-30 08:05:42'),
	(2, 1, 'reviewing', '', '2026-04-30 08:12:20'),
	(3, 1, 'approved', '', '2026-04-30 08:18:07'),
	(4, 1, 'rejected', '', '2026-04-30 08:18:18'),
	(5, 1, 'rejected', '', '2026-04-30 08:18:42'),
	(6, 1, 'refunded', '', '2026-04-30 08:18:52'),
	(7, 1, 'rejected', '', '2026-04-30 08:19:08'),
	(8, 1, 'refunded', '', '2026-04-30 08:20:23'),
	(9, 1, 'rejected', '', '2026-04-30 08:20:32'),
	(10, 2, 'pending', 'Yêu cầu trả hàng đã được gửi.', '2026-04-30 08:22:16'),
	(11, 2, 'reviewing', '', '2026-04-30 08:22:30'),
	(12, 2, 'rejected', '', '2026-04-30 08:22:39'),
	(13, 2, 'rejected', 'không thích', '2026-04-30 08:24:43'),
	(14, 3, 'pending', 'Yêu cầu trả hàng đã được gửi.', '2026-04-30 08:25:25'),
	(15, 3, 'reviewing', '', '2026-04-30 08:28:12'),
	(16, 3, 'approved', '', '2026-04-30 08:51:11'),
	(17, 3, 'reviewing', '', '2026-04-30 09:40:34'),
	(18, 2, 'approved', '', '2026-04-30 09:42:31'),
	(19, 3, 'rejected', '', '2026-04-30 09:44:19'),
	(20, 3, 'reviewing', '', '2026-04-30 09:47:30'),
	(21, 3, 'reviewing', '', '2026-05-09 06:29:59'),
	(22, 3, 'reviewing', 'jjj', '2026-05-13 04:50:07'),
	(23, 3, 'rejected', '', '2026-05-13 04:50:22'),
	(24, 3, 'approved', '', '2026-05-13 05:33:32'),
	(25, 3, 'approved', '', '2026-05-13 05:33:33'),
	(26, 1, 'refunded', '', '2026-05-18 01:39:06');

-- Dumping structure for table handmade_shop.return_media
CREATE TABLE IF NOT EXISTS `return_media` (
  `id` int NOT NULL AUTO_INCREMENT,
  `return_id` int NOT NULL,
  `file_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_type` enum('image','video') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `return_id` (`return_id`),
  CONSTRAINT `return_media_ibfk_1` FOREIGN KEY (`return_id`) REFERENCES `returns` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.return_media: ~0 rows (approximately)
INSERT INTO `return_media` (`id`, `return_id`, `file_path`, `file_type`, `created_at`) VALUES
	(1, 1, 'public/uploads/returns/return_1_0_1777536342.jpg', 'image', '2026-04-30 08:05:42');

-- Dumping structure for table handmade_shop.seller_requests
CREATE TABLE IF NOT EXISTS `seller_requests` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `shop_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `shop_description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `product_types` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `identity_proof` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `portfolio_links` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `bank_account` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('pending','approved','rejected') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `reject_reason` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `seller_requests_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.seller_requests: ~3 rows (approximately)
INSERT INTO `seller_requests` (`id`, `user_id`, `shop_name`, `shop_description`, `product_types`, `identity_proof`, `portfolio_links`, `bank_account`, `status`, `reject_reason`, `created_at`) VALUES
	(1, 18, 'Hân Shop', 'hẹ hẹ', 'Đồ lên ', '1778307660_luc-lac-vong-go-handmade-do-choi-an-toan-cho-be-4-1.jpg', 'https://www.facebook.com/falafs', '1028293216 - Vietcombank', 'rejected', 'no', '2026-05-09 06:21:00'),
	(2, 18, 'Han Shop', 'dep', 'Đồ len', '1778313242_istockphoto-1255984577-1024x1024.jpg', 'https://www.facebook.com/falafs', '1028293216 - Vietcombank', 'approved', NULL, '2026-05-09 07:54:02'),
	(3, 18, 'Han Shop', 'hehe', 'Đồ len', '1778313356_istockphoto-1255984577-1024x1024.jpg', '', '1028293216 - Vietcombank', 'approved', NULL, '2026-05-09 07:55:56');

-- Dumping structure for table handmade_shop.seller_wallets
CREATE TABLE IF NOT EXISTS `seller_wallets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `seller_id` int NOT NULL COMMENT 'FK → user.id (role=seller)',
  `balance` decimal(15,2) NOT NULL DEFAULT '0.00' COMMENT 'Số dư hiện tại có thể rút',
  `total_earned` decimal(15,2) NOT NULL DEFAULT '0.00' COMMENT 'Tổng đã kiếm được từ trước tới nay',
  `total_withdrawn` decimal(15,2) NOT NULL DEFAULT '0.00' COMMENT 'Tổng đã rút ra',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_wallet` (`seller_id`),
  CONSTRAINT `fk_wallet_seller` FOREIGN KEY (`seller_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ví điện tử của từng seller';

-- Dumping data for table handmade_shop.seller_wallets: ~3 rows (approximately)
INSERT INTO `seller_wallets` (`id`, `seller_id`, `balance`, `total_earned`, `total_withdrawn`, `created_at`, `updated_at`) VALUES
	(1, 18, 90999.50, 130999.50, 40000.00, '2026-05-18 10:58:23', '2026-05-23 13:17:05'),
	(2, 11, 133200.00, 133200.00, 0.00, '2026-05-20 14:21:39', '2026-05-23 13:17:05'),
	(3, 5, 331190.00, 431190.00, 100000.00, '2026-05-23 12:42:10', '2026-05-23 13:03:12');

-- Dumping structure for table handmade_shop.shops
CREATE TABLE IF NOT EXISTS `shops` (
  `id` int NOT NULL AUTO_INCREMENT,
  `seller_id` int NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `logo` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `banner` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `rating` float DEFAULT '0',
  `status` enum('active','inactive','suspended') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `seller_id` (`seller_id`),
  CONSTRAINT `shops_ibfk_1` FOREIGN KEY (`seller_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.shops: ~3 rows (approximately)
INSERT INTO `shops` (`id`, `seller_id`, `name`, `description`, `logo`, `banner`, `rating`, `status`, `created_at`) VALUES
	(1, 18, 'Han Shoppp', 'Shop bán đồ handmade thủ công mỹ nghệ \r\nMóc Khóa\r\nHoa Len\r\nKim Đan các loại', 'public/uploads/shops/1780917589_logo_OIP.jpg', NULL, 0, 'active', '2026-05-09 07:56:02'),
	(2, 5, 'Nguyễn Lan Phương Shop', 'Cửa hàng chính thức của ban quản trị.', NULL, NULL, 0, 'active', '2026-05-14 04:29:25'),
	(3, 11, 'phuong shop', 'mại zô mại zo', NULL, NULL, 0, 'active', '2026-05-20 09:05:07');

-- Dumping structure for table handmade_shop.shop_followers
CREATE TABLE IF NOT EXISTS `shop_followers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `shop_id` int NOT NULL,
  `user_id` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_shop_user` (`shop_id`,`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.shop_followers: ~2 rows (approximately)
INSERT INTO `shop_followers` (`id`, `shop_id`, `user_id`, `created_at`) VALUES
	(2, 1, 3, '2026-05-14 04:24:59'),
	(9, 2, 3, '2026-05-18 01:26:00');

-- Dumping structure for table handmade_shop.shop_update_requests
CREATE TABLE IF NOT EXISTS `shop_update_requests` (
  `id` int NOT NULL AUTO_INCREMENT,
  `shop_id` int NOT NULL,
  `new_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `new_description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `new_logo` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `new_banner` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('pending','approved','rejected') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `rejection_reason` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `shop_id` (`shop_id`),
  CONSTRAINT `shop_update_requests_ibfk_1` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.shop_update_requests: ~8 rows (approximately)
INSERT INTO `shop_update_requests` (`id`, `shop_id`, `new_name`, `new_description`, `new_logo`, `new_banner`, `status`, `created_at`, `rejection_reason`) VALUES
	(1, 1, 'Han Shop', 'hehe', NULL, NULL, 'approved', '2026-05-13 10:10:56', NULL),
	(2, 1, 'Han Shop', 'hehe', 'public/uploads/shops/1778667100_logo_z7772722283309_3c577827e8f56be8ad43f7b5d04768fb.jpg', NULL, 'approved', '2026-05-13 10:11:40', NULL),
	(3, 1, 'Han Shop', 'hehe', 'public/uploads/shops/1778667100_logo_z7772722283309_3c577827e8f56be8ad43f7b5d04768fb.jpg', NULL, 'approved', '2026-05-14 04:02:27', NULL),
	(4, 1, 'Han Shoppp', 'hehe', 'public/uploads/shops/1778667100_logo_z7772722283309_3c577827e8f56be8ad43f7b5d04768fb.jpg', NULL, 'approved', '2026-05-14 04:37:36', NULL),
	(5, 1, 'Han Shoppp', 'hehehehehehehe\r\n', 'public/uploads/shops/1778667100_logo_z7772722283309_3c577827e8f56be8ad43f7b5d04768fb.jpg', NULL, 'approved', '2026-05-14 04:53:57', NULL),
	(7, 3, 'phuong shop', 'mại zô mại zo', NULL, NULL, 'approved', '2026-05-20 09:21:39', NULL),
	(8, 1, 'Han Shoppp', 'hehehehehehehe\r\n', 'public/uploads/shops/1778667100_logo_z7772722283309_3c577827e8f56be8ad43f7b5d04768fb.jpg', 'public/uploads/shops/1779511629_banner_z7772738474329_ef4e0e7277e6bd740c06d6dcb581410c.jpg', 'rejected', '2026-05-23 04:47:09', NULL),
	(12, 1, 'Han Shoppp', 'Shop bán đồ handmade thủ công mỹ nghệ \r\nMóc Khóa\r\nHoa Len\r\nKim Đan các loại', 'public/uploads/shops/1780917589_logo_OIP.jpg', NULL, 'approved', '2026-06-08 11:19:49', NULL);

-- Dumping structure for table handmade_shop.user
CREATE TABLE IF NOT EXISTS `user` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `gender` enum('nam','nu','khac') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'khac',
  `dob` date DEFAULT NULL,
  `role` enum('user','seller','admin') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'user',
  `bank_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_account` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `avatar` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.user: ~11 rows (approximately)
INSERT INTO `user` (`id`, `name`, `username`, `email`, `password`, `phone`, `address`, `gender`, `dob`, `role`, `bank_name`, `bank_account`, `avatar`) VALUES
	(3, 'Chu Hoàng Khánh Hân', 'hankhanh0901@gmail.com', 'hankhanh0901@gmail.com', '$2y$10$I2jEvFCw70Z.fcFeqEPp4.tcafRIc8RiB97l38OAJoiXsyfZwUNFS', '0964325348', '', 'nam', '2004-01-09', 'admin', NULL, NULL, 'avatar_3_1776425351.jpg'),
	(5, 'Nguyễn Lan Phương', 'nguyenphuong2005b@gmail.com', 'nguyenphuong2005b@gmail.com', '$2y$10$NI81lET7vgHTCOZJ9F.EIOB92AyqaGO8pCJ69vSj4AxpDDCqL3WyO', '0382613031', '', 'nu', '2005-03-13', 'admin', NULL, NULL, 'avatar_5_1779254574.jpg'),
	(6, 'Han Khanh', 'hankhanh9124@gmail.com', 'hankhanh9124@gmail.com', '$2y$10$FP0QGWo4vzba.zMHwhq6FeWcKz4tf7b9hjtvQ3m9e2WAcSjFT.IBS', '0964325344', NULL, 'khac', NULL, 'seller', NULL, NULL, NULL),
	(7, 'Khánh Hân', 'hankhanh', NULL, '$2y$10$seVNssVMurk2j045nNcjyOPtJ1jptOQSmN61F6JQzm58NIaKA/Auq', '0964325331', '', 'nam', '2004-01-09', 'user', NULL, NULL, 'avatar_7_1778650063.jpg'),
	(8, 'Hân', 'hankhanh09012004@gmail.com', 'hankhanh09012004@gmail.com', '$2y$10$seVNssVMurk2j045nNcjyOPtJ1jptOQSmN61F6JQzm58NIaKA/Auq', '0964325331', '60/49 Phan Chu Trinh , 24817, 673, 68', 'khac', NULL, 'user', NULL, NULL, NULL),
	(9, 'Hânn', 'hankhanh090124@gmail.com', 'hankhanh090124@gmail.com', '$2y$10$vK3jN/KwQ4HjrjXaMztQB.jpj4RYL.pKhnyCRKpjV.VHDkfjWGKZq', '0964325344', '34 Tân Lập 1 hiệp phú thủ đức , 26845, 769, 79', 'khac', NULL, 'seller', NULL, NULL, NULL),
	(11, 'Nguyễn Huỳnh Minh Thư', NULL, 'minhthu@gmail.com', '$2y$10$u9mTY9j4l6gxze73e3gtnu9GSB4tBZ9gZbcG2Ze9jvfiTbwJmLRe.', NULL, '', 'khac', NULL, 'seller', NULL, NULL, 'avatar_11_1775830653.jpg'),
	(14, 'Chu Hoàng Khánh Hân', NULL, '', '$2y$10$I2jEvFCw70Z.fcFeqEPp4.tcafRIc8RiB97l38OAJoiXsyfZwUNFS', '0964325348', '34 Tân lập 1, Phường Tăng Nhơn Phú B, Thành phố Thủ Đức, Thành phố Hồ Chí Minh', 'khac', NULL, 'user', NULL, NULL, NULL),
	(16, 'Nguyen Van A', NULL, 'vana@gmail.com', '$2y$10$O3ohZ3kYMbGvAQJChl9ki.OVu5fZLvyDbP2JjIqbs0KQyt9DYoi2i', NULL, '', 'khac', NULL, 'user', NULL, NULL, NULL),
	(18, 'Han Khanh', NULL, NULL, '$2y$10$O7G6x09oqk2RR0VFwjmuNuObK2vCBLs8LY2w4ZpbuN6dr/rayFhLy', '0964325321', '', 'khac', NULL, 'seller', NULL, NULL, NULL),
	(20, 'phuong', NULL, 'phuong@gmail.com', '$2y$10$NUgg8WdXbT3lZcolECY7BuozyR31YxWHogjW3QfbO3.fHChPjUj52', NULL, '', 'khac', NULL, 'user', NULL, NULL, NULL);

-- Dumping structure for table handmade_shop.wallet_transactions
CREATE TABLE IF NOT EXISTS `wallet_transactions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `transaction_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Mã giao dịch duy nhất VD: TXN-20240518-00001',
  `wallet_id` int NOT NULL COMMENT 'FK → seller_wallets.id',
  `seller_id` int NOT NULL COMMENT 'FK → user.id',
  `order_id` int DEFAULT NULL COMMENT 'FK → orders.id',
  `order_detail_id` int DEFAULT NULL COMMENT 'FK → order_detail.id (NULL nếu là rút tiền)',
  `type` enum('commission','withdrawal','refund','adjustment') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Loại giao dịch',
  `gross_amount` decimal(12,2) NOT NULL DEFAULT '0.00' COMMENT 'Tổng giá trị mặt hàng (trước khi trừ phí)',
  `commission_percent` decimal(5,2) NOT NULL DEFAULT '10.00' COMMENT 'Tỷ lệ hoa hồng áp dụng',
  `admin_fee` decimal(12,2) NOT NULL DEFAULT '0.00' COMMENT 'Số tiền admin nhận',
  `amount` decimal(12,2) NOT NULL COMMENT 'Số tiền thực tế seller nhận/rút',
  `balance_before` decimal(12,2) NOT NULL DEFAULT '0.00' COMMENT 'Số dư ví trước giao dịch',
  `balance_after` decimal(12,2) NOT NULL DEFAULT '0.00' COMMENT 'Số dư ví sau giao dịch',
  `note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Ghi chú thêm',
  `status` enum('pending','completed','failed','refunded') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'completed',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_txn_code` (`transaction_code`),
  KEY `idx_txn_seller` (`seller_id`),
  KEY `idx_txn_order` (`order_id`),
  KEY `idx_txn_order_detail` (`order_detail_id`),
  KEY `idx_txn_created` (`created_at`),
  KEY `fk_txn_wallet` (`wallet_id`),
  CONSTRAINT `fk_txn_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_txn_order_detail` FOREIGN KEY (`order_detail_id`) REFERENCES `order_detail` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_txn_seller` FOREIGN KEY (`seller_id`) REFERENCES `user` (`id`),
  CONSTRAINT `fk_txn_wallet` FOREIGN KEY (`wallet_id`) REFERENCES `seller_wallets` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Lịch sử giao dịch chi tiết của ví seller';

-- Dumping data for table handmade_shop.wallet_transactions: ~9 rows (approximately)
INSERT INTO `wallet_transactions` (`id`, `transaction_code`, `wallet_id`, `seller_id`, `order_id`, `order_detail_id`, `type`, `gross_amount`, `commission_percent`, `admin_fee`, `amount`, `balance_before`, `balance_after`, `note`, `status`, `created_at`) VALUES
	(1, 'TXN-20260518-95388-40', 1, 18, 35, 40, 'commission', 55555.00, 10.00, 5555.50, 49999.50, 0.00, 49999.50, 'Nhận tiền từ sản phẩm #47 (đơn hàng #35)', 'completed', '2026-05-18 11:07:51'),
	(2, 'TXN-20260520-92816-42', 2, 11, 37, 42, 'commission', 30000.00, 10.00, 3000.00, 27000.00, 0.00, 27000.00, 'Nhận tiền từ sản phẩm #50 (đơn hàng #37)', 'completed', '2026-05-20 17:08:23'),
	(3, 'TXN-20260523-34621-W1', 1, 18, NULL, NULL, 'withdrawal', 0.00, 10.00, 0.00, -40000.00, 49999.50, 9999.50, 'Rút tiền về tài khoản ngân hàng #WDR-20260523-66600-18', 'completed', '2026-05-23 12:12:35'),
	(4, 'TXN-20260523-21708-43', 3, 5, 38, 43, 'commission', 375000.00, 10.00, 37500.00, 337500.00, 0.00, 337500.00, 'Nhận tiền từ sản phẩm #27 (đơn hàng #38)', 'completed', '2026-05-23 12:42:10'),
	(5, 'TXN-20260523-92032-32', 3, 5, 29, 32, 'commission', 29100.00, 10.00, 2910.00, 26190.00, 337500.00, 363690.00, 'Nhận tiền từ sản phẩm #39 (đơn hàng #29)', 'completed', '2026-05-23 12:43:40'),
	(6, 'TXN-20260523-59674-44', 3, 5, 39, 44, 'commission', 75000.00, 10.00, 7500.00, 67500.00, 363690.00, 431190.00, 'Nhận tiền từ sản phẩm #27 (đơn hàng #39)', 'completed', '2026-05-23 12:43:46'),
	(7, 'TXN-20260523-46081-W2', 3, 5, NULL, NULL, 'withdrawal', 0.00, 10.00, 0.00, -100000.00, 431190.00, 331190.00, 'Rút tiền về tài khoản ngân hàng #WDR-20260523-21753-5', 'completed', '2026-05-23 13:03:12'),
	(8, 'TXN-20260523-57623-45', 2, 11, 40, 45, 'commission', 118000.00, 10.00, 11800.00, 106200.00, 27000.00, 133200.00, 'Nhận tiền từ sản phẩm #50 (đơn hàng #40)', 'completed', '2026-05-23 13:17:05'),
	(9, 'TXN-20260523-86812-46', 1, 18, 40, 46, 'commission', 90000.00, 10.00, 9000.00, 81000.00, 9999.50, 90999.50, 'Nhận tiền từ sản phẩm #53 (đơn hàng #40)', 'completed', '2026-05-23 13:17:05');

-- Dumping structure for table handmade_shop.wishlist
CREATE TABLE IF NOT EXISTS `wishlist` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `product_id` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_product_unique` (`user_id`,`product_id`),
  KEY `wishlist_product_fk` (`product_id`),
  CONSTRAINT `wishlist_product_fk` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE,
  CONSTRAINT `wishlist_user_fk` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table handmade_shop.wishlist: ~18 rows (approximately)
INSERT INTO `wishlist` (`id`, `user_id`, `product_id`, `created_at`) VALUES
	(2, 6, 39, '2026-05-09 06:08:02'),
	(4, 6, 27, '2026-05-09 06:08:07'),
	(5, 6, 26, '2026-05-09 06:08:08'),
	(6, 6, 7, '2026-05-09 06:08:09'),
	(7, 6, 8, '2026-05-09 06:08:10'),
	(8, 6, 35, '2026-05-09 06:08:11'),
	(10, 18, 22, '2026-05-09 06:26:08'),
	(11, 18, 43, '2026-05-09 06:26:11'),
	(14, 18, 13, '2026-05-09 06:27:07'),
	(15, 18, 12, '2026-05-09 06:27:09'),
	(27, 18, 16, '2026-05-09 06:44:09'),
	(29, 18, 27, '2026-05-09 06:44:15'),
	(30, 18, 15, '2026-05-09 06:44:16'),
	(31, 18, 14, '2026-05-09 06:44:16'),
	(32, 18, 11, '2026-05-09 06:44:17'),
	(33, 18, 10, '2026-05-09 06:44:18'),
	(34, 3, 27, '2026-05-09 06:46:03'),
	(35, 3, 34, '2026-05-09 06:46:09');

-- Dumping structure for table handmade_shop.withdrawal_requests
CREATE TABLE IF NOT EXISTS `withdrawal_requests` (
  `id` int NOT NULL AUTO_INCREMENT,
  `request_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Mã yêu cầu VD: WDR-20240518-00001',
  `seller_id` int NOT NULL COMMENT 'FK → user.id',
  `wallet_id` int NOT NULL COMMENT 'FK → seller_wallets.id',
  `amount` decimal(12,2) NOT NULL COMMENT 'Số tiền muốn rút',
  `bank_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Tên ngân hàng',
  `bank_account` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Số tài khoản ngân hàng',
  `bank_owner` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Tên chủ tài khoản',
  `status` enum('pending','approved','rejected','processing','completed') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `admin_note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Ghi chú của admin khi xử lý',
  `processed_at` datetime DEFAULT NULL COMMENT 'Thời điểm admin xử lý',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_wdr_code` (`request_code`),
  KEY `idx_wdr_seller` (`seller_id`),
  KEY `idx_wdr_status` (`status`),
  KEY `fk_wdr_wallet` (`wallet_id`),
  CONSTRAINT `fk_wdr_seller` FOREIGN KEY (`seller_id`) REFERENCES `user` (`id`),
  CONSTRAINT `fk_wdr_wallet` FOREIGN KEY (`wallet_id`) REFERENCES `seller_wallets` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Yêu cầu rút tiền từ ví của seller';

-- Dumping data for table handmade_shop.withdrawal_requests: ~0 rows (approximately)
INSERT INTO `withdrawal_requests` (`id`, `request_code`, `seller_id`, `wallet_id`, `amount`, `bank_name`, `bank_account`, `bank_owner`, `status`, `admin_note`, `processed_at`, `created_at`, `updated_at`) VALUES
	(1, 'WDR-20260523-66600-18', 18, 1, 40000.00, 'Vietcombank', '222222', 'NMH', 'completed', NULL, '2026-05-23 12:12:35', '2026-05-23 12:12:35', '2026-05-23 12:12:35'),
	(2, 'WDR-20260523-21753-5', 5, 3, 100000.00, 'Techcombank', '555555', 'GDG', 'completed', NULL, '2026-05-23 13:03:12', '2026-05-23 13:03:12', '2026-05-23 13:03:12');

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;pataware_dbmysqlmysql