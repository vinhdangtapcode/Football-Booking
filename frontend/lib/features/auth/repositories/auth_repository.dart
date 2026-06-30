import 'dart:convert';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../models/user.dart';

class AuthRepository {
  static Future<String?> login(String email, String password) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.login,
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final token = data['token'];
        final role = data['role'];
        if (token != null && role != null) {
          await ApiClient.saveToken(token, role);
          return role;
        }
      }
    } catch (e) {
      print("Login error: $e");
    }
    return null;
  }

  static Future<bool> register(Map<String, dynamic> userData) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.register,
        body: jsonEncode(userData),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Register error: $e");
      return false;
    }
  }

  static Future<void> logout() async {
    await ApiClient.clearToken();
  }

  static Future<User?> getCurrentUser() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.currentUser);
      if (response.statusCode == 200) {
        final user = User.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
        ApiClient.currentUser = user;
        return user;
      }
    } catch (e) {
      print("Error fetching current user: $e");
    }
    return null;
  }
}
