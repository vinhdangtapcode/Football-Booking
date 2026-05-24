# Hướng dẫn cấu hình Google Maps API

## 1. Lấy Google Maps API Key

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Tạo project mới hoặc chọn project hiện có
3. Bật các API sau:
   - Maps SDK for Android
   - Geocoding API
   - Geolocation API
4. Tạo API Key:
   - Vào "Credentials" > "Create Credentials" > "API Key"
   - Sao chép API Key vừa tạo

## 2. Cấu hình Android

### Cập nhật AndroidManifest.xml
Thay thế `YOUR_GOOGLE_MAPS_API_KEY_HERE` trong file:
`android/app/src/main/AndroidManifest.xml`

```xml
<meta-data 
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE"/>
```

### Cập nhật build.gradle (nếu cần)
Trong file `android/app/build.gradle`, đảm bảo minSdkVersion >= 20:

```gradle
android {
    defaultConfig {
        minSdkVersion 20
    }
}
```

## 3. Cấu hình iOS (nếu cần)

Thêm API Key vào file `ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## 4. Tính năng đã được tích hợp

### Màn hình chi tiết sân:
- ✅ Nút "Xem bản đồ": Mở màn hình bản đồ tương tác
- ✅ Nút "Chỉ đường": Mở Google Maps để điều hướng

### Màn hình bản đồ:
- ✅ Hiển thị vị trí sân bóng với marker
- ✅ Hiển thị vị trí hiện tại của người dùng
- ✅ Nút chỉ đường trực tiếp từ bản đồ
- ✅ Thông tin chi tiết sân ở bottom panel

### Quyền được yêu cầu:
- ✅ ACCESS_FINE_LOCATION
- ✅ ACCESS_COARSE_LOCATION
- ✅ INTERNET

## 5. Cách sử dụng

1. Từ màn hình danh sách sân, chọn một sân bóng
2. Trong màn hình chi tiết sân, nhấn:
   - "Xem bản đồ": Xem sân trên bản đồ tương tác
   - "Chỉ đường": Mở Google Maps để điều hướng
3. Trong màn hình bản đồ:
   - Xem vị trí sân và vị trí hiện tại
   - Nhấn nút GPS để về vị trí hiện tại
   - Nhấn "Chỉ đường" để mở Google Maps

## 6. Lưu ý bảo mật API Key

- Không commit API Key lên Git repository công khai
- Hạn chế API Key chỉ cho domain/package của ứng dụng
- Thiết lập quota limits trong Google Cloud Console
