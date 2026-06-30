package vn.footballfield.infrastructure.migration;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class DatabaseMigration implements CommandLineRunner {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        System.out.println("====== [DATABASE MIGRATION START] ======");
        try {
            // 1. Cập nhật bảng booking
            jdbcTemplate.execute("ALTER TABLE booking ADD COLUMN IF NOT EXISTS status VARCHAR(255) DEFAULT 'PENDING_PAYMENT'");
            jdbcTemplate.execute("ALTER TABLE booking ADD COLUMN IF NOT EXISTS payment_link_id VARCHAR(255)");
            jdbcTemplate.execute("ALTER TABLE booking ADD COLUMN IF NOT EXISTS payment_url VARCHAR(1024)");
            jdbcTemplate.execute("ALTER TABLE booking ADD COLUMN IF NOT EXISTS total_price DOUBLE PRECISION");
            jdbcTemplate.execute("ALTER TABLE booking ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW()");

            // 2. Cập nhật bảng field
            jdbcTemplate.execute("ALTER TABLE field ADD COLUMN IF NOT EXISTS deposit_amount NUMERIC(38,2) DEFAULT 0.0");
            jdbcTemplate.execute("ALTER TABLE field ADD COLUMN IF NOT EXISTS price_per_hour_peak NUMERIC(38,2)");
            jdbcTemplate.execute("UPDATE field SET price_per_hour_peak = price_per_hour * 1.3 WHERE price_per_hour_peak IS NULL AND price_per_hour IS NOT NULL");

            // 3. Cập nhật bảng users (is_locked)
            jdbcTemplate.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS is_locked BOOLEAN DEFAULT FALSE");

            // Cập nhật trạng thái các đơn đặt lịch cũ trước khi tích hợp cọc sang APPROVED
            int updatedRows = jdbcTemplate.update("UPDATE booking SET status = 'APPROVED' WHERE (status = 'PENDING_PAYMENT' OR status IS NULL) AND payment_link_id IS NULL");
            System.out.println("====== [DATABASE MIGRATION: UPDATED " + updatedRows + " BOOKINGS TO APPROVED] ======");

            // In log toàn bộ đơn đặt sân để kiểm tra dữ liệu thực tế
            try {
                java.util.List<java.util.Map<String, Object>> bookings = jdbcTemplate.queryForList("SELECT id, status, payment_link_id, payment_url, total_price FROM booking");
                System.out.println("=== LIST OF ALL BOOKINGS IN DATABASE ===");
                for (java.util.Map<String, Object> b : bookings) {
                    System.out.println("Booking ID: " + b.get("id") + ", Status: " + b.get("status") + ", PaymentLinkId: " + b.get("payment_link_id") + ", PaymentUrl: " + b.get("payment_url") + ", Price: " + b.get("total_price"));
                }
                System.out.println("========================================");
            } catch (Exception ex) {
                System.err.println("Error printing bookings: " + ex.getMessage());
            }

            // 4. Tạo bảng system_config và thêm giá trị mặc định
            jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS system_config (" +
                    "config_key VARCHAR(100) PRIMARY KEY, " +
                    "config_value VARCHAR(500) NOT NULL, " +
                    "description VARCHAR(500), " +
                    "updated_at TIMESTAMP DEFAULT NOW())");

            jdbcTemplate.execute("INSERT INTO system_config (config_key, config_value, description) " +
                    "VALUES ('max_booking_days_advance', '30', 'Số ngày đặt trước tối đa'), " +
                    "('maintenance_mode', 'false', 'Chế độ bảo trì') " +
                    "ON CONFLICT (config_key) DO NOTHING");

            // 5. Tạo bảng admin_audit_log
            jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS admin_audit_log (" +
                    "id SERIAL PRIMARY KEY, " +
                    "admin_email VARCHAR(100), " +
                    "action VARCHAR(100) NOT NULL, " +
                    "target_type VARCHAR(50), " +
                    "target_id INTEGER, " +
                    "description TEXT, " +
                    "created_at TIMESTAMP DEFAULT NOW())");

            // 6. Thêm cột type vào bảng notification (đa dạng hoá loại thông báo)
            jdbcTemplate.execute("ALTER TABLE notification ADD COLUMN IF NOT EXISTS type VARCHAR(50) DEFAULT 'GENERAL'");

            // 7. Thêm cột reminder_sent vào bảng booking (đánh dấu đã gửi nhắc nhở)
            jdbcTemplate.execute("ALTER TABLE booking ADD COLUMN IF NOT EXISTS reminder_sent BOOLEAN DEFAULT FALSE");
            jdbcTemplate.execute("ALTER TABLE booking ADD COLUMN IF NOT EXISTS review_sent BOOLEAN DEFAULT FALSE");

            System.out.println("====== [DATABASE MIGRATION SUCCESSFUL] ======");
        } catch (Exception e) {
            System.err.println("====== [DATABASE MIGRATION ERROR]: " + e.getMessage() + " ======");
        }
    }
}
