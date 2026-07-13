package vn.footballfield.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import vn.footballfield.dto.booking.TimeRangeDTO;
import vn.footballfield.dto.booking.BookingHistoryDTO;
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

	@GetMapping("/lich-su-dat-san/{bookingId}")
	public ResponseEntity<BookingHistoryDTO> getBookingDetail(@PathVariable Integer bookingId) {
		return bookingService.getBookingById(bookingId)
				.map(b -> new BookingHistoryDTO(
					b.getId(),
					b.getField() != null ? b.getField().getId() : null,
					b.getField() != null ? b.getField().getName() : null,
					b.getField() != null ? b.getField().getAddress() : null,
					(b.getField() != null && b.getField().getPricePerHour() != null) ? b.getField().getPricePerHour().doubleValue() : 0.0,
					b.getFromTime(),
					b.getToTime(),
					b.getAdditional(),
					b.getCustomerName(),
					b.getCustomerPhone(),
					b.getStatus(),
					b.getTotalPrice(),
					b.getPaymentUrl(),
					b.getField() != null ? b.getField().getImageUrl() : null,
					(b.getField() != null && b.getField().getOwner() != null) ? b.getField().getOwner().getOwnerName() : null,
					(b.getField() != null && b.getField().getOwner() != null) ? b.getField().getOwner().getContactNumber() : null
				))
				.map(dto -> new ResponseEntity<>(dto, HttpStatus.OK))
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
				b.getField() != null ? b.getField().getAddress() : null,
				(b.getField() != null && b.getField().getPricePerHour() != null) ? b.getField().getPricePerHour().doubleValue() : 0.0,
				b.getFromTime(),
				b.getToTime(),
				b.getAdditional(),
				b.getCustomerName(),
				b.getCustomerPhone(),
				b.getStatus(),
				b.getTotalPrice(),
				b.getPaymentUrl(),
				b.getField() != null ? b.getField().getImageUrl() : null,
				(b.getField() != null && b.getField().getOwner() != null) ? b.getField().getOwner().getOwnerName() : null,
				(b.getField() != null && b.getField().getOwner() != null) ? b.getField().getOwner().getContactNumber() : null
			))
			.toList();
		return new ResponseEntity<>(result, HttpStatus.OK);
	}

	@PostMapping("/xac-nhan")
	public ResponseEntity<Book> confirmBooking(@Valid @RequestBody Book booking) {
		Integer customerId = getCurrentUserId();
		return new ResponseEntity<>(bookingService.createBooking(booking, customerId), HttpStatus.CREATED);
	}

	@GetMapping("/{fieldId}/booked-times")
	public ResponseEntity<List<TimeRangeDTO>> getBookedTimes(@PathVariable Integer fieldId) {
		List<Book> bookings = bookingService.getBookingsByField(fieldId);
		List<TimeRangeDTO> result = bookings.stream()
			.filter(b -> b.getFromTime() != null && b.getToTime() != null)
			// Chỉ giữ các lịch đang APPROVED, PENDING_PAYMENT hoặc lịch cũ chưa có status (null)
			.filter(b -> b.getStatus() == null || "APPROVED".equals(b.getStatus()) || "PENDING_PAYMENT".equals(b.getStatus()))
			.map(b -> new TimeRangeDTO(b.getFromTime(), b.getToTime()))
			.toList();
		return ResponseEntity.ok(result);
	}

	@PostMapping("/{bookingId}/huy-san")
	public ResponseEntity<?> cancelBooking(@PathVariable Integer bookingId) {
		Integer customerId = getCurrentUserId();
		Book cancelled = bookingService.cancelBooking(bookingId, customerId);
		return ResponseEntity.ok(cancelled);
	}

	private Integer getCurrentUserId() {
		String email = SecurityContextHolder.getContext().getAuthentication().getName();
		return userService.getUserIdByEmail(email);
	}
}

