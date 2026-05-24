import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Service for handling Google Sign-In authentication
class GoogleAuthService {
  // Web Client ID from Google Cloud Console
  static const String _webClientId = '334792422667-cmorccm477uacp7b99vkf06qii2a1a8a.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // serverClientId is required to get idToken on Android
    serverClientId: _webClientId,
  );

  /// Sign in with Google and authenticate with backend
  /// Returns JWT token if successful, null otherwise
  static Future<String?> signInWithGoogle() async {
    try {
      // Sign out first to ensure fresh sign-in
      await _googleSignIn.signOut();
      
      print('Starting Google Sign-In...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        print('Google Sign-In cancelled by user');
        return null;
      }

      print('Google Sign-In successful: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print('Got authentication. AccessToken: ${googleAuth.accessToken != null ? "Yes" : "No"}, IdToken: ${googleAuth.idToken != null ? "Yes" : "No"}');
      
      // Get ID token
      final String? idToken = googleAuth.idToken;
      
      if (idToken == null) {
        print('Failed to get Google ID token. Make sure serverClientId is configured correctly.');
        print('Current serverClientId: $_webClientId');
        return null;
      }

      print('Got ID token, sending to backend...');

      // Send ID token to backend for verification
      final token = await _authenticateWithBackend(idToken);
      return token;
      
    } catch (error, stackTrace) {
      print('Google Sign-In error: $error');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Sign out from Google
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      print('Google Sign-Out error: $error');
    }
  }

  /// Check if user is currently signed in with Google
  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Get current Google user (if signed in)
  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Send Google ID token to backend for verification
  static Future<String?> _authenticateWithBackend(String idToken) async {
    try {
      final url = Uri.parse("$baseUrl/api/auth/google");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Backend auth successful!');
        return data["token"];
      } else {
        print('Backend auth failed. Status: ${response.statusCode}. Body: ${response.body}');
        return null;
      }
    } catch (error) {
      print('Backend auth error: $error');
      return null;
    }
  }
}
