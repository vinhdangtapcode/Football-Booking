package vn.footballfield.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import vn.footballfield.entity.*;
import vn.footballfield.repository.*;
import vn.footballfield.service.*;

import javax.validation.Valid;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FieldRepository fieldRepository;

    @Autowired
    private OwnerRepository ownerRepository;

    @Autowired
    private BookingRepository bookingRepository;

    @Autowired
    private BookingService bookingService;

    @Autowired
    private SystemConfigRepository systemConfigRepository;

    @Autowired
    private AdminAuditLogRepository adminAuditLogRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private PushNotificationService pushNotificationService;

    private void logAdminAction(String action, String targetType, Integer targetId, String description) {
        String adminEmail = SecurityContextHolder.getContext().getAuthentication().getName();
        AdminAuditLog log = new AdminAuditLog();
        log.setAdminEmail(adminEmail);
        log.setAction(action);
        log.setTargetType(targetType);
        log.setTargetId(targetId);
        log.setDescription(description);
        adminAuditLogRepository.save(log);
    }

    @GetMapping("/dashboard-stats")
    public ResponseEntity<?> getDashboardStats() {
        long activeFields = fieldRepository.findAll().stream().filter(f -> Boolean.TRUE.equals(f.getAvailable())).count();
        long totalUsers = userRepository.count();
        long totalOwners = ownerRepository.count();
        List<Book> allBookings = bookingRepository.findAll();

        double totalUnsettledAmount = allBookings.stream()
                .filter(b -> ("APPROVED".equals(b.getStatus()) || ("CANCELLED".equals(b.getStatus()) && b.getTotalPrice() != null && b.getTotalPrice() > 0))
                        && !Boolean.TRUE.equals(b.getSettled()))
                .mapToDouble(b -> b.getTotalPrice() != null ? b.getTotalPrice() : 0.0)
                .sum();

        long pendingBookings = allBookings.stream()
                .filter(b -> "PENDING_PAYMENT".equals(b.getStatus()))
                .count();

        LocalDate today = LocalDate.now();
        long todayBookings = allBookings.stream()
                .filter(b -> b.getCreatedAt() != null && b.getCreatedAt().toLocalDate().isEqual(today))
                .count();

        double revenueThisMonth = allBookings.stream()
                .filter(b -> "APPROVED".equals(b.getStatus()) && b.getCreatedAt() != null 
                        && b.getCreatedAt().toLocalDate().getMonth() == today.getMonth() 
                        && b.getCreatedAt().toLocalDate().getYear() == today.getYear())
                .mapToDouble(b -> b.getTotalPrice() != null ? b.getTotalPrice() : 0.0)
                .sum();

        List<Map<String, Object>> bookingsByDay = new ArrayList<>();
        for (int i = 6; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            long count = allBookings.stream()
                    .filter(b -> b.getCreatedAt() != null && b.getCreatedAt().toLocalDate().isEqual(date))
                    .count();
            double amount = allBookings.stream()
                    .filter(b -> "APPROVED".equals(b.getStatus()) && b.getCreatedAt() != null && b.getCreatedAt().toLocalDate().isEqual(date))
                    .mapToDouble(b -> b.getTotalPrice() != null ? b.getTotalPrice() : 0.0)
                    .sum();
            Map<String, Object> dayMap = new HashMap<>();
            dayMap.put("date", date.toString());
            dayMap.put("count", count);
            dayMap.put("revenue", amount);
            bookingsByDay.add(dayMap);
        }

        long approvedCount = allBookings.stream().filter(b -> "APPROVED".equals(b.getStatus())).count();
        long cancelledCount = allBookings.stream().filter(b -> "CANCELLED".equals(b.getStatus())).count();
        long expiredCount = allBookings.stream().filter(b -> "EXPIRED".equals(b.getStatus())).count();
        Map<String, Long> statusBreakdown = Map.of(
                "APPROVED", approvedCount,
                "CANCELLED", cancelledCount,
                "EXPIRED", expiredCount,
                "PENDING_PAYMENT", pendingBookings
        );

        List<AdminAuditLog> recentLogs = adminAuditLogRepository.findAllByOrderByCreatedAtDesc();
        List<AdminAuditLog> recentActivities = recentLogs.size() > 10 ? recentLogs.subList(0, 10) : recentLogs;

        List<Map<String, String>> alerts = new ArrayList<>();
        List<Owner> owners = ownerRepository.findAll();
        for (Owner owner : owners) {
            if (owner.getBankAccountNo() == null || owner.getBankAccountNo().isEmpty()) {
                alerts.add(Map.of("type", "NO_BANK_ACCOUNT", "ownerName", owner.getOwnerName()));
            }
        }

        Map<String, Object> stats = new HashMap<>();
        stats.put("activeFields", activeFields);
        stats.put("totalUsers", totalUsers);
        stats.put("totalOwners", totalOwners);
        stats.put("totalUnsettledAmount", totalUnsettledAmount);
        stats.put("pendingBookings", pendingBookings);
        stats.put("todayBookings", todayBookings);
        stats.put("revenueThisMonth", revenueThisMonth);
        stats.put("bookingsByDay", bookingsByDay);
        stats.put("bookingStatusBreakdown", statusBreakdown);
        stats.put("recentActivities", recentActivities);
        stats.put("alerts", alerts);

        return ResponseEntity.ok(stats);
    }

    @GetMapping("/bookings")
    public ResponseEntity<List<Book>> getAdminBookings() {
        List<Book> list = bookingRepository.findAll();
        list.sort((a, b) -> {
            LocalDateTime at = a.getCreatedAt() != null ? a.getCreatedAt() : LocalDateTime.MIN;
            LocalDateTime bt = b.getCreatedAt() != null ? b.getCreatedAt() : LocalDateTime.MIN;
            return bt.compareTo(at);
        });
        return ResponseEntity.ok(list);
    }



    @PostMapping("/bookings/{id}/cancel")
    public ResponseEntity<?> cancelBookingByAdmin(@PathVariable Integer id) {
        try {
            Book book = bookingService.adminCancelBooking(id);
            logAdminAction("CANCEL_BOOKING", "BOOKING", id, "Admin hủy lịch đặt sân #" + id);
            return ResponseEntity.ok(book);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", e.getMessage()));
        }
    }

    @PatchMapping("/users/{id}/toggle-lock")
    public ResponseEntity<?> toggleUserLock(@PathVariable Integer id) {
        String adminEmail = SecurityContextHolder.getContext().getAuthentication().getName();
        Optional<User> adminOpt = userRepository.findByEmail(adminEmail);
        if (adminOpt.isPresent() && adminOpt.get().getId().equals(id)) {
            return ResponseEntity.badRequest().body(Map.of("message", "Bạn không thể tự khóa chính mình!"));
        }
        Optional<User> userOpt = userRepository.findById(id);
        if (userOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        User user = userOpt.get();
        if ("ADMIN".equals(user.getRole())) {
            return ResponseEntity.badRequest().body(Map.of("message", "Không thể khóa tài khoản Admin khác!"));
        }
        user.setIsLocked(!Boolean.TRUE.equals(user.getIsLocked()));
        userRepository.save(user);
        String action = user.getIsLocked() ? "LOCK_USER" : "UNLOCK_USER";
        logAdminAction(action, "USER", id, (user.getIsLocked() ? "Khóa" : "Mở khóa") + " tài khoản " + user.getEmail());
        return ResponseEntity.ok(user);
    }

    @PatchMapping("/fields/{id}/toggle-availability")
    public ResponseEntity<?> toggleFieldAvailability(@PathVariable Integer id) {
        Optional<Field> fieldOpt = fieldRepository.findById(id);
        if (fieldOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        Field field = fieldOpt.get();
        field.setAvailable(!Boolean.TRUE.equals(field.getAvailable()));
        fieldRepository.save(field);
        String action = field.getAvailable() ? "ACTIVATE_FIELD" : "DEACTIVATE_FIELD";
        logAdminAction(action, "FIELD", id, (field.getAvailable() ? "Bật" : "Tắt") + " hoạt động sân " + field.getName());
        return ResponseEntity.ok(field);
    }

    @GetMapping("/config")
    public ResponseEntity<List<SystemConfig>> getSystemConfigs() {
        return ResponseEntity.ok(systemConfigRepository.findAll());
    }

    @PutMapping("/config/{key}")
    public ResponseEntity<?> updateSystemConfig(@PathVariable String key, @RequestBody Map<String, String> body) {
        Optional<SystemConfig> configOpt = systemConfigRepository.findById(key);
        if (configOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        SystemConfig config = configOpt.get();
        config.setConfigValue(body.get("value"));
        systemConfigRepository.save(config);
        logAdminAction("UPDATE_CONFIG", "CONFIG", 0, "Cập nhật cấu hình " + key + " thành " + body.get("value"));
        return ResponseEntity.ok(config);
    }

    @GetMapping("/audit-log")
    public ResponseEntity<List<AdminAuditLog>> getAdminAuditLogs() {
        return ResponseEntity.ok(adminAuditLogRepository.findAllByOrderByCreatedAtDesc());
    }

    @GetMapping("/owners")
    public ResponseEntity<List<Owner>> getOwners() {
        return ResponseEntity.ok(ownerRepository.findAll());
    }

    @PostMapping("/owners")
    public ResponseEntity<Owner> createOwner(@Valid @RequestBody Owner owner) {
        Owner saved = ownerRepository.save(owner);
        logAdminAction("CREATE_OWNER", "OWNER", saved.getId(), "Tạo chủ sân mới: " + owner.getOwnerName());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @PutMapping("/owners/{id}")
    public ResponseEntity<Owner> updateOwner(@PathVariable Integer id, @Valid @RequestBody Owner ownerDetails) {
        Optional<Owner> ownerOpt = ownerRepository.findById(id);
        if (ownerOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        Owner owner = ownerOpt.get();
        owner.setOwnerName(ownerDetails.getOwnerName());
        owner.setEmail(ownerDetails.getEmail());
        owner.setContactNumber(ownerDetails.getContactNumber());
        owner.setBankName(ownerDetails.getBankName());
        owner.setBankAccountNo(ownerDetails.getBankAccountNo());
        owner.setBankAccountName(ownerDetails.getBankAccountName());
        Owner updated = ownerRepository.save(owner);
        logAdminAction("UPDATE_OWNER", "OWNER", id, "Cập nhật thông tin chủ sân: " + owner.getOwnerName());
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/owners/{id}")
    public ResponseEntity<Void> deleteOwner(@PathVariable Integer id) {
        Optional<Owner> ownerOpt = ownerRepository.findById(id);
        if (ownerOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        ownerRepository.deleteById(id);
        logAdminAction("DELETE_OWNER", "OWNER", id, "Xóa chủ sân ID: " + id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/notifications/broadcast")
    public ResponseEntity<?> broadcastNotification(@RequestBody Map<String, String> body) {
        String title = body.get("title");
        String message = body.get("body");

        if (title == null || title.trim().isEmpty() || message == null || message.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Tiêu đề và nội dung không được để trống"));
        }

        List<User> allUsers = userRepository.findAll();
        List<Notification> notificationsToSave = new ArrayList<>();

        for (User user : allUsers) {
            Notification noti = new Notification();
            noti.setUserId(user.getId());
            noti.setMessage(title + ": " + message);
            notificationsToSave.add(noti);
        }
        notificationRepository.saveAll(notificationsToSave);

        // Gửi push notification bất đồng bộ
        new Thread(() -> {
            for (User user : allUsers) {
                if (user.getFcmToken() != null && !user.getFcmToken().trim().isEmpty()) {
                    try {
                        pushNotificationService.sendNotification(user.getFcmToken(), title, message);
                    } catch (Exception e) {
                        System.out.println("Gửi FCM cho user #" + user.getId() + " thất bại: " + e.getMessage());
                    }
                }
            }
        }).start();

        logAdminAction("BROADCAST_NOTIFICATION", "SYSTEM", 0, "Gửi thông báo toàn hệ thống: " + title);
        return ResponseEntity.ok(Map.of("message", "Gửi thông báo thành công", "recipientCount", allUsers.size()));
    }
}
