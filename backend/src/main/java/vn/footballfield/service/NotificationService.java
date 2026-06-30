package vn.footballfield.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import vn.footballfield.entity.Notification;
import vn.footballfield.entity.User;
import vn.footballfield.repository.NotificationRepository;
import vn.footballfield.repository.UserRepository;

import java.util.List;

@Service
public class NotificationService {

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PushNotificationService pushNotificationService;

    public Notification createAndSendNotification(Integer userId, String title, String message, String type) {
        Notification noti = new Notification();
        noti.setUserId(userId);
        noti.setMessage(message);
        noti.setType(type);
        Notification saved = notificationRepository.save(noti);

        userRepository.findById(userId).ifPresent(user -> {
            if (user.getFcmToken() != null) {
                pushNotificationService.sendNotification(user.getFcmToken(), title, message);
            }
        });

        return saved;
    }

    public List<Notification> getNotificationsByUserId(Integer userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }
}
