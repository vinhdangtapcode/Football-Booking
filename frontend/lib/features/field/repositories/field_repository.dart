import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../models/field.dart';

class FieldRepository {
  static Future<List<Field>> getPublicFields() async {
    try {
      final response = await ApiClient.get('/danh-sach-san');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Field.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error in getPublicFields: $e");
    }
    return [];
  }

  static Future<List<Field>> getFields() async {
    try {
      final response = await ApiClient.get('/api/stadiums');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Field.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error in getFields: $e");
    }
    return [];
  }

  static Future<List<Field>> getFavorites() async {
    try {
      final response = await ApiClient.get('/yeu-thich');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Field.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error in getFavorites: $e");
    }
    return [];
  }

  static Future<bool> addFavorite(int fieldId) async {
    try {
      final response = await ApiClient.post('/yeu-thich?fieldId=$fieldId');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error in addFavorite: $e");
      return false;
    }
  }

  static Future<bool> removeFavorite(int fieldId) async {
    try {
      final response = await ApiClient.delete('/yeu-thich?fieldId=$fieldId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error in removeFavorite: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getFieldImages(int fieldId) async {
    try {
      final response = await ApiClient.get('/api/images/field/$fieldId');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((img) {
          final map = Map<String, dynamic>.from(img);
          map['url'] = ApiClient.resolveImageUrl(map['url']);
          return map;
        }).toList();
      }
    } catch (e) {
      print("Error in getFieldImages: $e");
    }
    return [];
  }
}
