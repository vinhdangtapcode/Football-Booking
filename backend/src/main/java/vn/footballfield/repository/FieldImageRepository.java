package vn.footballfield.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.footballfield.entity.FieldImage;

import java.util.List;

@Repository
public interface FieldImageRepository extends JpaRepository<FieldImage, Integer> {
	List<FieldImage> findByFieldIdOrderByDisplayOrderAsc(Integer fieldId);
	List<FieldImage> findByFieldId(Integer fieldId);
	void deleteByFieldId(Integer fieldId);
}
