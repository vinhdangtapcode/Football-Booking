# Football Booking System - Hệ Thống Đặt Sân Bóng Đá

Dự án này là một hệ thống toàn diện cho phép người dùng tìm kiếm và đặt sân bóng đá, đồng thời cung cấp công cụ quản lý cho các chủ sân. Hệ thống được xây dựng với kiến trúc Client-Server hiện đại.

## 🏗 Cấu Trúc Dự Án

Hệ thống bao gồm hai phần chính:

*   **[Backend](./backend):** Xây dựng bằng Java Spring Boot, cung cấp các RESTful API, quản lý cơ sở dữ liệu và xác thực.
*   **[Frontend](./frontend):** Ứng dụng di động đa nền tảng được xây dựng bằng Flutter, cung cấp giao diện người dùng mượt mà và trực quan.

## 🚀 Tính Năng Chính

### 🙋 Đối với Người Đặt Sân
*   **Tìm kiếm sân:** Tìm kiếm sân bóng theo khu vực, giá cả và tiện ích.
*   **Đặt sân trực tuyến:** Chọn khung giờ và đặt sân nhanh chóng.
*   **Quản lý lịch sử:** Xem lại các đơn đặt sân đã thực hiện.
*   **Yêu thích & Đánh giá:** Lưu các sân yêu thích và để lại nhận xét sau khi sử dụng.
*   **Thông báo:** Nhận thông báo đẩy về trạng thái đặt sân qua Firebase.

### 🏟 Đối với Chủ Sân
*   **Quản lý sân:** Thêm, sửa, xóa thông tin sân bóng và các khung giờ hoạt động.
*   **Quản lý đặt sân:** Xem và quản lý các yêu cầu đặt sân từ khách hàng.
*   **Thống kê:** Theo dõi hiệu suất kinh doanh (tùy chọn).

## 🛠 Công Nghệ Sử Dụng

| Thành phần | Công nghệ |
| :--- | :--- |
| **Backend** | Java 17, Spring Boot 3, Spring Security, JWT, PostgreSQL, SpringDoc (Swagger) |
| **Frontend** | Flutter, Dart, Google Maps API, Firebase Cloud Messaging |
| **DevOps/Tools** | Railway (Deployment), Git, Maven |

## 📖 Hướng Dẫn Bắt Đầu

Để chạy dự án này trên máy cục bộ, bạn cần thực hiện theo các bước hướng dẫn chi tiết trong từng thư mục:

1.  **Thiết lập Backend:** Xem hướng dẫn tại [backend/README.md](./backend/README.md).
2.  **Thiết lập Frontend:** Xem hướng dẫn tại [frontend/README.md](./frontend/README.md).

## 📄 Giấy Phép
Dự án này được phát triển cho mục đích giáo dục và thực hành.

