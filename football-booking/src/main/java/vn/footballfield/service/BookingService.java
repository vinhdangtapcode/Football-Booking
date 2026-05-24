package vn.footballfield.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import vn.footballfield.entity.Book;
import vn.footballfield.entity.Field;
import vn.footballfield.entity.Notification;
import vn.footballfield.exception.InvalidBookingTimeException;
import vn.footballfield.repository.BookingRepository;
import vn.footballfield.repository.FieldRepository;
import vn.footballfield.repository.NotificationRepository;

import javax.validation.Valid;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

@Service
public class BookingService {

	@Autowired
	private BookingRepository bookingRepository;

	@Autowired
	private FieldRepository fieldRepository;

	@Autowired
	private vn.footballfield.repository.UserRepository userRepository;

	@Autowired
	private NotificationRepository notificationRepository;

	@Autowired
	private PushNotificationService pushNotificationService;

	@Autowired
	private ChatService chatService;

	private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

	public Book createBooking(@Valid Book booking, Integer customerId) {
		Field fieldFromRequest = booking.getField();
		if (fieldFromRequest == null || fieldFromRequest.getId() == null) {
			throw new RuntimeException("Field not provided");
		}
		// Lấy đối tượng Field từ DB dựa trên id
		Field field = fieldRepository.findById(fieldFromRequest.getId())
				.orElseThrow(() -> new RuntimeException("Field not found"));

		if (!Boolean.TRUE.equals(field.getAvailable())) { // Kiểm tra an toàn
			throw new RuntimeException("Field not available");
		}

		// Kiểm tra trùng lịch đặt sân (chỉ overlap thực sự mới không cho đặt, đặt liên
		// tiếp thì cho phép)
		List<Book> existingBookings = bookingRepository.findByField_Id(field.getId());
		for (Book b : existingBookings) {
			if (b.getFromTime() != null && b.getToTime() != null && booking.getFromTime() != null
					&& booking.getToTime() != null) {
				boolean overlap = booking.getFromTime().isBefore(b.getToTime())
						&& booking.getToTime().isAfter(b.getFromTime());
				if (overlap) {
					throw new RuntimeException("Sân đã được đặt vào thời điểm này");
				}
			}
		}

		booking.setCustomerId(customerId);
		booking.setField(field); // Gán lại đối tượng Field từ DB cho booking
		// Set customer object for serialization
		vn.footballfield.entity.User customer = userRepository.findById(customerId).orElse(null);
		booking.setCustomer(customer);
		Book savedBooking = bookingRepository.save(booking);

		// Format thời gian để hiển thị đẹp hơn
		String fromTimeStr = booking.getFromTime() != null ? booking.getFromTime().format(TIME_FORMATTER) : "";
		String toTimeStr = booking.getToTime() != null ? booking.getToTime().format(TIME_FORMATTER) : "";
		String customerName = customer != null ? customer.getName() : "Khách hàng";

		// Tạo thông báo cho người dùng
		Notification userNoti = new Notification();
		userNoti.setUserId(customerId);
		String userMessage = "Bạn đã đặt sân '" + field.getName() + "' thành công từ " + fromTimeStr + " đến "
				+ toTimeStr + ".";
		userNoti.setMessage(userMessage);
		notificationRepository.save(userNoti);

		// Gửi push notification cho người dùng
		if (customer != null && customer.getFcmToken() != null) {
			pushNotificationService.sendNotification(
					customer.getFcmToken(),
					"Đặt sân thành công! ⚽",
					"Bạn đã đặt sân '" + field.getName() + "' từ " + fromTimeStr + " đến " + toTimeStr);
		}

		// Tạo thông báo cho chủ sân
		if (field.getOwner() != null) {
			vn.footballfield.entity.Owner owner = field.getOwner();
			vn.footballfield.entity.User ownerUser = null;
			if (owner != null && owner.getEmail() != null) {
				ownerUser = userRepository.findByEmail(owner.getEmail()).orElse(null);
			}
			if (ownerUser != null) {
				Notification ownerNoti = new Notification();
				ownerNoti.setUserId(ownerUser.getId());
				String ownerMessage = "Sân '" + field.getName() + "' của bạn đã được " + customerName + " đặt từ "
						+ fromTimeStr + " đến " + toTimeStr + ".";
				ownerNoti.setMessage(ownerMessage);
				notificationRepository.save(ownerNoti);

				// Gửi push notification cho chủ sân
				if (ownerUser.getFcmToken() != null) {
					pushNotificationService.sendNotification(
							ownerUser.getFcmToken(),
							"Có khách đặt sân mới! 🎉",
							customerName + " đã đặt sân '" + field.getName() + "' từ " + fromTimeStr + " đến "
									+ toTimeStr);
				}
			}
		}

		// Gửi tin nhắn thông báo đặt sân vào cuộc hội thoại
		if (field.getOwner() != null) {
			chatService.sendBookingNotificationMessage(
					customerId,
					field.getOwner().getId(),
					field.getId(),
					field.getName(),
					fromTimeStr,
					toTimeStr,
					customerName);
		}

		return savedBooking;
	}

	public List<Book> getBookingsByCustomer(Integer customerId) {
		return bookingRepository.findByCustomerId(customerId);
	}

	public Optional<Book> getBookingById(Integer id) {
		return bookingRepository.findById(id);
	}

	public List<Book> getBookingsByOwner(Integer ownerId) {
		return bookingRepository.findByField_Owner_Id(ownerId);
	}

	public List<Book> getBookingsByField(Integer fieldId) {
		return bookingRepository.findByField_Id(fieldId);
	}
}
