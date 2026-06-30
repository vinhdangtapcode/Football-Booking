import 'dart:convert';
import '../../../core/network/api_client.dart';

class NotificationRepository {
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await ApiClient.get('/api/users/notifications');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    }
    return [];
  }

  static Future<bool> markNotificationAsRead(int id) async {
    try {
      final response = await ApiClient.put('/api/users/notifications/$id');
      return response.statusCode == 200;
    } catch (e) {
      print("Error marking notification as read: $e");
      return false;
    }
  }

  static Future<bool> deleteNotification(int id) async {
    try {
      final response = await ApiClient.delete('/api/users/notifications/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error deleting notification: $e");
      return false;
    }
  }

  static Future<bool> updateFcmToken(String fcmToken) async {
    try {
      final response = await ApiClient.put(
        '/api/users/fcm-token',
        body: jsonEncode({"fcmToken": fcmToken}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating FCM token: $e');
      return false;
    }
  }
}
