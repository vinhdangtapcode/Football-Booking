import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/field.dart';
import '../models/booking.dart';
import '../models/rating.dart';
import '../models/favorite.dart';

const String baseUrl = "http://178.128.62.29:8080";

class ApiService {
  static String? _token;
  static User? _currentUser;
  static const String _tokenKey = 'jwt_token';
  static const String _userRoleKey = 'user_role';

  // Hàm tiện ích: nếu có token thì set Authorization.
  static Map<String, String> get headers {
    return {
      "Content-Type": "application/json",
      "bypass-tunnel-reminder": "true", // Bypass localtunnel warning
      if (_token != null) "Authorization": "Bearer $_token",
    };
  }

  // Set token manually (used for OAuth login)
  static void setToken(String token) {
    _token = token;
  }

  // Load token từ SharedPreferences khi khởi động app
  static Future<bool> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    if (savedToken != null && savedToken.isNotEmpty) {
      _token = savedToken;
      return true;
    }
    return false;
  }

  // Lưu token vào SharedPreferences
  static Future<void> saveToken(String token, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userRoleKey, role);
  }

  // Lấy role đã lưu
  static Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  // Xóa token khi logout
  static Future<void> clearToken() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userRoleKey);
  }

  // Kiểm tra xem có token không
  static bool hasToken() {
    return _token != null && _token!.isNotEmpty;
  }

  // Đăng nhập: POST /api/users/login
  static Future<String?> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/api/users/login");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data["token"];
      final role = data["role"] ?? "USER";
      // Lưu token vào SharedPreferences
      await saveToken(_token!, role);
      return _token;
    } else {
      // In log để debug thêm
      print("Login failed. Status: ${response.statusCode}. Body: ${response.body}");
      return null;
    }
  }

  // Đăng xuất: xóa token
  static Future<void> logout() async {
    await clearToken();
  }

  // Đăng ký người dùng: POST /api/users/register
  static Future<bool> register(Map<String, dynamic> userData) async {
    final url = Uri.parse("$baseUrl/api/users/register");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(userData),
    );
    return response.statusCode == 201;
  }

  // Lấy danh sách sân công cộng: GET /danh-sach-san
  static Future<List<Field>> getPublicFields() async {
    final url = Uri.parse("$baseUrl/danh-sach-san");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Field.fromJson(json)).toList();
    }
    return [];
  }

  // Lấy danh sách sân theo Admin: GET /api/stadiums
  static Future<List<Field>> getFields() async {
    final url = Uri.parse("$baseUrl/api/stadiums");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Field.fromJson(json)).toList();
    }
    return [];
  }

  // Xác nhận đặt sân: POST /dat-san/xac-nhan
  static Future<bool> confirmBooking(int fieldId, DateTime from, DateTime to) async {
    final url = Uri.parse("$baseUrl/dat-san/xac-nhan");
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "field": {"id": fieldId},
        "from": from.toIso8601String(),
        "to": to.toIso8601String(),
      }),
    );
    return response.statusCode == 201;
  }

  static Future<bool> confirmBookingWithAdditional(int fieldId, DateTime from, DateTime to, String additional) async {
    final url = Uri.parse("$baseUrl/dat-san/xac-nhan");
    final body = {
      "field": {"id": fieldId},
      "fromTime": from.toIso8601String(),
      "toTime": to.toIso8601String(),
      if (additional.isNotEmpty) "additional": additional,
    };
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    return response.statusCode == 201;
  }

  // Đổi mật khẩu: POST /change-password
  static Future<dynamic> changePassword(String oldPassword, String newPassword) async {
    final url = Uri.parse("$baseUrl/api/users/change-password");
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "oldPassword": oldPassword,
        "newPassword": newPassword,
      }),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      try {
        final data = jsonDecode(response.body);
        if (data is String) return data;
        if (data is Map && data['message'] != null) return data['message'];
      } catch (_) {}
      return response.body;
    }
  }

  // Lấy lịch sử đặt sân: GET /dat-san/lich-su-dat-san
  static Future<List<Booking>> getBookingHistory() async {
    final url = Uri.parse("$baseUrl/dat-san/lich-su-dat-san");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Booking.fromJson(json)).toList();
    }
    return [];
  }

  // Lấy danh sách sân yêu thích: GET /yeu-thich
  static Future<List<Field>> getFavorites() async {
    final url = Uri.parse("$baseUrl/yeu-thich");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Field.fromJson(json)).toList();
    }
    return [];
  }

  // Thêm sân yêu thích: POST /yeu-thich?fieldId=...
  static Future<void> addFavorite(int fieldId) async {
    final url = Uri.parse("$baseUrl/yeu-thich?fieldId=$fieldId");
    await http.post(url, headers: headers);
  }

  // Xóa sân yêu thích: DELETE /yeu-thich?fieldId=...
  static Future<void> removeFavorite(int fieldId) async {
    final url = Uri.parse("$baseUrl/yeu-thich?fieldId=$fieldId");
    await http.delete(url, headers: headers);
  }

  // Lấy danh sách đánh giá của 1 sân: GET /danh-gia-san/{fieldId}
  static Future<List<Rating>> getRatings(int fieldId) async {
    final url = Uri.parse("$baseUrl/danh-gia-san/$fieldId");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Rating.fromJson(json)).toList();
    }
    return [];
  }

  // Thêm đánh giá cho 1 sân: POST /danh-gia-san/them-danh-gia?fieldId=...
  static Future<bool> addRating(int fieldId, int score, String comment, bool isAnonymous) async {
    final url = Uri.parse("$baseUrl/danh-gia-san/them-danh-gia?fieldId=$fieldId");
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "score": score,
        "comment": comment,
        "isAnonymous": isAnonymous,
      }),
    );
    return response.statusCode == 201;
  }

  // Xóa đánh giá: DELETE /danh-gia-san/xoa-danh-gia/{ratingId}
  static Future<bool> deleteRating(int ratingId) async {
    final url = Uri.parse("$baseUrl/danh-gia-san/xoa-danh-gia/$ratingId");
    final response = await http.delete(url, headers: headers);
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // Cập nhật đánh giá: PUT /danh-gia-san/cap-nhat-danh-gia/{ratingId}
  static Future<bool> updateRating(int ratingId, int score, String comment, bool isAnonymous) async {
    final url = Uri.parse("$baseUrl/danh-gia-san/cap-nhat-danh-gia/$ratingId");
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode({
        "score": score,
        "comment": comment,
        "isAnonymous": isAnonymous,
      }),
    );
    return response.statusCode == 200;
  }

  // Lấy danh sách đánh giá của chính bạn: GET /danh-gia-san/danh-gia-cua-toi
  static Future<List<Rating>> getMyRatings() async {
    final url = Uri.parse("$baseUrl/danh-gia-san/danh-gia-cua-toi");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Rating.fromJson(json)).toList();
    }
    return [];
  }

  // Lấy danh sách sân của chủ sân: GET /api/owner/fields
  static Future<List<Field>> getOwnerFields() async {
    final url = Uri.parse("$baseUrl/api/owner/fields");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Field.fromJson(json)).toList();
    }
    return [];
  }

  // Thêm sân cho thuê: POST /api/owner/fields
  static Future<bool> createField(Field field) async {
    final url = Uri.parse("$baseUrl/api/owner/fields");
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(field.toJson()),
    );
    return response.statusCode == 201;
  }

  // Cập nhật thông tin sân: PUT /api/owner/fields/{id}
  static Future<bool> updateField(Field field) async {
    if (field.id == null) return false;
    final url = Uri.parse("$baseUrl/api/owner/fields/${field.id}");
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(field.toJson()),
    );
    return response.statusCode == 200;
  }

  // Xóa sân đã đăng: DELETE /api/owner/fields/{id}
  static Future<bool> deleteField(int fieldId) async {
    final url = Uri.parse("$baseUrl/api/owner/fields/$fieldId");
    final response = await http.delete(url, headers: headers);
    return response.statusCode == 204;
  }

  // Lấy lịch sử đặt sân cho 1 sân cụ thể (OWNER)
  static Future<List<Booking>> getBookingsForField(int fieldId) async {
    final url = Uri.parse("$baseUrl/api/owner/fields/$fieldId/bookings");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Booking.fromJson(json)).toList();
    }
    return [];
  }

  // Lấy các khung giờ đã được đặt cho một sân cụ thể
  static Future<List<Map<String, DateTime>>> getBookedTimes(int fieldId) async {
    final url = Uri.parse("$baseUrl/dat-san/$fieldId/booked-times");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map<Map<String, DateTime>>((json) => {
        'fromTime': DateTime.parse(json['fromTime']),
        'toTime': DateTime.parse(json['toTime']),
      }).toList();
    }
    return [];
  }

  // Lấy thông tin người dùng hiện tại: GET /api/users/me
  static Future<User?> getProfile() async {
    final url = Uri.parse("$baseUrl/api/users/me");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        _currentUser = User.fromJson(data);
        return _currentUser;
      }
      print("[getProfile] API trả về kiểu dữ liệu không xác định: "+data.runtimeType.toString());
      return null;
    }
    print("[getProfile] Lỗi lấy profile: "+response.statusCode.toString()+" - "+response.body);
    return null;
  }

  // Cập nhật thông tin người dùng: PUT /api/users
  static Future<User?> updateProfile(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/users");
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return User.fromJson(json);
    }
    return null;
  }

  // Cập nhật thông tin chủ sân: PUT /api/owner
  static Future<Map<String, dynamic>?> updateOwnerProfile(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/owner");
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // Lấy danh sách thông báo cho user/owner
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final url = Uri.parse("$baseUrl/api/users/notifications");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // Đánh dấu thông báo đã đọc
  static Future<bool> markNotificationAsRead(int id) async {
    final url = Uri.parse("$baseUrl/api/users/notifications/$id");
    final response = await http.put(url, headers: headers);
    return response.statusCode == 200;
  }

  // Xóa thông báo
  static Future<bool> deleteNotification(int id) async {
    final url = Uri.parse("$baseUrl/api/users/notifications/$id");
    final response = await http.delete(url, headers: headers);
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // Admin Field Management APIs

  // Lấy danh sách tất cả sân: GET /api/stadiums
  static Future<List<Field>> getAllStadiums() async {
    final url = Uri.parse("$baseUrl/api/stadiums");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Field.fromJson(json)).toList();
    }
    return [];
  }

  // Lấy thông tin sân theo ID: GET /api/stadiums/{id}
  static Future<Field?> getStadiumById(int id) async {
    final url = Uri.parse("$baseUrl/api/stadiums/$id");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return Field.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // Lấy danh sách sân cho user: GET /api/stadiums/danh-sach-san
  static Future<List<Field>> getStadiumsList() async {
    final url = Uri.parse("$baseUrl/api/stadiums/danh-sach-san");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Field.fromJson(json)).toList();
    }
    return [];
  }

  // ===== ADMIN METHODS =====

  // Thêm sân cho admin: POST /api/admin/fields
  static Future<bool> adminCreateField(Field field) async {
    final url = Uri.parse("$baseUrl/api/stadiums");
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(field.toJson()),
    );
    print('Admin Create Field - Status: ${response.statusCode}');
    print('Admin Create Field - Response: ${response.body}');
    return response.statusCode == 201 || response.statusCode == 200;
  }

  // Cập nhật thông tin sân cho admin: PUT /api/admin/fields/{id}
  static Future<bool> adminUpdateField(Field field) async {
    if (field.id == null) return false;
    final url = Uri.parse("$baseUrl/api/stadiums/${field.id}");
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(field.toJson()),
    );
    print('Admin Update Field - Status: ${response.statusCode}');
    print('Admin Update Field - Response: ${response.body}');
    return response.statusCode == 200;
  }

  // Xóa sân cho admin: DELETE /api/admin/fields/{id}
  static Future<bool> adminDeleteField(int fieldId) async {
    final url = Uri.parse("$baseUrl/api/stadiums/$fieldId");
    final response = await http.delete(url, headers: headers);
    print('Admin Delete Field - Status: ${response.statusCode}');
    print('Admin Delete Field - Response: ${response.body}');
    return response.statusCode == 204 || response.statusCode == 200;
  }

  // ===== END ADMIN METHODS =====

  // ===== ADMIN USER MANAGEMENT =====

  // Lấy danh sách tất cả người dùng: GET /api/users
  static Future<List<User>> getAllUsers() async {
    final url = Uri.parse("$baseUrl/api/users");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    }
    return [];
  }

  // Lấy thông tin người dùng theo ID: GET /api/users/{id}
  static Future<User?> getUserById(int userId) async {
    final url = Uri.parse("$baseUrl/api/users/$userId");
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // Cập nhật thông tin người dùng (admin): PUT /api/users/{id}
  static Future<bool> adminUpdateUser(int userId, Map<String, dynamic> userData) async {
    final url = Uri.parse("$baseUrl/api/users/$userId");
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(userData),
    );
    return response.statusCode == 200;
  }

  // Xóa người dùng: DELETE /api/users/{id}
  static Future<bool> adminDeleteUser(int userId) async {
    final url = Uri.parse("$baseUrl/api/users/$userId");
    final response = await http.delete(url, headers: headers);
    return response.statusCode == 204 || response.statusCode == 200;
  }

  // Cập nhật trạng thái người dùng: PUT /api/users/{id}/status
  static Future<bool> adminUpdateUserStatus(int userId, bool isActive) async {
    final url = Uri.parse("$baseUrl/api/users/$userId/status");
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode({"isActive": isActive}),
    );
    return response.statusCode == 200;
  }

  // Đặt lại mật khẩu người dùng: PUT /api/users/{id}/reset-password
  static Future<bool> adminResetUserPassword(int userId, String newPassword) async {
    final url = Uri.parse("$baseUrl/api/users/$userId/reset-password");
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({"newPassword": newPassword}),
    );

    print('Admin Reset Password - User ID: $userId');
    print('Admin Reset Password - Status: ${response.statusCode}');
    print('Admin Reset Password - Response: ${response.body}');

    return response.statusCode == 200;
  }

  // Cập nhật FCM token cho user hiện tại
  static Future<bool> updateFcmToken(String fcmToken) async {
    final url = Uri.parse("$baseUrl/api/users/fcm-token");
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({"fcmToken": fcmToken}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating FCM token: $e');
      return false;
    }
  }

  // ===== CHAT METHODS =====

  // Tạo hoặc lấy cuộc hội thoại: POST /api/chat/conversations
  static Future<Map<String, dynamic>?> getOrCreateConversation(int userId, int ownerId, int? fieldId) async {
    final url = Uri.parse("$baseUrl/api/chat/conversations");
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "userId": userId,
          "ownerId": ownerId,
          "fieldId": fieldId,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error creating conversation: $e');
    }
    return null;
  }

  // Lấy danh sách cuộc hội thoại của user: GET /api/chat/conversations/user/{userId}
  static Future<List<Map<String, dynamic>>> getConversationsForUser(int userId) async {
    final url = Uri.parse("$baseUrl/api/chat/conversations/user/$userId");
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error getting conversations: $e');
    }
    return [];
  }

  // Lấy danh sách cuộc hội thoại của owner: GET /api/chat/conversations/owner/{ownerId}
  static Future<List<Map<String, dynamic>>> getConversationsForOwner(int ownerId) async {
    final url = Uri.parse("$baseUrl/api/chat/conversations/owner/$ownerId");
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error getting owner conversations: $e');
    }
    return [];
  }

  // Lấy danh sách cuộc hội thoại của owner theo email: GET /api/chat/conversations/owner/email/{email}
  static Future<List<Map<String, dynamic>>> getConversationsForOwnerByEmail(String email) async {
    final url = Uri.parse("$baseUrl/api/chat/conversations/owner/email/$email");
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error getting owner conversations by email: $e');
    }
    return [];
  }

  // Lấy owner ID theo email: GET /api/chat/owner-id/{email}
  static Future<int?> getOwnerIdByEmail(String email) async {
    final url = Uri.parse("$baseUrl/api/chat/owner-id/$email");
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ownerId'];
      }
    } catch (e) {
      print('Error getting owner ID: $e');
    }
    return null;
  }

  // Lấy tin nhắn của cuộc hội thoại: GET /api/chat/conversations/{conversationId}/messages
  static Future<List<Map<String, dynamic>>> getMessages(int conversationId) async {
    final url = Uri.parse("$baseUrl/api/chat/conversations/$conversationId/messages");
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error getting messages: $e');
    }
    return [];
  }

  // Gửi tin nhắn: POST /api/chat/messages
  static Future<Map<String, dynamic>?> sendMessage(int conversationId, String senderType, int senderId, String content) async {
    final url = Uri.parse("$baseUrl/api/chat/messages");
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "conversationId": conversationId,
          "senderType": senderType,
          "senderId": senderId,
          "content": content,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error sending message: $e');
    }
    return null;
  }

  // Đánh dấu tin nhắn đã đọc: POST /api/chat/conversations/{conversationId}/read
  static Future<bool> markMessagesAsRead(int conversationId, String readerType) async {
    final url = Uri.parse("$baseUrl/api/chat/conversations/$conversationId/read");
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"readerType": readerType}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking as read: $e');
      return false;
    }
  }

  // ===== END CHAT METHODS =====
}
