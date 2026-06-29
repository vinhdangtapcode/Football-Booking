package vn.footballfield.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import vn.footballfield.entity.AdminAuditLog;
import java.util.List;

public interface AdminAuditLogRepository extends JpaRepository<AdminAuditLog, Integer> {
    List<AdminAuditLog> findAllByOrderByCreatedAtDesc();
}
