import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../models/rating.dart';

class RatingRepository {
  static Future<List<Rating>> getRatings(int fieldId) async {
    try {
      final response = await ApiClient.get('/danh-gia-san/$fieldId');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Rating.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error in getRatings: $e");
    }
    return [];
  }

  static Future<bool> addRating(int fieldId, int score, String comment, bool isAnonymous) async {
    try {
      final response = await ApiClient.post(
        '/danh-gia-san/them-danh-gia?fieldId=$fieldId',
        body: jsonEncode({
          "score": score,
          "comment": comment,
          "isAnonymous": isAnonymous,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error in addRating: $e");
      return false;
    }
  }

  static Future<bool> deleteRating(int ratingId) async {
    try {
      final response = await ApiClient.delete('/danh-gia-san/xoa-danh-gia/$ratingId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error in deleteRating: $e");
      return false;
    }
  }

  static Future<bool> updateRating(int ratingId, int score, String comment, bool isAnonymous) async {
    try {
      final response = await ApiClient.put(
        '/danh-gia-san/cap-nhat-danh-gia/$ratingId',
        body: jsonEncode({
          "score": score,
          "comment": comment,
          "isAnonymous": isAnonymous,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error in updateRating: $e");
      return false;
    }
  }

  static Future<List<Rating>> getMyRatings() async {
    try {
      final response = await ApiClient.get('/danh-gia-san/danh-gia-cua-toi');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Rating.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error in getMyRatings: $e");
    }
    return [];
  }
}
