# Bối Cảnh Dự Án (Project Context) – Football Booking System

> **Tệp tin này là bộ nhớ sống của dự án.**  
> **Hướng dẫn dành cho AI**: Bạn phải đọc tệp này khi bắt đầu phiên làm việc và **bắt buộc phải cập nhật** tệp này bất cứ khi nào bạn hoàn thành một tính năng, sửa lỗi hoặc thay đổi kiến trúc hệ thống.

---

## 1. Trạng thái hiện tại của Dự án (Current State)

Dự án là một hệ thống đặt sân bóng đá toàn diện (Monorepo), bao gồm Spring Boot Backend và Flutter Frontend. Hệ thống đã hoàn thành các tính năng cốt lõi và đang trong giai đoạn tối ưu hóa trải nghiệm người dùng, bảo mật và sửa lỗi giao diện.

### Các phân hệ chính đang hoạt động:
*   **Khách hàng (Customer)**: Đăng ký/đăng nhập (gồm Google OAuth2), tìm sân qua bản đồ vệ tinh (Google Maps), đặt sân & thanh toán cọc qua cổng PayOS, nhận thông báo đẩy (FCM), nhắn tin với chủ sân và đánh giá sân.
*   **Chủ sân (Owner)**: Quản lý sân bóng, cấu hình giá theo khung giờ, duyệt/hủy đơn đặt sân, quản lý ví tiền cọc và yêu cầu đối soát, nhắn tin với khách hàng.
*   **Quản trị viên (Admin)**: Dashboard tổng quan doanh thu hệ thống, quản lý tài khoản, quản lý sân bóng, thực hiện đối soát và thanh toán tiền cọc cho chủ sân.

---

## 2. Các thay đổi và cập nhật gần đây (Recent Changes)

### 30/06/2026:
1.  **Đồng bộ hóa Token bảo mật**:
    *   Đã đồng bộ hóa token JWT giữa hệ thống mới (`ApiClient`) và hệ thống cũ (`ApiService`). Các màn hình cũ (như Owner/Admin) vẫn hoạt động chính xác bằng cách tự động đính kèm Token từ `ApiClient`.
2.  **Định dạng tiền tệ VND**:
    *   Tất cả số tiền doanh thu, tiền cọc trên màn hình Admin đã được định dạng chẵn theo hàng đơn vị VND, sử dụng dấu chấm phân tách hàng nghìn và không có chữ số thập phân (Ví dụ: `1.200.000 đ`).
3.  **Tách biệt cấu hình Dark Mode theo tài khoản**:
    *   Cấu hình Dark Mode (`isModernMode`) hiện được lưu trữ riêng biệt trong `SharedPreferences` theo từng ID người dùng dưới khóa `theme_mode_<userId>`.
    *   Khi người dùng đăng xuất, giao diện tự động reset về chế độ mặc định (Sáng) để tránh ảnh hưởng đến tài khoản đăng nhập sau.
4.  **Tối ưu hóa thời điểm chuyển Dark Mode**:
    *   Loại bỏ việc tải giao diện sớm tại màn hình Splash và màn hình Đăng nhập để tránh hiện tượng nhấp nháy giao diện tối.
    *   Giao diện chỉ chuyển sang Dark Mode sau khi người dùng đã vào đến màn hình chính (`MainTabScaffold`, `OwnerMainTabScaffold`, hoặc `AdminDashboardScreen`).
5.  **Sửa lỗi Dark Mode màn hình Sửa thông tin chủ sân**:
    *   Refactor [owner_edit_profile_screen.dart](file:///c:/Users/Admin/IdeaProjects/football_booking/frontend/lib/features/owner/screens/owner_edit_profile_screen.dart) để tự động thích ứng màu nền, màu chữ, Card và các nút bấm theo chế độ sáng/tối.
6.  **Tự động cập nhật thông báo khi chuyển Tab**:
    *   Cấu hình các tab chính tự động gọi `loadNotifications()` từ `NotificationProvider` khi người dùng nhấn vào Tab Thông báo để hiển thị thông tin mới ngay lập tức mà không cần kéo để tải lại.
7.  **Tài liệu hóa hệ thống**:
    *   Đã tạo thư mục `docs/` chứa [system_overview.md](file:///c:/Users/Admin/IdeaProjects/football_booking/docs/system_overview.md) và [system_design.md](file:///c:/Users/Admin/IdeaProjects/football_booking/docs/system_design.md) mô tả chi tiết kiến trúc, cơ sở dữ liệu, các luồng giao dịch PayOS và đối soát.
    *   Đã thêm hai tài liệu hướng dẫn chi tiết: [guide_run.md](file:///c:/Users/Admin/IdeaProjects/football_booking/docs/guide_run.md) (hướng dẫn thiết lập và chạy local kèm cấu hình Google Cloud, Firebase, PayOS) và [guide_deploy.md](file:///c:/Users/Admin/IdeaProjects/football_booking/docs/guide_deploy.md) (hướng dẫn deploy VPS, Docker, SSL, Nginx, đóng gói APK/AAB cho Android và IPA cho iOS).
8.  **Cấu hình deploy riêng tư**:
    *   Đã tạo thư mục `my_deploy/` chứa tệp hướng dẫn [my_deploy.md](file:///c:/Users/Admin/IdeaProjects/football_booking/my_deploy/my_deploy.md), script deploy 1-click [deploy.ps1](file:///c:/Users/Admin/IdeaProjects/football_booking/my_deploy/deploy.ps1), và script đồng bộ DB [sync_db.ps1](file:///c:/Users/Admin/IdeaProjects/football_booking/my_deploy/sync_db.ps1) để cập nhật ứng dụng và đồng bộ hóa cơ sở dữ liệu lên server DigitalOcean (`178.128.62.29`).
    *   Đã thêm thư mục `my_deploy/` vào [.gitignore](file:///c:/Users/Admin/IdeaProjects/football_booking/.gitignore) để bảo mật thông tin máy chủ cá nhân.

---

## 3. Các cấu hình quan trọng cần lưu ý (Key Configurations)

### 3.1. Địa chỉ Backend kết nối từ Frontend
Được cấu hình tập trung tại thuộc tính `baseUrl` trong tệp [app_constants.dart](file:///c:/Users/Admin/IdeaProjects/football_booking/frontend/lib/core/constants/app_constants.dart):
*   **Máy ảo Android**: `http://10.0.2.2:8080`
*   **Thiết bị thật / Máy ảo iOS**: Sử dụng IP cục bộ của máy tính chạy backend (ví dụ: `http://192.168.1.X:8080`).

### 3.2. Cấu hình Backend
Tệp [application.properties](file:///c:/Users/Admin/IdeaProjects/football_booking/backend/src/main/resources/application.properties) chứa các cấu hình quan trọng:
*   `file.base-url`: URL gốc để truy cập ảnh tải lên (cần khớp với cấu hình IP cục bộ tương ứng của thiết bị test).
*   PayOS API Keys (`payos.client-id`, `payos.api-key`, `payos.checksum-key`).

---

## 4. Hướng dẫn dành cho AI khi thực hiện cập nhật (AI Instructions)

Mỗi khi bạn thực hiện bất kỳ thay đổi nào trong mã nguồn hoặc cấu hình hệ thống:
1.  **Cập nhật phần "Recent Changes"**: Thêm dòng nhật ký ngày tháng kèm theo mô tả ngắn gọn, dễ hiểu về công việc đã thực hiện.
2.  **Cập nhật trạng thái hệ thống**: Nếu có tệp cấu hình mới hoặc thay đổi kiến trúc (ví dụ: thêm bảng cơ sở dữ liệu mới), hãy cập nhật vào các phần tương ứng trong tệp này và tệp [system_design.md](file:///c:/Users/Admin/IdeaProjects/football_booking/docs/system_design.md).
3.  **Duy trì liên kết tệp**: Khi nhắc đến các tệp nguồn, luôn sử dụng đường dẫn tuyệt đối với giao thức `file:///` để người dùng có thể click trực tiếp từ giao diện chat (ví dụ: `[main.dart](file:///c:/Users/Admin/IdeaProjects/football_booking/frontend/lib/main.dart)`).
