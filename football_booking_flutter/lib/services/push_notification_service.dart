import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Service for handling Firebase Cloud Messaging (Push Notifications)
class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Callback để navigate khi tap notification
  static GlobalKey<NavigatorState>? navigatorKey;
  
  // Flag để biết app được mở từ notification hay không
  static bool openedFromNotification = false;

  /// Initialize Firebase and notification settings
  static Future<void> initialize() async {
    // Request notification permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token and send to backend
    await _setupToken();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle when user taps on notification (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification (app was terminated)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from notification (FCM - terminated state)');
      openedFromNotification = true;
    } else {
      // Fallback: Check if opened via local notification click (requires launch details)
      try {
        final NotificationAppLaunchDetails? notificationAppLaunchDetails = 
          await _localNotifications.getNotificationAppLaunchDetails();
        
        if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
          print('App opened from notification (Local Notification - terminated state)');
          openedFromNotification = true;
        }
      } catch (e) {
        print('Error checking local notification launch details: $e');
      }
    }
  }

  /// Request notification permission
  static Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('Notification permission status: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications for foreground display
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle local notification tap (foreground)
        print('Local notification tapped: ${response.payload}');
        _navigateToNotifications();
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'football_booking_channel',
      'Football Booking Notifications',
      description: 'Thông báo từ ứng dụng đặt sân bóng',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Get FCM token and send to backend
  static Future<void> _setupToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      if (token != null) {
        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        // Token will be sent to backend after login via sendTokenToBackend()
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', newToken);
        await _sendTokenToBackend(newToken);
      });
    } catch (e) {
      print('Error setting up FCM token: $e');
    }
  }

  /// Public method to send FCM token to backend after login
  static Future<void> sendTokenToBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('fcm_token');
      
      if (token == null) {
        token = await _firebaseMessaging.getToken();
        if (token != null) {
          await prefs.setString('fcm_token', token);
        }
      }
      
      if (token != null) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      print('Error sending FCM token to backend: $e');
    }
  }

  /// Send FCM token to backend
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final result = await ApiService.updateFcmToken(token);
      if (result) {
        print('FCM token sent to backend successfully');
      } else {
        print('Failed to send FCM token to backend');
      }
    } catch (e) {
      print('Failed to send FCM token to backend: $e');
    }
  }

  /// Handle foreground message
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'football_booking_channel',
            'Football Booking Notifications',
            channelDescription: 'Thông báo từ ứng dụng đặt sân bóng',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle notification tap - navigate to notifications screen
  static void _handleNotificationTap(RemoteMessage message) {
    print('FCM Notification tapped: ${message.notification?.title}');
    print('FCM Message data: ${message.data}');
    _navigateToNotifications();
  }

  /// Navigate to notifications screen using global navigatorKey
  static Future<void> _navigateToNotifications() async {
    print('_navigateToNotifications called');
    
    // Đợi một chút để đảm bảo navigation sẵn sàng
    await Future.delayed(Duration(milliseconds: 500));
    
    print('navigatorKey: $navigatorKey');
    print('navigatorKey?.currentState: ${navigatorKey?.currentState}');
    
    if (navigatorKey?.currentState == null) {
      print('Navigator not ready, cannot navigate');
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role') ?? 'USER';
      print('User role: $role');
      
      final route = role == 'OWNER' ? '/ownerNotifications' : '/notifications';
      print('Navigating to: $route');
      
      navigatorKey!.currentState!.pushNamed(route);
      print('Navigation successful');
    } catch (e) {
      print('Error navigating to notifications: $e');
    }
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

/// Handle background messages (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}
