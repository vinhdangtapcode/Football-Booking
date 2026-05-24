package vn.footballfield.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import vn.footballfield.entity.Rating;

import java.util.List;

public interface RatingRepository extends JpaRepository<Rating, Integer> {
	List<Rating> findByFieldId(Integer fieldId);
	List<Rating> findByCustomerId(Integer customerId);
}