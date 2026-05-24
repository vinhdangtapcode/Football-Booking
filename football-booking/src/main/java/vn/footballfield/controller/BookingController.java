package vn.footballfield.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import vn.footballfield.dto.TimeRangeDTO;
import vn.footballfield.dto.BookingHistoryDTO;
import vn.footballfield.entity.Book;
import vn.footballfield.entity.Field;
import vn.footballfield.service.BookingService;
import vn.footballfield.service.FieldService;
import vn.footballfield.service.UserService;

import javax.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/dat-san")
public class BookingController {

	@Autowired
	private BookingService bookingService;

	@Autowired
	private FieldService fieldService;

	@Autowired
	private UserService userService;

	@GetMapping("/{fieldId}")
	public ResponseEntity<Field> getFieldDetail(@PathVariable Integer fieldId) {
		return fieldService.getFieldById(fieldId)
				.map(field -> new ResponseEntity<>(field, HttpStatus.OK))
				.orElse(new ResponseEntity<>(HttpStatus.NOT_FOUND));
	}

	@GetMapping("/lich-su-dat-san")
	public ResponseEntity<List<BookingHistoryDTO>> getBookingHistory() {
		Integer customerId = getCurrentUserId();
		List<Book> bookings = bookingService.getBookingsByCustomer(customerId);
		List<BookingHistoryDTO> result = bookings.stream()
			.map(b -> new BookingHistoryDTO(
				b.getId(),
				b.getField() != null ? b.getField().getId() : null,
				b.getField() != null ? b.getField().getName() : null,
				b.getFromTime(),
				b.getToTime(),
				b.getAdditional(),
				b.getCustomerName(),
				b.getCustomerPhone()
			))
			.toList();
		return new ResponseEntity<>(result, HttpStatus.OK);
	}

	@PostMapping("/xac-nhan")
	public ResponseEntity<Book> confirmBooking(@Valid @RequestBody Book booking) {
		Integer customerId = getCurrentUserId();
		return new ResponseEntity<>(bookingService.createBooking(booking, customerId), HttpStatus.CREATED);
	}

	// API: Lấy danh sách các khung giờ đã đặt của một sân
	@GetMapping("/{fieldId}/booked-times")
	public ResponseEntity<List<TimeRangeDTO>> getBookedTimes(@PathVariable Integer fieldId) {
		List<Book> bookings = bookingService.getBookingsByField(fieldId);
		List<TimeRangeDTO> result = bookings.stream()
			.filter(b -> b.getFromTime() != null && b.getToTime() != null)
			.map(b -> new TimeRangeDTO(b.getFromTime(), b.getToTime()))
			.toList();
		return ResponseEntity.ok(result);
	}

	private Integer getCurrentUserId() {
		String email = SecurityContextHolder.getContext().getAuthentication().getName();
		return userService.getUserIdByEmail(email);
	}
}

