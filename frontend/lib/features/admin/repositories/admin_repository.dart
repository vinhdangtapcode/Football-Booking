import 'dart:convert';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../models/field.dart';

class AdminRepository {
  static Future<List<Field>> getAllStadiums() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.adminStadiumsBase);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((item) => Field.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error fetching all stadiums: $e");
    }
    return [];
  }
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.adminDashboardStats);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Error fetching admin stats: $e");
    }
    return {};
  }

  static Future<List<dynamic>> getAdminBookings() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.adminBookings);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Error fetching admin bookings: $e");
    }
    return [];
  }

  static Future<bool> approveBooking(int bookingId) async {
    try {
      final response = await ApiClient.post("${ApiEndpoints.adminBookings}/$bookingId/approve");
      return response.statusCode == 200;
    } catch (e) {
      print("Error approving booking $bookingId: $e");
      return false;
    }
  }

  static Future<bool> cancelBooking(int bookingId) async {
    try {
      final response = await ApiClient.post("${ApiEndpoints.adminBookings}/$bookingId/cancel");
      return response.statusCode == 200;
    } catch (e) {
      print("Error cancelling booking $bookingId: $e");
      return false;
    }
  }

  static Future<bool> toggleLock(int userId) async {
    try {
      final response = await ApiClient.patch("${ApiEndpoints.adminUsers}/$userId/toggle-lock");
      return response.statusCode == 200;
    } catch (e) {
      print("Error toggling lock for user $userId: $e");
      return false;
    }
  }

  static Future<bool> toggleFieldAvailability(int fieldId) async {
    try {
      final response = await ApiClient.patch("${ApiEndpoints.adminFields}/$fieldId/toggle-availability");
      return response.statusCode == 200;
    } catch (e) {
      print("Error toggling field availability $fieldId: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>> getAdminRevenue() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.adminRevenue);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Error fetching admin revenue: $e");
    }
    return {"totalPlatformHeld": 0.0, "bookings": []};
  }

  static Future<List<dynamic>> getAdminOwnersRevenue() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.adminOwnersRevenue);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Error fetching admin owners revenue: $e");
    }
    return [];
  }

  static Future<bool> settleOwner(int ownerId) async {
    try {
      final response = await ApiClient.post("${ApiEndpoints.adminSettle}/$ownerId");
      return response.statusCode == 200;
    } catch (e) {
      print("Error settling owner $ownerId: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getAdminOwners() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.adminOwners);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Error fetching admin owners: $e");
    }
    return [];
  }

  static Future<bool> adminCreateOwner(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.adminOwners,
        body: jsonEncode(data),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error creating owner: $e");
      return false;
    }
  }

  static Future<bool> adminUpdateOwner(int id, Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.put(
        "${ApiEndpoints.adminOwners}/$id",
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating owner $id: $e");
      return false;
    }
  }

  static Future<bool> adminDeleteOwner(int id) async {
    try {
      final response = await ApiClient.delete("${ApiEndpoints.adminOwners}/$id");
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print("Error deleting owner $id: $e");
      return false;
    }
  }

  static Future<bool> adminBroadcastNotification(String title, String body) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.adminBroadcast,
        body: jsonEncode({"title": title, "body": body}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error broadcasting notification: $e");
      return false;
    }
  }

  static Future<bool> adminResetPassword(int userId, String newPassword) async {
    try {
      final response = await ApiClient.post(
        "${ApiEndpoints.adminUsers}/$userId/reset-password",
        body: jsonEncode({"newPassword": newPassword}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error resetting password: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getAdminConfigs() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.adminConfig);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Error fetching configs: $e");
    }
    return [];
  }

  static Future<bool> updateAdminConfig(String key, String value) async {
    try {
      final response = await ApiClient.put(
        "${ApiEndpoints.adminConfig}/$key",
        body: jsonEncode({"value": value}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating config: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getAdminAuditLogs() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.adminAuditLog);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Error fetching audit logs: $e");
    }
    return [];
  }
}
