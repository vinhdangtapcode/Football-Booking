package vn.footballfield.config;

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

            System.out.println("====== [DATABASE MIGRATION SUCCESSFUL] ======");
        } catch (Exception e) {
            System.err.println("====== [DATABASE MIGRATION ERROR]: " + e.getMessage() + " ======");
        }
    }
}
