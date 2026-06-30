# Hướng dẫn và Quy tắc dành cho AI (Project-Specific Rules)

Chào mừng AI Assistant! Tệp này định nghĩa các quy tắc hoạt động cụ thể cho dự án **Football Booking System**. Vui lòng tuân thủ nghiêm ngặt các hướng dẫn dưới đây:

## 1. Duy trì bộ nhớ hệ thống (Context Maintenance)

*   **ĐỌC ĐẦU PHIÊN**: Vào đầu mỗi phiên làm việc hoặc khi bắt đầu một nhiệm vụ mới, bạn **phải đọc** tệp bối cảnh dự án tại [project_context.md](file:///c:/Users/Admin/IdeaProjects/football_booking/docs/project_context.md).
*   **CẬP NHẬT CUỐI PHIÊN**: Bất cứ khi nào bạn hoàn thành việc sửa đổi mã nguồn, cấu hình hoặc cơ sở dữ liệu, bạn **bắt buộc phải cập nhật** mục nhật ký thay đổi trong [project_context.md](file:///c:/Users/Admin/IdeaProjects/football_booking/docs/project_context.md) và các tệp tài liệu liên quan trong thư mục `docs/`.
*   **LIÊN KẾT TỆP**: Khi nhắc đến bất kỳ lớp, hàm hoặc tệp nào, hãy sử dụng liên kết Markdown tuyệt đối với giao thức `file:///` (ví dụ: `[main.dart](file:///c:/Users/Admin/IdeaProjects/football_booking/frontend/lib/main.dart)`). Không sử dụng dấu backtick xung quanh liên kết.

---

## 2. Quy tắc phát triển Frontend (Flutter)

*   **Hỗ trợ giao diện sáng/tối (Dark Mode)**:
    *   Tất cả các màn hình mới hoặc sửa đổi phải sử dụng `Provider.of<ThemeProvider>(context)` để cấu hình màu sắc động.
    *   Tuyệt đối không sử dụng màu nền hoặc màu chữ dạng tĩnh (như `Colors.white` làm màu nền chính hoặc `Colors.black` làm màu chữ chính) mà không kiểm tra biến `isModernMode`.
*   **Định dạng tiền tệ**:
    *   Mọi thông tin liên quan đến giá cả, doanh thu và tiền cọc phải được làm tròn và định dạng theo định dạng tiền tệ Việt Nam Đồng chẵn hàng đơn vị (Ví dụ: `1.200.000 đ`). Sử dụng dấu chấm phân tách hàng nghìn, không sử dụng dấu phẩy hay số thập phân.
*   **Xác thực và Token**:
    *   Sử dụng `ApiClient` và `AuthProvider` cho các luồng xử lý xác thực mới. Các luồng cũ thông qua `ApiService` đã được đồng bộ hóa tự động nên hạn chế sửa đổi trực tiếp nếu không cần thiết.

---

## 3. Quy tắc phát triển Backend (Spring Boot)

*   **Cấu hình môi trường**:
    *   Mọi thay đổi liên quan đến cấu hình trong `application.properties` phải được đồng bộ hóa và cập nhật chú thích tương tự tại tệp mẫu `application-example.properties`.
*   **Xác thực chữ ký Webhook**:
    *   Khi làm việc với các Webhook từ bên thứ ba (như PayOS), luôn xác thực chữ ký an toàn (`signature`) bằng khóa bí mật (`checksum-key`) trước khi cập nhật dữ liệu cơ sở dữ liệu.
