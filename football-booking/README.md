# Hệ Thống Đặt Sân Bóng Đá

Một ứng dụng Spring Boot để quản lý việc đặt sân bóng đá, xác thực người dùng và các chức năng liên quan.

## Tính Năng
- Đăng ký và đăng nhập người dùng (dựa trên JWT)
- Đặt sân bóng đá
- Quản lý danh sách yêu thích và đánh giá
- Quản lý chủ sân và quản trị viên
- Xem lịch sử đặt sân

## Công Nghệ Sử Dụng
- Java 17 trở lên
- Spring Boot
- Spring Security (JWT)
- Maven
- JPA/Hibernate
- MySQL (hoặc hệ quản trị cơ sở dữ liệu khác)

## Bắt Đầu

### Yêu Cầu
- Java 17 hoặc cao hơn
- Maven
- MySQL (hoặc cập nhật datasource trong `application.properties`)

### Cài Đặt
1. **Clone repository:**
   ```bash
   git clone <repository-url>
   cd football-booking
   ```
2. **Cấu hình cơ sở dữ liệu:**
   - Cập nhật `src/main/resources/application.properties` với thông tin DB và JWT secret của bạn.
3. **Build project:**
   ```bash
   mvn clean install
   ```
4. **Chạy ứng dụng:**
   ```bash
   mvn spring-boot:run
   ```

### Các API chính
- Xác thực: `/api/auth/login`, `/api/auth/register`
- Đặt sân: `/api/bookings`
- Quản lý sân: `/api/fields`
- Yêu thích: `/api/favorites`
- Đánh giá: `/api/ratings`

(Xem các lớp controller để biết chi tiết đầy đủ.)

## Cấu Hình
- `application.properties` chứa tất cả các thiết lập riêng cho môi trường.
- JWT secret và thời gian hết hạn phải được thiết lập để xác thực hoạt động.

## Giấy Phép
Dự án này chỉ dành cho mục đích giáo dục.
