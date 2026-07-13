package vn.footballfield.infrastructure.scheduler;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import vn.footballfield.entity.Book;
import vn.footballfield.repository.BookingRepository;

import java.time.LocalDateTime;
import java.util.List;

@Component
public class PaymentCleanupScheduler {

    @Autowired
    private BookingRepository bookingRepository;

    @Autowired
    private vn.footballfield.service.PushNotificationService pushNotificationService;

    @Scheduled(fixedDelay = 60000) // Run every 60 seconds
    public void cleanupExpiredBookings() {
        List<Book> pendingBookings = bookingRepository.findByStatus("PENDING_PAYMENT");
        LocalDateTime limitTime = LocalDateTime.now().minusMinutes(10);
        
        for (Book booking : pendingBookings) {
            if (booking.getCreatedAt() != null && booking.getCreatedAt().isBefore(limitTime)) {
                booking.setStatus("EXPIRED");
                booking.setTotalPrice(0.0);
                Book savedBooking = bookingRepository.save(booking);
                System.out.println("Booking ID " + savedBooking.getId() + " has expired due to payment timeout.");

                // Gửi thông báo đẩy cập nhật realtime cho các client để giải phóng slot
                if (savedBooking.getField() != null && savedBooking.getField().getId() != null) {
                    try {
                        java.util.Map<String, String> syncData = new java.util.HashMap<>();
                        syncData.put("type", "REALTIME_BOOKING_UPDATE");
                        syncData.put("fieldId", savedBooking.getField().getId().toString());
                        if (savedBooking.getFromTime() != null) {
                            syncData.put("date", savedBooking.getFromTime().format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy")));
                        }
                        pushNotificationService.sendTopicDataMessage("booking_updates", syncData);
                    } catch (Exception e) {
                        System.err.println("Gửi tin nhắn realtime sync EXPIRED thất bại: " + e.getMessage());
                    }
                }
            }
        }
    }
}
