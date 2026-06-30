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

    @Scheduled(fixedDelay = 60000) // Run every 60 seconds
    public void cleanupExpiredBookings() {
        List<Book> pendingBookings = bookingRepository.findByStatus("PENDING_PAYMENT");
        LocalDateTime limitTime = LocalDateTime.now().minusMinutes(10);
        
        for (Book booking : pendingBookings) {
            if (booking.getCreatedAt() != null && booking.getCreatedAt().isBefore(limitTime)) {
                booking.setStatus("EXPIRED");
                booking.setTotalPrice(0.0);
                bookingRepository.save(booking);
                System.out.println("Booking ID " + booking.getId() + " has expired due to payment timeout.");
            }
        }
    }
}
