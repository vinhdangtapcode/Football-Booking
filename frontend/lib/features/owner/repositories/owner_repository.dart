import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../models/field.dart';
import '../../../models/booking.dart';

class OwnerRepository {
  static Future<List<Field>> getOwnerFields() async {
    try {
      final response = await ApiClient.get('/api/owner/fields');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Field.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error in getOwnerFields: $e");
    }
    return [];
  }

  static Future<Field?> createField(Field field) async {
    try {
      final response = await ApiClient.post(
        '/api/owner/fields',
        body: jsonEncode(field.toJson()),
      );
      if (response.statusCode == 201) {
        return Field.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) {
      print("Error in createField: $e");
    }
    return null;
  }

  static Future<bool> updateField(Field field) async {
    if (field.id == null) return false;
    try {
      final response = await ApiClient.put(
        '/api/owner/fields/${field.id}',
        body: jsonEncode(field.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error in updateField: $e");
      return false;
    }
  }

  static Future<bool> deleteField(int fieldId) async {
    try {
      final response = await ApiClient.delete('/api/owner/fields/$fieldId');
      return response.statusCode == 204;
    } catch (e) {
      print("Error in deleteField: $e");
      return false;
    }
  }

  static Future<List<Booking>> getBookingsForField(int fieldId) async {
    try {
      final response = await ApiClient.get('/api/owner/fields/$fieldId/bookings');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Booking.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error in getBookingsForField: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>?> updateOwnerProfile(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.put(
        '/api/owner',
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Error in updateOwnerProfile: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>> getOwnerRevenue() async {
    try {
      final response = await ApiClient.get('/api/owner/revenue');
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data;
      }
    } catch (e) {
      print("Error in getOwnerRevenue: $e");
    }
    return {"totalPlatformHeld": 0.0, "bookings": []};
  }

  static Future<bool> updateOwnerBankDetails(
      String bankName, String bankAccountNo, String bankAccountName) async {
    try {
      final response = await ApiClient.put(
        '/api/owner/bank-details',
        body: jsonEncode({
          "bankName": bankName,
          "bankAccountNo": bankAccountNo,
          "bankAccountName": bankAccountName,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error in updateOwnerBankDetails: $e");
      return false;
    }
  }
}
