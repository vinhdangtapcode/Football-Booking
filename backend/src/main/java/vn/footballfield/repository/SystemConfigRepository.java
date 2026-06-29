package vn.footballfield.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import vn.footballfield.entity.SystemConfig;

public interface SystemConfigRepository extends JpaRepository<SystemConfig, String> {
}
