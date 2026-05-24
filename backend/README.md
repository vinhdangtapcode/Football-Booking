# Football Booking Backend - API Dịch Vụ Đặt Sân Bóng Đá

Backend của hệ thống đặt sân bóng đá được xây dựng trên nền tảng Spring Boot, cung cấp các dịch vụ quản lý sân, đặt chỗ, xác thực và thông báo.

## 🛠 Công Nghệ Sử Dụng

*   **Ngôn ngữ:** Java 17
*   **Framework:** Spring Boot 3.4.5
*   **Bảo mật:** Spring Security & JSON Web Token (JWT)
*   **Cơ sở dữ liệu:** PostgreSQL (Hỗ trợ cấu hình linh hoạt)
*   **Quản lý phụ thuộc:** Maven
*   **Tài liệu API:** SpringDoc OpenAPI (Swagger)
*   **Tích hợp:** Firebase Admin SDK (Thông báo), Google OAuth2

## ✨ Tính Năng Chính

*   **Xác thực & Phân quyền:**
    *   Đăng ký/Đăng nhập với JWT.
    *   Tích hợp đăng nhập bằng Google.
    *   Phân quyền người dùng: USER, OWNER, ADMIN.
*   **Quản lý Sân bóng:**
    *   CRUD thông tin sân, hình ảnh, giá cả.
    *   Quản lý khung giờ (slots).
*   **Hệ thống Đặt sân:**
    *   Xử lý logic đặt sân, kiểm tra trùng lặp.
    *   Quản lý trạng thái đơn đặt.
*   **Tương tác Người dùng:**
    *   Quản lý danh sách sân yêu thích.
    *   Đánh giá và bình luận về sân bóng.
*   **Thông báo:**
    *   Gửi thông báo đẩy (Push Notifications) qua Firebase Cloud Messaging.

## 📋 Yêu Cầu Hệ Thống

*   Java JDK 17
*   Maven 3.8+
*   PostgreSQL 14+

## 🚀 Cài Đặt và Chạy

1.  **Cấu hình Cơ sở dữ liệu:**
    Tạo một database PostgreSQL và cập nhật thông tin trong `src/main/resources/application.properties`:
    ```properties
    spring.datasource.url=jdbc:postgresql://localhost:5432/football_booking
    spring.datasource.username=your_username
    spring.datasource.password=your_password
    ```

2.  **Cấu hình JWT & Firebase:**
    *   Thiết lập `jwt.secret` trong file cấu hình.
    *   Thêm file `firebase-service-account.json` vào thư mục `src/main/resources/` (nếu sử dụng thông báo).

3.  **Build và Chạy:**
    ```bash
    mvn clean install
    mvn spring-boot:run
    ```

## 📍 Tài Liệu API

Sau khi khởi chạy, bạn có thể truy cập Swagger UI để xem tài liệu API chi tiết tại:
`http://localhost:8080/swagger-ui/index.html`

## 📁 Cấu Trúc Thư Mục

*   `src/main/java/vn/footballfield/`: Chứa mã nguồn chính (Controller, Service, Repository, Entity, DTO).
*   `src/main/resources/`: Chứa file cấu hình và tài nguyên tĩnh.

---
Phát triển bởi đội ngũ dự án Football Booking.
