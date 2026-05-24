# 📱 Football Booking Frontend

Ứng dụng di động dành cho hệ thống đặt sân bóng đá, được xây dựng bằng **Flutter**. Ứng dụng cung cấp trải nghiệm mượt mà cho cả người đi thuê sân và chủ sân trên cả hai nền tảng Android và iOS.

## 🚀 Công Nghệ Sử Dụng

- **Framework:** Flutter 3.x
- **Ngôn ngữ:** Dart
- **Quản lý trạng thái:** Provider / Bloc
- **Bản đồ:** Google Maps Flutter
- **Thông báo:** Firebase Cloud Messaging & Local Notifications
- **Network:** HTTP Client (Xử lý REST API)
- **Tiện ích:** Geolocator, Image Picker, Shared Preferences

## ✨ Tính Năng Chính

### 🙋 Dành cho Người Thuê Sân
- **Bản đồ Sân bóng:** Tìm kiếm và xem vị trí các sân bóng xung quanh qua Google Maps.
- **Đặt sân nhanh:** Chọn ngày, khung giờ và xác nhận đặt sân trong vài thao tác.
- **Lịch sử & Trạng thái:** Theo dõi các đơn đặt sân đã thực hiện và trạng thái hiện tại.
- **Cá nhân hóa:** Quản lý sân bóng yêu thích và thông tin cá nhân.

### 🏟 Dành cho Chủ Sân
- **Bảng điều khiển:** Xem danh sách các yêu cầu đặt sân mới.
- **Quản lý Sân:** Cập nhật thông tin chi tiết, giá cả và hình ảnh sân bóng.
- **Thông báo:** Nhận thông báo tức thì khi có khách hàng đặt sân mới.

## 📋 Yêu Cầu Cài Đặt

- **Flutter SDK:** ^3.10.0
- **Dart SDK:** ^3.0.0
- **Công cụ:** Android Studio / VS Code (với Flutter Extension)
- **Tài khoản Firebase:** Để cấu hình thông báo và Google Sign-In.

## 🛠 Hướng Dẫn Cấu Hình

### 1. Phụ thuộc
Chạy lệnh sau để tải các gói thư viện:
```bash
flutter pub get
```

### 2. Cấu hình Firebase
- Tải file `google-services.json` (Android) và `GoogleService-Info.plist` (iOS) từ console Firebase.
- Đặt `google-services.json` vào `android/app/`.
- Thêm `GoogleService-Info.plist` vào `ios/Runner/` qua Xcode.

### 3. Google Maps API
- Lấy API Key từ Google Cloud Console.
- Cấu hình Key trong `AndroidManifest.xml` (Android) và `AppDelegate.swift` (iOS).

### 4. Kết nối Backend
Cập nhật `baseUrl` trong file cấu hình dịch vụ API (ví dụ: `lib/services/api_service.dart`) để trỏ đến địa chỉ Backend của bạn.

## 🏗 Chạy Ứng Dụng

```bash
# Chạy ở chế độ Debug
flutter run

# Build APK (Android)
flutter build apk --release
```

## 📁 Cấu Trúc Mã Nguồn

```text
lib/
├── assets/      # Hình ảnh, Fonts, Icons
├── models/      # Lớp dữ liệu (POJO/Entities)
├── screens/     # Giao diện người dùng (UI Screens)
├── services/    # Xử lý API và Logic nghiệp vụ
├── widgets/     # Các thành phần giao diện dùng chung
└── main.dart    # Điểm khởi đầu của ứng dụng
```

---
Kết nối đam mê - Football Booking Flutter!
