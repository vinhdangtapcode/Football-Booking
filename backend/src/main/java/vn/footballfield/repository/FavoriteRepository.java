package vn.footballfield.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;
import vn.footballfield.entity.Favorite;

import java.util.List;

public interface FavoriteRepository extends JpaRepository<Favorite, Integer> {
	List<Favorite> findByCustomerId(Integer customerId);

	List<Favorite> findByField_Id(Integer fieldId);

	@Modifying
	@Transactional
	@Query("DELETE FROM Favorite f WHERE f.customerId = :customerId AND f.field.id = :fieldId")
	void deleteByCustomerIdAndField_Id(@Param("customerId") Integer customerId,
	                                   @Param("fieldId") Integer fieldId);

}