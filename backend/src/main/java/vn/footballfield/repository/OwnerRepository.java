// File: src/main/java/vn/footballfield/repository/OwnerRepository.java
package vn.footballfield.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import vn.footballfield.entity.Owner;
import java.util.Optional;

public interface OwnerRepository extends JpaRepository<Owner, Integer> {
	Optional<Owner> findByEmail(String email);
}
