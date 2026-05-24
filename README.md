# ⚽ Football Booking System - Hệ Thống Đặt Sân Bóng Đá Toàn Diện

Dự án Football Booking là một giải pháp quản lý và đặt sân bóng đá hiện đại, bao gồm giải pháp Backend mạnh mẽ và ứng dụng Frontend di động đa nền tảng. Hệ thống được thiết kế để tối ưu hóa quy trình đặt sân cho người dùng và quản lý kinh doanh cho chủ sân.

## 🏗 Cấu Trúc Dự Án (Monorepo)

Dự án được tổ chức theo cấu trúc monorepo để dễ dàng quản lý đồng bộ giữa Backend và Frontend:

```text
football_booking/
├── backend/       # Mã nguồn Spring Boot (Java)
├── frontend/      # Mã nguồn Flutter (Dart)
└── README.md      # Tài liệu hướng dẫn tổng quát
```

| Thành phần | Công nghệ chính | Link chi tiết |
| :--- | :--- | :--- |
| **Backend** | Spring Boot 3, Java 17, PostgreSQL, Security, JWT | [Xem chi tiết](./backend/README.md) |
| **Frontend** | Flutter 3, Dart, Google Maps, Firebase FCM | [Xem chi tiết](./frontend/README.md) |

## 🌟 Tính Năng Nổi Bật

### 📱 Đối với Người Dùng (Mobile App)
*   **Tìm kiếm thông minh:** Tìm sân theo vị trí (Google Maps), giá cả và tiện ích.
*   **Đặt sân thời gian thực:** Xem lịch sân trống và đặt chỗ ngay lập tức.
*   **Thông báo đẩy:** Nhận cập nhật trạng tái đơn hàng qua Firebase Cloud Messaging.
*   **Đánh giá & Yêu thích:** Lưu sân bóng quan tâm và để lại phản hồi sau trận đấu.

### 🏟 Đối với Chủ Sân & Quản Trị Viên
*   **Quản lý sân bóng:** Cập nhật thông tin, hình ảnh và quản lý khung giờ hoạt động linh hoạt.
*   **Quản lý đặt sân:** Duyệt và theo dõi các đơn đặt sân tập trung.
*   **Xác thực nâng cao:** Tích hợp Google OAuth2 cho người dùng và chủ sân.

## 🚀 Hướng Dẫn Khởi Động Nhanh

### 1. Yêu cầu hệ thống
*   **Java 17** & **Maven**
*   **Flutter SDK** (mới nhất)
*   **PostgreSQL** (Database)

### 2. Thiết lập Backend
```bash
cd backend
# Cấu hình file application.properties với DB của bạn
mvn clean install
mvn spring-boot:run
```

### 3. Thiết lập Frontend
```bash
cd frontend
flutter pub get
# Đảm bảo đã thiết lập Google Maps API Key
flutter run
```

## 🛠 Sơ Đồ Công Nghệ
- **Backend:** Spring Data JPA, Spring Security, JWT, Swagger (OpenAPI), Firebase Admin SDK.
- **Frontend:** Provider/Bloc pattern, Google Maps, Firebase Core, HTTP Client.
- **Deployment:** Hỗ trợ Docker (tùy chọn), Railway, Render.

## 📄 License
Dự án được phát triển dưới mục đích học tập và xây dựng giải pháp thực tế.

---
© 2026 Football Booking Team. Kết nối niềm đam mê sân cỏ!

