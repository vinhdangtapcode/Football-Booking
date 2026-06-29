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

	List<Book> findByStatus(String status);

	// For booking reminder scheduler: APPROVED bookings starting within a time window, not yet reminded
	@org.springframework.data.jpa.repository.Query("SELECT b FROM Book b WHERE b.status = 'APPROVED' AND b.fromTime BETWEEN :from AND :to AND (b.reminderSent = FALSE OR b.reminderSent IS NULL)")
	List<Book> findUpcomingBookingsToRemind(@org.springframework.data.repository.query.Param("from") java.time.LocalDateTime from, @org.springframework.data.repository.query.Param("to") java.time.LocalDateTime to);

	// For review request scheduler: APPROVED bookings ending within time window, not yet sent review request
	@org.springframework.data.jpa.repository.Query("SELECT b FROM Book b WHERE b.status = 'APPROVED' AND b.toTime BETWEEN :from AND :to AND (b.reviewSent = FALSE OR b.reviewSent IS NULL)")
	List<Book> findCompletedBookingsForReview(@org.springframework.data.repository.query.Param("from") java.time.LocalDateTime from, @org.springframework.data.repository.query.Param("to") java.time.LocalDateTime to);
}

