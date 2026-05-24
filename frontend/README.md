# Football Booking Frontend - Ứng Dụng Đặt Sân Bóng Đá

Frontend của hệ thống đặt sân bóng đá được xây dựng bằng Flutter, cung cấp trải nghiệm đa nền tảng (Android, iOS, Web) mượt mà cho người dùng và chủ sân.

## 🛠 Công Nghệ Sử Dụng

*   **Framework:** Flutter 3.x
*   **Ngôn ngữ:** Dart
*   **Bản đồ:** Google Maps Flutter
*   **Vị trí:** Geolocator & Geocoding
*   **Thông báo:** Firebase Cloud Messaging (FCM) & Local Notifications
*   **Lưu trữ cục bộ:** Shared Preferences
*   **Network:** HTTP package

## ✨ Tính Năng Chính

### 📱 Dành cho Người Đặt Sân
*   **Đăng nhập/Đăng ký:** Hỗ trợ đăng nhập truyền thống và Google Sign-In.
*   **Tìm kiếm & Bản đồ:** Xem danh sách sân hoặc tìm kiếm trên bản đồ Google Maps.
*   **Đặt sân:** Quy trình đặt sân trực quan, chọn ngày giờ và quản lý lịch đặt.
*   **Yêu thích:** Lưu danh sách các sân bóng yêu thích để truy cập nhanh.
*   **Thông báo:** Nhận thông báo thời gian thực về trạng thái đơn đặt sân.

### 🏠 Dành cho Chủ Sân
*   **Quản lý sân bóng:** Chỉnh sửa thông tin, giá cả và hình ảnh sân.
*   **Quản lý yêu cầu:** Theo dõi và duyệt các yêu cầu đặt sân từ khách hàng.
*   **Hồ sơ cá nhân:** Quản lý thông tin tài khoản và cài đặt.

## 📋 Yêu Cầu Hệ Thống

*   Flutter SDK (^3.7.0)
*   Android Studio / VS Code đã cài đặt Flutter extension
*   Google Maps API Key (được cấu hình trong AndroidManifest.xml và AppDelegate.swift)
*   File `google-services.json` (Android) và `GoogleService-Info.plist` (iOS) từ Firebase.

## 🚀 Hướng Dẫn Cài Đặt

1.  **Cài đặt phụ thuộc:**
    ```bash
    flutter pub get
    ```

2.  **Cấu hình API:**
    *   Mở file `lib/services/api_service.dart` (hoặc file cấu hình tương đương) và cập nhật `baseUrl` trỏ đến Backend của bạn.

3.  **Chạy ứng dụng:**
    ```bash
    flutter run
    ```

## 📁 Cấu Trúc Thư Mục

*   `lib/models/`: Định nghĩa cấu trúc dữ liệu (Data models).
*   `lib/screens/`: Chứa các màn hình UI (Login, Home, Booking, Profile...).
*   `lib/services/`: Xử lý logic gọi API và các dịch vụ bên ngoài.
*   `lib/assets/`: Chứa hình ảnh, icons và tài nguyên tĩnh.

---
Football Booking Flutter - Kết nối niềm đam mê bóng đá!
