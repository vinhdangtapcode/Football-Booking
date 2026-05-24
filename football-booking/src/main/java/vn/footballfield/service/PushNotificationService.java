package vn.footballfield.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;
import jakarta.annotation.PostConstruct;

import java.io.IOException;

@Service
public class PushNotificationService {

    @PostConstruct
    public void initialize() {
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                ClassPathResource resource = new ClassPathResource("firebase-service-account.json");

                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(resource.getInputStream()))
                        .build();

                FirebaseApp.initializeApp(options);
                System.out.println("Firebase Admin SDK initialized successfully");
            }
        } catch (IOException e) {
            System.err.println("Failed to initialize Firebase: " + e.getMessage());
            System.err.println(
                    "Push notifications will not work. Please add firebase-service-account.json to resources folder.");
        }
    }

    /**
     * Send push notification to a specific device
     * 
     * @param fcmToken FCM token of the target device
     * @param title    Notification title
     * @param body     Notification body
     * @return true if sent successfully
     */
    public boolean sendNotification(String fcmToken, String title, String body) {
        if (fcmToken == null || fcmToken.isEmpty()) {
            System.out.println("No FCM token provided, skipping push notification");
            return false;
        }

        try {
            // Thêm Android Config để xử lý click action
            com.google.firebase.messaging.AndroidConfig androidConfig = com.google.firebase.messaging.AndroidConfig
                    .builder()
                    .setNotification(com.google.firebase.messaging.AndroidNotification.builder()
                            .setClickAction("FLUTTER_NOTIFICATION_CLICK")
                            .build())
                    .build();

            Message message = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .setAndroidConfig(androidConfig)
                    .putData("click_action", "FLUTTER_NOTIFICATION_CLICK")
                    .putData("type", "notification")
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println("Push notification sent successfully: " + response);
            return true;
        } catch (Exception e) {
            System.err.println("Failed to send push notification: " + e.getMessage());
            return false;
        }
    }

    /**
     * Send push notification with custom data
     * 
     * @param fcmToken FCM token of the target device
     * @param title    Notification title
     * @param body     Notification body
     * @param data     Additional data to send
     * @return true if sent successfully
     */
    public boolean sendNotificationWithData(String fcmToken, String title, String body,
            java.util.Map<String, String> data) {
        if (fcmToken == null || fcmToken.isEmpty()) {
            System.out.println("No FCM token provided, skipping push notification");
            return false;
        }

        try {
            // Thêm Android Config để xử lý click action
            com.google.firebase.messaging.AndroidConfig androidConfig = com.google.firebase.messaging.AndroidConfig
                    .builder()
                    .setNotification(com.google.firebase.messaging.AndroidNotification.builder()
                            .setClickAction("FLUTTER_NOTIFICATION_CLICK")
                            .build())
                    .build();

            Message.Builder messageBuilder = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .setAndroidConfig(androidConfig);

            if (data != null) {
                messageBuilder.putAllData(data);
            }

            String response = FirebaseMessaging.getInstance().send(messageBuilder.build());
            System.out.println("Push notification sent successfully: " + response);
            return true;
        } catch (Exception e) {
            System.err.println("Failed to send push notification: " + e.getMessage());
            return false;
        }
    }
}
