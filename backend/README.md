# ⚙️ Football Booking Backend

Hệ thống API cốt lõi cho dịch vụ đặt sân bóng đá, được xây dựng trên nền tảng **Spring Boot 3**. Backend cung cấp khả năng xử lý nghiệp vụ mạnh mẽ, quản lý bảo mật và tích hợp các dịch vụ bên thứ ba như Firebase và Google.

## 🚀 Công Nghệ Sử Dụng

- **Ngôn ngữ:** Java 17
- **Framework:** Spring Boot 3.4.x
- **Bảo mật:** Spring Security, Spring Session, JWT (JSON Web Token)
- **Cơ sở dữ liệu:** PostgreSQL (ORM: Spring Data JPA)
- **Tài liệu:** Swagger UI (OpenAPI 3.0)
- **Dịch vụ:** Firebase Cloud Messaging (FCM), Google OAuth2

## ✨ Tính Năng Chính

- **Xác thực & Phân quyền:**
  - Hỗ trợ đăng nhập truyền thống (Email/Password) và Google Login.
  - Phân quyền người dùng chi tiết: `ROLE_USER`, `ROLE_OWNER`, `ROLE_ADMIN`.
- **Quản lý Sân bóng (Core API):**
  - Quản lý danh sách sân, khung giờ (time slots) và giá cả.
  - Tìm kiếm sân bóng nâng cao với bộ lọc.
- **Quy trình Đặt sân:**
  - Xử lý đặt chỗ, ngăn chặn trùng lặp khung giờ.
  - Quản lý trạng thái đơn hàng (Pending, Confirmed, Cancelled).
- **Hệ thống Thông báo:**
  - Tích hợp thông báo thời gian thực khi trạng thái đặt sân thay đổi.
- **Tương tác:**
  - Đánh giá sân bóng (Ratings & Reviews).
  - Quản lý danh sách sân yêu thích cho người dùng.

## 📋 Yêu Cầu Cài Đặt

- **JDK 17** hoặc mới hơn.
- **Maven 3.8+**.
- **PostgreSQL 14+**.

## 🛠 Hướng dẫn Cấu hình

### 1. Database
Tạo database PostgreSQL và cập nhật cấu hình trong `src/main/resources/application.properties`:
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/football_booking
spring.datasource.username=your_username
spring.datasource.password=your_password
```

### 2. Firebase (Dành cho Thông báo)
Bạn cần file `firebase-service-account.json`. 
- Đặt file này vào: `src/main/resources/`
- *Lưu ý: File này đã được thêm vào `.gitignore` để bảo mật.*

### 3. JWT & Bảo mật
Cấu hình các tham số JWT trong `application.properties`:
```properties
jwt.secret=your_super_secret_key_here
jwt.expiration=86400000
```

## 🏗 Build và Chạy

Sử dụng Maven để khởi động dự án:
```bash
mvn clean install
mvn spring-boot:run
```

API sẽ mặc định chạy tại: `http://localhost:8081` (hoặc 8080 tùy cấu hình).

## 📍 Tài Liệu API (Swagger)

Sau khi ứng dụng chạy, truy cập tài liệu API chi tiết tại:
`http://localhost:8080/swagger-ui/index.html`

## 📁 Cấu Trúc Mã Nguồn

```text
src/main/java/vn/football_booking/
├── config/        # Cấu hình Security, Swagger, Firebase
├── controller/    # REST Endpoints
├── dto/           # Data Transfer Objects
├── entity/        # Database Models (JPA Entities)
├── repository/    # Spring Data JPA Repositories
├── service/       # Business Logic
└── security/      # JWT & Security Implementation
```

---
Phát triển với ❤️ bởi Football Booking Team.
