package vn.footballfield.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import vn.footballfield.entity.Book;

import java.util.List;

public interface BookingRepository extends JpaRepository<Book, Integer> {
	@org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"customer"})
	List<Book> findByCustomerId(Integer customerId);

	@org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"customer"})
	List<Book> findByField_Owner_Id(Integer ownerId);

	List<Book> findByField_Id(Integer id);
}

