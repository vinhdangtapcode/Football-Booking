import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart' show navigatorKey;
import '../constants/app_constants.dart';
import '../../models/user.dart';

class ApiClient {
  static String? _token;
  static User? _currentUser;

  static User? get currentUser => _currentUser;
  static set currentUser(User? user) => _currentUser = user;

  static String? get token => _token;

  static Map<String, String> get headers {
    return {
      "Content-Type": "application/json",
      "bypass-tunnel-reminder": "true",
      if (_token != null) "Authorization": "Bearer $_token",
    };
  }

  static void setToken(String token) {
    _token = token;
  }

  static Future<bool> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(AppConstants.tokenKey);
    if (savedToken != null && savedToken.isNotEmpty) {
      _token = savedToken;
      return true;
    }
    return false;
  }

  static Future<void> saveToken(String token, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userRoleKey, role);
    _token = token;
  }

  static Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userRoleKey);
  }

  static Future<void> clearToken() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userRoleKey);
  }

  static bool hasToken() {
    return _token != null && _token!.isNotEmpty;
  }

  static void _check(http.Response res) {
    if (res.statusCode == 503) {
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['maintenance'] == true) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(AppConstants.maintenance, (route) => false);
        }
      } catch (_) {}
    }
  }

  static Future<http.Response> get(String path, {Map<String, String>? customHeaders}) async {
    final url = Uri.parse("${AppConstants.baseUrl}$path");
    final res = await http.get(url, headers: customHeaders ?? headers);
    _check(res);
    return res;
  }

  static Future<http.Response> post(String path, {Map<String, String>? customHeaders, Object? body}) async {
    final url = Uri.parse("${AppConstants.baseUrl}$path");
    final res = await http.post(url, headers: customHeaders ?? headers, body: body);
    _check(res);
    return res;
  }

  static Future<http.Response> put(String path, {Map<String, String>? customHeaders, Object? body}) async {
    final url = Uri.parse("${AppConstants.baseUrl}$path");
    final res = await http.put(url, headers: customHeaders ?? headers, body: body);
    _check(res);
    return res;
  }

  static Future<http.Response> patch(String path, {Map<String, String>? customHeaders, Object? body}) async {
    final url = Uri.parse("${AppConstants.baseUrl}$path");
    final res = await http.patch(url, headers: customHeaders ?? headers, body: body);
    _check(res);
    return res;
  }

  static Future<http.Response> delete(String path, {Map<String, String>? customHeaders, Object? body}) async {
    final url = Uri.parse("${AppConstants.baseUrl}$path");
    final res = await http.delete(url, headers: customHeaders ?? headers, body: body);
    _check(res);
    return res;
  }

  static Future<http.StreamedResponse> sendMultipartRequest(
    String method,
    String path,
    List<http.MultipartFile> files, {
    Map<String, String>? fields,
  }) async {
    final url = Uri.parse("${AppConstants.baseUrl}$path");
    final request = http.MultipartRequest(method, url);

    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    request.files.addAll(files);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final streamedResponse = await request.send();
    if (streamedResponse.statusCode == 503) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(AppConstants.maintenance, (route) => false);
    }
    return streamedResponse;
  }

  static String? resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return "${AppConstants.baseUrl}$url";
  }
}
