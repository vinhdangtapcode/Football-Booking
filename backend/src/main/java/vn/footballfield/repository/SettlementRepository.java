package vn.footballfield.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.footballfield.entity.Settlement;
import java.util.List;

@Repository
public interface SettlementRepository extends JpaRepository<Settlement, Integer> {
    List<Settlement> findByOwnerIdOrderBySettledAtDesc(Integer ownerId);
}
