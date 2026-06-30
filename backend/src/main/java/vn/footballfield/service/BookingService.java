package vn.footballfield.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import vn.footballfield.entity.Book;
import vn.footballfield.entity.Field;
import vn.footballfield.entity.Notification;
import vn.footballfield.repository.BookingRepository;
import vn.footballfield.repository.FieldRepository;
import vn.footballfield.repository.NotificationRepository;
import vn.payos.PayOS;
import vn.payos.model.v2.paymentRequests.CreatePaymentLinkRequest;
import vn.payos.model.v2.paymentRequests.CreatePaymentLinkResponse;

import javax.validation.Valid;
import java.math.BigDecimal;
import java.time.Duration;
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

	@Autowired
	private PayOS payOS;



	@Value("${file.base-url:http://localhost:8080}")
	private String baseUrl;

	private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
	private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy");
	private static final DateTimeFormatter HOUR_FORMATTER = DateTimeFormatter.ofPattern("HH:mm");

	private String formatBookingSlot(LocalDateTime from, LocalDateTime to) {
		if (from == null || to == null) return "";
		return from.format(HOUR_FORMATTER) + " - " + to.format(HOUR_FORMATTER) + " ngày " + from.format(DATE_FORMATTER);
	}

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

		// 1. ÁP DỤNG GIỚI HẠN ĐẶT SÂN
		List<Book> customerBookings = bookingRepository.findByCustomerId(customerId);
		
		// Giới hạn 1: Không được có quá 1 lịch đặt ở trạng thái chờ thanh toán
		long pendingCount = customerBookings.stream()
				.filter(b -> "PENDING_PAYMENT".equals(b.getStatus()))
				.count();
		if (pendingCount >= 1) {
			throw new RuntimeException("Bạn đang có 1 lịch chờ thanh toán. Vui lòng hoàn tất hoặc hủy trước khi đặt thêm!");
		}

		// Giới hạn 2: Không được có quá 2 lịch đặt ở tương lai (đã được duyệt)
		LocalDateTime nowTime = LocalDateTime.now();
		long activeFutureCount = customerBookings.stream()
				.filter(b -> "APPROVED".equals(b.getStatus()) && b.getFromTime() != null && b.getFromTime().isAfter(nowTime))
				.count();
		if (activeFutureCount >= 2) {
			throw new RuntimeException("Bạn đã đạt giới hạn đặt tối đa (tối đa 2 lịch đặt ở tương lai cùng lúc)!");
		}

		// 2. KIỂM TRA TRÙNG LỊCH (Chỉ kiểm tra trùng lịch với APPROVED hoặc PENDING_PAYMENT)
		List<Book> existingBookings = bookingRepository.findByField_Id(field.getId());
		for (Book b : existingBookings) {
			if (b.getFromTime() != null && b.getToTime() != null && booking.getFromTime() != null
					&& booking.getToTime() != null) {
				if ("CANCELLED".equals(b.getStatus()) || "EXPIRED".equals(b.getStatus())) {
					continue;
				}
				boolean overlap = booking.getFromTime().isBefore(b.getToTime())
						&& booking.getToTime().isAfter(b.getFromTime());
				if (overlap) {
					throw new RuntimeException("Sân đã được đặt vào thời điểm này");
				}
			}
		}

		// 3. TÍNH TOÁN TIỀN CỌC (Cấu hình sẵn trên sân nhân với số giờ thuê)
		double durationInHours = 1.0;
		if (booking.getFromTime() != null && booking.getToTime() != null) {
			long minutes = java.time.Duration.between(booking.getFromTime(), booking.getToTime()).toMinutes();
			durationInHours = minutes / 60.0;
		}
		if (durationInHours <= 0.0) {
			durationInHours = 1.0;
		}

		BigDecimal depositBigDecimal = field.getDepositAmount() != null ? field.getDepositAmount() : BigDecimal.ZERO;
		long amount = Math.round(depositBigDecimal.doubleValue() * durationInHours);

		// Nếu số tiền cọc bằng 0, duyệt luôn không cần cổng thanh toán
		if (amount <= 0) {
			booking.setCustomerId(customerId);
			booking.setField(field);
			booking.setStatus("APPROVED");
			booking.setTotalPrice(0.0);
			
			vn.footballfield.entity.User customer = userRepository.findById(customerId).orElse(null);
			booking.setCustomer(customer);
			
			Book savedBooking = bookingRepository.save(booking);
			confirmAndNotifyBooking(savedBooking);
			return savedBooking;
		}

		// 4. LƯU LỊCH ĐẶT Ở TRẠNG THÁI CHỜ THANH TOÁN
		booking.setCustomerId(customerId);
		booking.setField(field);
		booking.setStatus("PENDING_PAYMENT");
		booking.setTotalPrice((double) amount);
		
		vn.footballfield.entity.User customer = userRepository.findById(customerId).orElse(null);
		booking.setCustomer(customer);
		
		Book savedBooking = bookingRepository.save(booking);

		// 5. TẠO LIÊN KẾT THANH TOÁN QUA PAYOS
		try {
			String returnUrl = baseUrl + "/payment/success";
			String cancelUrl = baseUrl + "/payment/cancel";

			CreatePaymentLinkRequest paymentData = CreatePaymentLinkRequest.builder()
					.orderCode(savedBooking.getId().longValue())
					.amount(amount)
					.description("Dat san ID " + savedBooking.getId())
					.returnUrl(returnUrl)
					.cancelUrl(cancelUrl)
					.build();

			CreatePaymentLinkResponse response = payOS.paymentRequests().create(paymentData);
			savedBooking.setPaymentUrl(response.getCheckoutUrl());
			savedBooking.setPaymentLinkId(response.getPaymentLinkId());
			savedBooking = bookingRepository.save(savedBooking);
		} catch (Exception e) {
			bookingRepository.delete(savedBooking);
			throw new RuntimeException("Lỗi khởi tạo cổng thanh toán PayOS: " + e.getMessage());
		}

		return savedBooking;
	}

	public void confirmAndNotifyBooking(Book booking) {
		if (booking == null) return;
		
		booking.setStatus("APPROVED");
		bookingRepository.save(booking);

		Field field = booking.getField();
		vn.footballfield.entity.User customer = booking.getCustomer();
		if (customer == null && booking.getCustomerId() != null) {
			customer = userRepository.findById(booking.getCustomerId()).orElse(null);
		}
		
		// Format thời gian để hiển thị đẹp hơn
		String slotStr = formatBookingSlot(booking.getFromTime(), booking.getToTime());
		String customerName = customer != null ? customer.getName() : "Khách hàng";

		// Tạo thông báo cho người dùng
		Notification userNoti = new Notification();
		userNoti.setUserId(booking.getCustomerId());
		String userMessage = "Bạn đã đặt sân '" + (field != null ? field.getName() : "") + "' thành công khung giờ " + slotStr + ".";
		userNoti.setMessage(userMessage);
		userNoti.setType("BOOKING_CONFIRMED");
		notificationRepository.save(userNoti);

		// Gửi push notification cho người dùng
		if (customer != null && customer.getFcmToken() != null) {
			pushNotificationService.sendNotification(
					customer.getFcmToken(),
					"Đặt sân thành công! ⚽",
					"Bạn đã đặt sân '" + (field != null ? field.getName() : "") + "' khung giờ " + slotStr
			);
		}

		// Tạo thông báo cho chủ sân
		if (field != null && field.getOwner() != null) {
			vn.footballfield.entity.Owner owner = field.getOwner();
			vn.footballfield.entity.User ownerUser = null;
			if (owner != null && owner.getEmail() != null) {
				ownerUser = userRepository.findByEmail(owner.getEmail()).orElse(null);
			}
			if (ownerUser != null) {
				Notification ownerNoti = new Notification();
				ownerNoti.setUserId(ownerUser.getId());
				String ownerMessage = "Sân '" + field.getName() + "' của bạn đã được " + customerName + " đặt khung giờ " + slotStr + ".";
				ownerNoti.setMessage(ownerMessage);
				ownerNoti.setType("BOOKING_CONFIRMED");
				notificationRepository.save(ownerNoti);

				// Gửi push notification cho chủ sân
				if (ownerUser.getFcmToken() != null) {
					pushNotificationService.sendNotification(
							ownerUser.getFcmToken(),
							"Có khách đặt sân mới! 🎉",
							customerName + " đã đặt sân '" + field.getName() + "' khung giờ " + slotStr
					);
				}
			}
		}

		// Gửi tin nhắn thông báo đặt sân vào cuộc hội thoại
		if (field != null && field.getOwner() != null && booking.getCustomerId() != null) {
			chatService.sendBookingNotificationMessage(
					booking.getCustomerId(),
					field.getOwner().getId(),
					field.getId(),
					field.getName(),
					slotStr,
					customerName);
		}
	}

	private void syncPendingBookings(List<Book> bookings) {
		if (bookings == null) return;
		for (Book booking : bookings) {
			if ("PENDING_PAYMENT".equals(booking.getStatus())) {
				try {
					vn.payos.model.v2.paymentRequests.PaymentLink info = payOS.paymentRequests().get(booking.getId().longValue());
					if (vn.payos.model.v2.paymentRequests.PaymentLinkStatus.PAID.equals(info.getStatus())) {
						confirmAndNotifyBooking(booking);
					} else if (vn.payos.model.v2.paymentRequests.PaymentLinkStatus.CANCELLED.equals(info.getStatus())) {
						booking.setStatus("CANCELLED");
						booking.setTotalPrice(0.0);
						bookingRepository.save(booking);
					}
				} catch (Exception e) {
					System.out.println("Kiểm tra trạng thái PayOS cho lịch đặt " + booking.getId() + " thất bại: " + e.getMessage());
				}
			}
		}
	}

	public List<Book> getBookingsByCustomer(Integer customerId) {
		List<Book> bookings = bookingRepository.findByCustomerId(customerId);
		syncPendingBookings(bookings);
		return bookings;
	}

	public Optional<Book> getBookingById(Integer id) {
		Optional<Book> bookingOpt = bookingRepository.findById(id);
		if (bookingOpt.isPresent()) {
			Book booking = bookingOpt.get();
			if ("PENDING_PAYMENT".equals(booking.getStatus())) {
				try {
					vn.payos.model.v2.paymentRequests.PaymentLink info = payOS.paymentRequests().get(booking.getId().longValue());
					if (vn.payos.model.v2.paymentRequests.PaymentLinkStatus.PAID.equals(info.getStatus())) {
						confirmAndNotifyBooking(booking);
					} else if (vn.payos.model.v2.paymentRequests.PaymentLinkStatus.CANCELLED.equals(info.getStatus())) {
						booking.setStatus("CANCELLED");
						booking.setTotalPrice(0.0);
						bookingRepository.save(booking);
					}
				} catch (Exception e) {
					System.out.println("Kiểm tra trạng thái PayOS cho lịch đặt " + id + " chưa đổi: " + e.getMessage());
				}
			}
		}
		return bookingOpt;
	}

	public List<Book> getBookingsByOwner(Integer ownerId) {
		List<Book> bookings = bookingRepository.findByField_Owner_Id(ownerId);
		syncPendingBookings(bookings);
		return bookings;
	}

	public List<Book> getBookingsByField(Integer fieldId) {
		List<Book> bookings = bookingRepository.findByField_Id(fieldId);
		syncPendingBookings(bookings);
		return bookings;
	}

	public List<Book> getAllBookings() {
		return bookingRepository.findAll();
	}

	public Book cancelBooking(Integer bookingId, Integer customerId) {
		Book booking = bookingRepository.findById(bookingId)
				.orElseThrow(() -> new RuntimeException("Không tìm thấy lịch đặt sân này"));
				
		if (!booking.getCustomerId().equals(customerId)) {
			throw new RuntimeException("Bạn không có quyền hủy lịch đặt này");
		}
		
		if ("CANCELLED".equals(booking.getStatus()) || "EXPIRED".equals(booking.getStatus())) {
			throw new RuntimeException("Lịch đặt sân đã ở trạng thái hủy hoặc hết hạn");
		}
		
		// Hủy trên PayOS nếu đang chờ thanh toán
		if ("PENDING_PAYMENT".equals(booking.getStatus())) {
			try {
				payOS.paymentRequests().cancel(booking.getId().longValue(), "Khach hang chu dong huy");
			} catch (Exception e) {
				System.out.println("Hủy link PayOS thất bại: " + e.getMessage());
			}
			booking.setTotalPrice(0.0);
		}
		
		booking.setStatus("CANCELLED");
		
		// Gửi thông báo cho chủ sân về việc hủy sân
		try {
			if (booking.getField() != null && booking.getField().getOwner() != null) {
				vn.footballfield.entity.Owner owner = booking.getField().getOwner();
				vn.footballfield.entity.User ownerUser = null;
				if (owner != null && owner.getEmail() != null) {
					ownerUser = userRepository.findByEmail(owner.getEmail()).orElse(null);
				}
				if (ownerUser != null) {
					String slotTime = formatBookingSlot(booking.getFromTime(), booking.getToTime());
					String cancelTimeStr = LocalDateTime.now().format(TIME_FORMATTER);

					Notification ownerNoti = new Notification();
					ownerNoti.setUserId(ownerUser.getId());
					String msg = "Lịch đặt sân '" + booking.getField().getName() + "' khung giờ " + slotTime + " đã bị hủy bởi khách hàng vào lúc " + cancelTimeStr + ".";
					ownerNoti.setMessage(msg);
					ownerNoti.setType("BOOKING_CANCELLED_BY_USER");
					notificationRepository.save(ownerNoti);
					
					if (ownerUser.getFcmToken() != null) {
						pushNotificationService.sendNotification(
								ownerUser.getFcmToken(),
								"Lịch đặt sân đã bị hủy ❌",
								msg
						);
					}
				}
			}
		} catch (Exception e) {
			System.out.println("Gửi thông báo hủy sân thất bại: " + e.getMessage());
		}

		return bookingRepository.save(booking);
	}





	public Book adminCancelBooking(Integer bookingId) {
		Book booking = bookingRepository.findById(bookingId)
				.orElseThrow(() -> new RuntimeException("Không tìm thấy lịch đặt sân này"));

		if ("CANCELLED".equals(booking.getStatus()) || "EXPIRED".equals(booking.getStatus())) {
			throw new RuntimeException("Lịch đặt sân đã ở trạng thái hủy hoặc hết hạn");
		}

		// Hủy trên PayOS nếu đang chờ thanh toán
		if ("PENDING_PAYMENT".equals(booking.getStatus())) {
			try {
				if (booking.getPaymentLinkId() != null) {
					payOS.paymentRequests().cancel(booking.getId().longValue(), "Admin chu dong huy");
				}
			} catch (Exception e) {
				System.out.println("Hủy link PayOS thất bại: " + e.getMessage());
			}
			booking.setTotalPrice(0.0);
		}

		booking.setStatus("CANCELLED");
		Book savedBooking = bookingRepository.save(booking);

		String slotTime = formatBookingSlot(booking.getFromTime(), booking.getToTime());
		String fieldName = booking.getField() != null ? booking.getField().getName() : "Sân bóng";

		// 1. Gửi thông báo cho người đặt (Khách hàng)
		try {
			vn.footballfield.entity.User customer = userRepository.findById(booking.getCustomerId()).orElse(null);
			if (customer != null) {
				String cancelTimeStr = LocalDateTime.now().format(TIME_FORMATTER);
				Notification userNoti = new Notification();
				userNoti.setUserId(customer.getId());
				String msg = "Lịch đặt sân '" + fieldName + "' khung giờ " + slotTime + " đã bị hủy bởi Quản trị viên (Admin) vào lúc " + cancelTimeStr + ".";
				userNoti.setMessage(msg);
				userNoti.setType("BOOKING_CANCELLED_BY_ADMIN");
				notificationRepository.save(userNoti);

				if (customer.getFcmToken() != null) {
					pushNotificationService.sendNotification(
							customer.getFcmToken(),
							"Lịch đặt sân bị hủy bởi Admin ❌",
							msg
					);
				}
			}
		} catch (Exception e) {
			System.out.println("Gửi thông báo hủy sân cho khách hàng thất bại: " + e.getMessage());
		}

		// 2. Gửi thông báo cho chủ sân
		try {
			if (booking.getField() != null && booking.getField().getOwner() != null) {
				vn.footballfield.entity.Owner owner = booking.getField().getOwner();
				vn.footballfield.entity.User ownerUser = null;
				if (owner != null && owner.getEmail() != null) {
					ownerUser = userRepository.findByEmail(owner.getEmail()).orElse(null);
				}
				if (ownerUser != null) {
					String cancelTimeStr = LocalDateTime.now().format(TIME_FORMATTER);
					Notification ownerNoti = new Notification();
					ownerNoti.setUserId(ownerUser.getId());
					String msg = "Lịch đặt sân '" + fieldName + "' khung giờ " + slotTime + " đã bị hủy bởi Quản trị viên (Admin) vào lúc " + cancelTimeStr + ".";
					ownerNoti.setMessage(msg);
					ownerNoti.setType("BOOKING_CANCELLED_BY_ADMIN");
					notificationRepository.save(ownerNoti);

					if (ownerUser.getFcmToken() != null) {
						pushNotificationService.sendNotification(
								ownerUser.getFcmToken(),
								"Lịch đặt sân bị hủy bởi Admin ❌",
								msg
						);
					}
				}
			}
		} catch (Exception e) {
			System.out.println("Gửi thông báo hủy sân cho chủ sân thất bại: " + e.getMessage());
		}

		return savedBooking;
	}
}
