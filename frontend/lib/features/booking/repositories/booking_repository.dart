import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../models/booking.dart';

class BookingRepository {
  static Future<bool> confirmBooking(int fieldId, DateTime from, DateTime to) async {
    try {
      final response = await ApiClient.post(
        '/dat-san/xac-nhan',
        body: jsonEncode({
          "field": {"id": fieldId},
          "from": from.toIso8601String(),
          "to": to.toIso8601String(),
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error in confirmBooking: $e");
      return false;
    }
  }

  static Future<Booking?> confirmBookingWithAdditional(
      int fieldId, DateTime from, DateTime to, String additional) async {
    final body = {
      "field": {"id": fieldId},
      "fromTime": from.toIso8601String(),
      "toTime": to.toIso8601String(),
      if (additional.isNotEmpty) "additional": additional,
    };
    try {
      final response = await ApiClient.post(
        '/dat-san/xac-nhan',
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return Booking.fromJson(decoded);
      } else {
        String msg = "Lỗi đặt sân";
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          msg = decoded["message"] ?? decoded["error"] ?? "Lỗi đặt sân";
        } catch (_) {
          msg = utf8.decode(response.bodyBytes);
          if (msg.isEmpty) {
            msg = "Lỗi hệ thống (Status code: ${response.statusCode})";
          }
        }
        throw Exception(msg);
      }
    } catch (e) {
      print("Error creating booking: $e");
      rethrow;
    }
  }

  static Future<Booking?> getBookingById(int id) async {
    try {
      final response = await ApiClient.get('/dat-san/lich-su-dat-san/$id');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return Booking.fromJson(decoded);
      }
    } catch (e) {
      print("Error fetching booking by id $id: $e");
    }
    return null;
  }

  static Future<bool> cancelBooking(int bookingId) async {
    try {
      final response = await ApiClient.post('/dat-san/$bookingId/huy-san');
      return response.statusCode == 200;
    } catch (e) {
      print("Error cancelling booking: $e");
      return false;
    }
  }

  static Future<List<Booking>> getBookingHistory() async {
    try {
      final response = await ApiClient.get('/dat-san/lich-su-dat-san');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Booking.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error in getBookingHistory: $e");
    }
    return [];
  }

  static Future<List<Map<String, DateTime>>> getBookedTimes(int fieldId) async {
    try {
      final response = await ApiClient.get('/dat-san/$fieldId/booked-times');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map<Map<String, DateTime>>((json) => {
          'fromTime': DateTime.parse(json['fromTime']),
          'toTime': DateTime.parse(json['toTime']),
        }).toList();
      }
    } catch (e) {
      print("Error in getBookedTimes: $e");
    }
    return [];
  }
}
