# Hướng Dẫn Triển Khai Hệ Thống Lên Môi Trường Sản Xuất (Production Deployment Guide)

> **Dự án**: Football Booking System  
> **Phiên bản**: 1.0  
> **Tài liệu**: Hướng dẫn đóng gói, cấu hình sản xuất và deploy chi tiết.

---

## 1. Sơ đồ kiến trúc triển khai sản xuất (Production Architecture)

Khi đưa dự án lên môi trường sản xuất (Production), hệ thống cần hoạt động dưới giao thức bảo mật **HTTPS** để tích hợp được Webhook từ PayOS.

```text
[Khách hàng (App) / PayOS Webhook]
                 │ (HTTPS - Cổng 443)
                 ▼
     ┌──────────────────────┐
     │  Nginx Reverse Proxy │ (Xử lý chứng chỉ SSL Let's Encrypt)
     └───────────┬──────────┘
                 │ (HTTP - Cổng 8080)
                 ▼
     ┌──────────────────────┐
     │  Spring Boot Backend │ (Chạy trong Docker Container / Jar)
     └───────────┬──────────┘
                 │
                 ▼
     ┌──────────────────────┐
     │  PostgreSQL Database │ (Dịch vụ đám mây AWS RDS / Render DB)
     └──────────────────────┘
```

---

## 2. Triển khai Hệ thống Backend (Spring Boot)

### 2.1. Chuẩn bị Cơ sở dữ liệu sản xuất
Tránh việc cài đặt PostgreSQL trực tiếp trên cùng một máy chủ ứng dụng nếu không có cơ chế backup. Hãy sử dụng các dịch vụ cơ sở dữ liệu được quản lý (Managed Database):
*   **Dịch vụ khuyên dùng**: AWS RDS, Render PostgreSQL, hoặc Railway PostgreSQL.
*   **Cấu hình**: Lưu lại chuỗi kết nối dạng `jdbc:postgresql://<host>:<port>/<database_name>`, tên đăng nhập và mật khẩu.

---

### 2.2. Đóng gói ứng dụng thành tệp JAR
Mở terminal tại thư mục `backend` và chạy lệnh sau để build dự án bỏ qua phần kiểm thử:
```bash
mvn clean package -DskipTests
```
Tệp tin sau khi đóng gói sẽ nằm ở: `backend/target/football_booking-0.0.1-SNAPSHOT.jar`.

---

### 2.3. Triển khai bằng Docker (Khuyên dùng cho VPS)
Để ứng dụng hoạt động ổn định và dễ dàng quản lý trên máy chủ VPS (Ubuntu/CentOS), hãy đóng gói ứng dụng vào Docker.

1.  **Tạo tệp `Dockerfile`** tại thư mục gốc của `backend`:
    ```dockerfile
    FROM openjdk:17-jdk-alpine
    VOLUME /tmp
    ARG JAR_FILE=target/*.jar
    COPY ${JAR_FILE} app.jar
    # Copy file account Firebase vào container
    COPY src/main/resources/firebase-service-account.json firebase-service-account.json
    EXPOSE 8080
    ENTRYPOINT ["java","-jar","/app.jar"]
    ```
2.  **Tạo tệp `docker-compose.yml`** để quản lý khởi chạy:
    ```yaml
    version: '3.8'
    services:
      app:
        build: .
        ports:
          - "8080:8080"
        environment:
          - SPRING_DATASOURCE_URL=jdbc:postgresql://db-host:5432/FootballField
          - SPRING_DATASOURCE_USERNAME=your_prod_db_user
          - SPRING_DATASOURCE_PASSWORD=your_prod_db_password
          - JWT_SECRET=ChuoiKhoaMatKhauSieuDaiVaBaoMatDànhChoProduction2026
          - PAYOS_CLIENT_ID=client_id_production_payos
          - PAYOS_API_KEY=api_key_production_payos
          - PAYOS_CHECKSUM_KEY=checksum_key_production_payos
          - GOOGLE_CLIENT_ID=google_client_id_web_production
        restart: always
    ```
3.  **Khởi chạy trên VPS**:
    ```bash
    docker-compose up -d --build
    ```

---

### 2.4. Cấu hình Nginx và SSL (HTTPS)
PayOS yêu cầu đường dẫn nhận Webhook phải là **HTTPS**. Bạn cần cấu hình Nginx làm Reverse Proxy và cài đặt chứng chỉ SSL miễn phí từ **Let's Encrypt**.

1.  **Cài đặt Certbot và Nginx** trên Ubuntu:
    ```bash
    sudo apt update
    sudo apt install nginx certbot python3-certbot-nginx -y
    ```
2.  **Cấu hình Nginx**:
    Tạo file cấu hình `/etc/nginx/sites-available/football-booking` với nội dung:
    ```nginx
    server {
        server_name api.yourdomain.com; # Thay bằng tên miền của bạn

        location / {
            proxy_pass http://localhost:8080; # Trỏ về container Spring Boot
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    ```
    Kích hoạt cấu hình và reload Nginx:
    ```bash
    sudo ln -s /etc/nginx/sites-available/football-booking /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
    ```
3.  **Cấp chứng chỉ SSL tự động**:
    ```bash
    sudo certbot --nginx -d api.yourdomain.com
    ```
    *Chọn option tự động redirect từ HTTP sang HTTPS.*

---

## 3. Cấu hình dịch vụ bên thứ ba trên Production

### 3.1. Cấu hình Google Console & Đăng nhập Google
Khi xuất bản ứng dụng lên Google Play hoặc App Store, bạn cần cập nhật thông tin bảo mật:
1.  **OAuth Consent Screen**: Chuyển trạng thái dự án từ **Testing** sang **In Production** và gửi yêu cầu xác minh (nếu cần thiết) để người dùng không gặp cảnh báo bảo mật khi đăng nhập bằng Google.
2.  **Cập nhật mã SHA-256 khóa ký phát hành (Release Keystore)**:
    *   Khi bạn đóng gói ứng dụng Flutter để xuất bản (sử dụng Keystore tự tạo), bạn cần lấy mã vân tay **SHA-256** của khóa ký phát hành đó.
    *   Truy cập **Google Cloud Console** > **Credentials** > Sửa thông tin **Android Client ID** và cập nhật mã SHA-256 này vào.
    *   Đồng thời cập nhật mã SHA-256 này vào phần cài đặt ứng dụng Android trên **Firebase Console**. *Nếu không cập nhật bước này, tính năng Đăng nhập bằng Google sẽ bị lỗi ngay lập tức trên bản cài đặt Release.*

### 3.2. Cấu hình Webhook của PayOS
1.  Truy cập vào trang quản trị **PayOS Portal** của bạn.
2.  Chuyển sang cấu hình cổng thanh toán **Môi trường Live (Thực tế)**.
3.  Điền URL nhận Webhook của bạn: `https://api.yourdomain.com/api/bookings/webhook`.
4.  Lưu lại cấu hình để nhận thông báo thanh toán tức thì từ ngân hàng.

---

## 4. Triển khai ứng dụng di động Frontend (Flutter)

### 4.1. Đóng gói ứng dụng Android (.apk & .aab)

1.  **Tạo khóa ký ứng dụng (Keystore)**:
    Mở Terminal và chạy lệnh để tạo file khóa ký (đặt tên là `upload-keystore.jks`):
    ```bash
    keytool -genkey -v -keystore c:/Users/Admin/upload-keystore.jks -storetype editorials -alias upload -keyalg RSA -keysize 2048 -validity 10000
    ```
2.  **Cấu hình cấu hình ký trong dự án**:
    *   Tạo một file tên là `key.properties` nằm tại thư mục [frontend/android/key.properties](file:///c:/Users/Admin/IdeaProjects/football_booking/frontend/android/key.properties) chứa thông tin khóa ký:
        ```properties
        storePassword=mat_khau_keystore
        keyPassword=mat_khau_key
        keyAlias=upload
        storeFile=c:/Users/Admin/upload-keystore.jks
        ```
    *   Mở tệp [build.gradle](file:///c:/Users/Admin/IdeaProjects/football_booking/frontend/android/app/build.gradle) để cấu hình tự động ký khi build release.
3.  **Cập nhật cấu hình môi trường**:
    *   Đảm bảo tệp [app_constants.dart](file:///c:/Users/Admin/IdeaProjects/football_booking/frontend/lib/core/constants/app_constants.dart) đã trỏ `baseUrl` về tên miền HTTPS của bạn: `https://api.yourdomain.com`.
4.  **Chạy lệnh đóng gói**:
    *   **Build tệp cài đặt nhanh APK**:
        ```bash
        flutter build apk --release
        ```
    *   **Build tệp phát hành lên Google Play (App Bundle)**:
        ```bash
        flutter build appbundle
        ```
    *Tệp tin xuất ra sẽ nằm ở thư mục `build/app/outputs/bundle/release/app-release.aab`.*

---

### 4.2. Đóng gói ứng dụng iOS (.ipa)

1.  **Đăng ký tài khoản nhà phát triển**: Yêu cầu có tài khoản **Apple Developer Account** ($99/năm).
2.  **Cấu hình Xcode**:
    *   Mở thư mục `ios` của dự án bằng phần mềm **Xcode** trên máy Mac.
    *   Chọn **Runner** > tab **Signing & Capabilities**.
    *   Bật **Automatically manage signing**, chọn **Team** phát triển của bạn.
    *   Đảm bảo Bundle Identifier là duy nhất.
3.  **Cấu hình Push Notification (FCM trên iOS)**:
    *   Tạo khóa **APNs Auth Key** (.p8) trên trang Apple Developer.
    *   Tải khóa này lên **Firebase Console** > **Project Settings** > **Cloud Messaging** > mục cấu hình APNs của iOS.
4.  **Chạy lệnh đóng gói**:
    Mở Terminal tại thư mục `frontend` trên máy Mac và thực hiện:
    ```bash
    flutter build ipa
    ```
    *Sau khi hoàn thành, bạn sử dụng công cụ **Transporter** hoặc Xcode để upload tệp `.ipa` lên **App Store Connect** phục vụ kiểm thử qua TestFlight hoặc phát hành chính thức.*
