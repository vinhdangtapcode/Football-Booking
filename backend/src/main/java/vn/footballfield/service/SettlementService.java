package vn.footballfield.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import jakarta.transaction.Transactional;
import vn.footballfield.entity.Book;
import vn.footballfield.entity.Notification;
import vn.footballfield.entity.Settlement;
import vn.footballfield.entity.User;
import vn.footballfield.repository.BookingRepository;
import vn.footballfield.repository.NotificationRepository;
import vn.footballfield.repository.SettlementRepository;
import vn.footballfield.repository.UserRepository;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class SettlementService {

    @Autowired
    private SettlementRepository settlementRepository;

    @Autowired
    private BookingRepository bookingRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private PushNotificationService pushNotificationService;

    @Autowired
    private BookingService bookingService;

    @Transactional
    public Settlement settleOwnerBookings(Integer ownerId) {
        List<Book> ownerBookings = bookingService.getBookingsByOwner(ownerId);
        
        List<Book> unsettledBookings = ownerBookings.stream()
                .filter(b -> ("APPROVED".equals(b.getStatus()) || ("CANCELLED".equals(b.getStatus()) && b.getTotalPrice() != null && b.getTotalPrice() > 0))
                        && !Boolean.TRUE.equals(b.getSettled()))
                .toList();

        if (unsettledBookings.isEmpty()) {
            throw new RuntimeException("Chủ sân không có số dư nào cần đối soát!");
        }

        double totalAmount = unsettledBookings.stream()
                .mapToDouble(b -> b.getTotalPrice() != null ? b.getTotalPrice() : 0.0)
                .sum();

        List<String> bookingIdsList = unsettledBookings.stream()
                .map(b -> String.valueOf(b.getId()))
                .toList();
        String bookingIdsStr = String.join(",", bookingIdsList);

        Settlement settlement = new Settlement();
        settlement.setOwnerId(ownerId);
        settlement.setAmount(totalAmount);
        settlement.setSettledAt(LocalDateTime.now());
        settlement.setBookingIds(bookingIdsStr);
        settlementRepository.save(settlement);

        // Gửi thông báo SETTLEMENT_DONE cho chủ sân
        try {
            if (!unsettledBookings.isEmpty() && unsettledBookings.get(0).getField() != null
                    && unsettledBookings.get(0).getField().getOwner() != null) {
                String ownerEmail = unsettledBookings.get(0).getField().getOwner().getEmail();
                User ownerU = userRepository.findByEmail(ownerEmail).orElse(null);
                if (ownerU != null) {
                    String settlementMsg = "Admin đã hoàn tất thanh toán " + String.format("%,.0f", totalAmount) + " VND cho " + unsettledBookings.size() + " lịch đặt sân. Vui lòng kiểm tra tài khoản ngân hàng.";
                    Notification noti = new Notification();
                    noti.setUserId(ownerU.getId());
                    noti.setMessage(settlementMsg);
                    noti.setType("SETTLEMENT_DONE");
                    notificationRepository.save(noti);
                    if (ownerU.getFcmToken() != null) {
                        pushNotificationService.sendNotification(ownerU.getFcmToken(), "Đối soát hoàn tất 💰", settlementMsg);
                    }
                }
            }
        } catch (Exception e) {
            System.out.println("Gửi thông báo đối soát thất bại: " + e.getMessage());
        }

        for (Book booking : unsettledBookings) {
            booking.setSettled(true);
            bookingRepository.save(booking);
        }

        return settlement;
    }

    public List<Settlement> getSettlementsByOwner(Integer ownerId) {
        return settlementRepository.findByOwnerIdOrderBySettledAtDesc(ownerId);
    }
}
