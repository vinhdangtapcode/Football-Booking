// File: src/main/java/vn/footballfield/repository/FieldRepository.java
package vn.footballfield.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import vn.footballfield.entity.Field;
import vn.footballfield.entity.Owner;
import java.util.List;

public interface FieldRepository extends JpaRepository<Field, Integer> {
	boolean existsById(Integer id);
	List<Field> findByOwner(Owner owner);
}
