import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../models/user.dart';

class UserRepository {
  static User? _currentUser;

  static User? get currentUser => _currentUser;

  static Future<User?> getProfile() async {
    try {
      final response = await ApiClient.get('/api/users/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) {
          _currentUser = User.fromJson(data);
          return _currentUser;
        }
        print("[getProfile] API returned unknown format: " + data.runtimeType.toString());
        return null;
      }
      print("[getProfile] Error fetching profile: " + response.statusCode.toString());
    } catch (e) {
      print("Error in getProfile: $e");
    }
    return null;
  }

  static Future<User?> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.put(
        '/api/users',
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        _currentUser = User.fromJson(json);
        return _currentUser;
      }
    } catch (e) {
      print("Error in updateProfile: $e");
    }
    return null;
  }

  static Future<dynamic> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await ApiClient.post(
        '/api/users/change-password',
        body: jsonEncode({
          "oldPassword": oldPassword,
          "newPassword": newPassword,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data is String) return data;
          if (data is Map && data['message'] != null) return data['message'];
        } catch (_) {}
        return utf8.decode(response.bodyBytes);
      }
    } catch (e) {
      print("Error in changePassword: $e");
      return "Lỗi kết nối mạng";
    }
  }
}
