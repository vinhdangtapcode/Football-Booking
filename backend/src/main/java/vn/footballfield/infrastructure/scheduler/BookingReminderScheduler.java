package vn.footballfield.infrastructure.scheduler;

import vn.footballfield.service.PushNotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import vn.footballfield.entity.Book;
import vn.footballfield.entity.Notification;
import vn.footballfield.repository.BookingRepository;
import vn.footballfield.repository.NotificationRepository;
import vn.footballfield.repository.RatingRepository;
import vn.footballfield.repository.UserRepository;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Scheduler chạy mỗi 15 phút để:
 * 1. Gửi nhắc nhở trước giờ đá (2 giờ trước fromTime)
 * 2. Gửi yêu cầu đánh giá sau trận (30 phút sau toTime, chỉ nếu chưa từng đánh giá sân đó)
 */
@Component
public class BookingReminderScheduler {

    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy");

    @Autowired
    private BookingRepository bookingRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private PushNotificationService pushNotificationService;

    @Autowired
    private RatingRepository ratingRepository;

    @Autowired
    private UserRepository userRepository;

    // Chạy mỗi 15 phút
    @Scheduled(fixedRate = 15 * 60 * 1000)
    public void sendBookingReminders() {
        LocalDateTime now = LocalDateTime.now();

        // ---- 1. Nhắc nhở trước 2 giờ ----
        // Tìm các booking APPROVED có fromTime trong [now+1h45m, now+2h15m] và chưa được nhắc
        LocalDateTime reminderWindowStart = now.plusHours(1).plusMinutes(45);
        LocalDateTime reminderWindowEnd   = now.plusHours(2).plusMinutes(15);

        List<Book> upcomingBookings = bookingRepository.findUpcomingBookingsToRemind(reminderWindowStart, reminderWindowEnd);
        for (Book booking : upcomingBookings) {
            try {
                String fieldName = booking.getField() != null ? booking.getField().getName() : "Sân bóng";
                String startTimeStr = booking.getFromTime() != null ? booking.getFromTime().format(TIME_FMT) : "";

                // Gửi cho khách hàng
                if (booking.getCustomerId() != null) {
                    String userMsg = "⏰ Sân '" + fieldName + "' của bạn sẽ bắt đầu vào lúc " + startTimeStr + ". Chúc bạn có một trận đấu vui vẻ! ⚽";
                    saveNotification(booking.getCustomerId(), userMsg, "BOOKING_REMINDER");

                    vn.footballfield.entity.User customer = userRepository.findById(booking.getCustomerId()).orElse(null);
                    if (customer != null && customer.getFcmToken() != null) {
                        pushNotificationService.sendNotification(customer.getFcmToken(), "Sắp đến giờ đá bóng! ⚽", userMsg);
                    }
                }

                // Gửi cho chủ sân
                if (booking.getField() != null && booking.getField().getOwner() != null) {
                    String ownerEmail = booking.getField().getOwner().getEmail();
                    vn.footballfield.entity.User ownerUser = userRepository.findByEmail(ownerEmail).orElse(null);
                    if (ownerUser != null) {
                        String ownerMsg = "⏰ Sân '" + fieldName + "' của bạn sẽ có khách đến vào lúc " + startTimeStr + ". Hãy chuẩn bị sân sẵn sàng!";
                        saveNotification(ownerUser.getId(), ownerMsg, "BOOKING_REMINDER");

                        if (ownerUser.getFcmToken() != null) {
                            pushNotificationService.sendNotification(ownerUser.getFcmToken(), "Khách sắp đến sân! ⏰", ownerMsg);
                        }
                    }
                }

                // Đánh dấu đã gửi nhắc nhở
                booking.setReminderSent(true);
                bookingRepository.save(booking);
            } catch (Exception e) {
                System.out.println("[Reminder Scheduler] Lỗi gửi nhắc nhở cho booking " + booking.getId() + ": " + e.getMessage());
            }
        }

        // ---- 2. Yêu cầu đánh giá sau trận ----
        // Tìm booking có toTime trong [now-1h, now-30min] (tức là đã kết thúc 30-60 phút trước) và chưa gửi review
        LocalDateTime reviewWindowStart = now.minusHours(1);
        LocalDateTime reviewWindowEnd   = now.minusMinutes(30);

        List<Book> completedBookings = bookingRepository.findCompletedBookingsForReview(reviewWindowStart, reviewWindowEnd);
        for (Book booking : completedBookings) {
            try {
                if (booking.getCustomerId() == null || booking.getField() == null) continue;
                Integer fieldId = booking.getField().getId();
                Integer customerId = booking.getCustomerId();

                // Chỉ gửi nếu khách chưa từng đánh giá sân này
                boolean hasRated = ratingRepository.existsByFieldIdAndCustomerId(fieldId, customerId);
                if (!hasRated) {
                    String fieldName = booking.getField().getName();
                    String reviewMsg = "⭐ Bạn vừa kết thúc trận đấu tại '" + fieldName + "'. Hãy để lại đánh giá để giúp cộng đồng nhé!";
                    saveNotification(customerId, reviewMsg, "REVIEW_REQUEST");

                    vn.footballfield.entity.User customer = userRepository.findById(customerId).orElse(null);
                    if (customer != null && customer.getFcmToken() != null) {
                        pushNotificationService.sendNotification(customer.getFcmToken(), "Trận đấu kết thúc! Đánh giá sân nhé ⭐", reviewMsg);
                    }
                }

                // Đánh dấu đã gửi yêu cầu đánh giá dù có gửi hay không (để không gửi lại)
                booking.setReviewSent(true);
                bookingRepository.save(booking);
            } catch (Exception e) {
                System.out.println("[Reminder Scheduler] Lỗi gửi yêu cầu đánh giá cho booking " + booking.getId() + ": " + e.getMessage());
            }
        }

        if (!upcomingBookings.isEmpty() || !completedBookings.isEmpty()) {
            System.out.println("[Reminder Scheduler] Đã nhắc " + upcomingBookings.size() + " lịch sắp đến, gửi đánh giá cho " + completedBookings.size() + " lịch đã xong.");
        }
    }

    private void saveNotification(Integer userId, String message, String type) {
        Notification noti = new Notification();
        noti.setUserId(userId);
        noti.setMessage(message);
        noti.setType(type);
        notificationRepository.save(noti);
    }
}
