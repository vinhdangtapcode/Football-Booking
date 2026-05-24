# Hệ Thống Đặt Sân Bóng Đá (Frontend)
Ứng dụng Flutter cho phép người dùng đặt sân bóng đá, quản lý sân và trải nghiệm dịch vụ thuê sân bóng trực tuyến dễ dàng, kết nối với backend Spring Boot.

Link backend: [Backend](https://github.com/vinhdangtapcode/FootballBooking)

## Tính Năng
- Đăng ký và đăng nhập người dùng (tích hợp với backend qua JWT)
- Với người dùng (Người đặt sân):
  + Đặt sân bóng đá
  + Tìm kiếm sân
  + Thêm sân yêu thích
  + Xem lịch sử đặt sân
  + Quản lý thông báo
  + Thay đổi thông tin cá nhân
- Với chủ sân (Người cho thuê sân):
  + Quản lý sân cho thuê (Thêm, sửa, xóa)
  + Xem lịch sử các yêu cầu đặt sân từ người dùng
  + Quản lý thông báo
  + Thay đổi thông tin cá nhân

## Công Nghệ Sử Dụng
- Flutter (Dart)
- Kết nối RESTful API (Spring Boot Backend)
- Hỗ trợ đa nền tảng: Android, iOS, Web

## Cấu Trúc Dự Án
```
lib/
  main.dart                # Điểm khởi đầu ứng dụng
  models/                  # Định nghĩa các model: booking, favorite, field, rating, user
  screens/                 # Các màn hình giao diện: đăng nhập, đăng ký, đặt sân, lịch sử, chủ sân, v.v.
  services/                # Các dịch vụ gọi API backend
```

## Yêu Cầu Cài Đặt
- Flutter SDK
- Thiết bị Android thật hoặc giả lập đã bật debugging 
- Đã có backend Spring Boot hoạt động

## Cài Đặt
1. **Cài đặt Flutter SDK:** https://docs.flutter.dev/get-started/install
2. **Clone repository:**
   ```bash
   git clone https://github.com/your-repo/football_booking_flutter.git
   ```
3. **Cài đặt dependencies:**
   ```bash
   flutter pub get
   ```
4. **Cấu hình endpoint backend:**
   - Cập nhật URL backend trong file api_service.dart 
5. **Chạy ứng dụng:**
   ```bash
   flutter run
   ```

## Liên Kết API Chính Với Backend
- Xác thực: `/api/auth/login`, `/api/auth/register`
- Đặt sân: `/api/bookings`
- Quản lý sân: `/api/fields`
- Yêu thích: `/api/favorites`
- Đánh giá: `/api/ratings`

---
Football Booking Flutter - Đặt sân bóng dễ dàng, nhanh chóng và tiện lợi!
