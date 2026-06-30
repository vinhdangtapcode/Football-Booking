import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../core/network/api_client.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    try {
      final hasToken = await ApiClient.loadSavedToken();
      if (hasToken) {
        final user = await AuthRepository.getCurrentUser();
        if (user != null) {
          _currentUser = user;
          _isAuthenticated = true;
          return true;
        }
      }
    } catch (e) {
      print("Error checking auth status in provider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    _isAuthenticated = false;
    _currentUser = null;
    return false;
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final role = await AuthRepository.login(email, password);
      if (role != null) {
        final user = await AuthRepository.getCurrentUser();
        if (user != null) {
          _currentUser = user;
          _isAuthenticated = true;
          return role;
        }
      }
    } catch (e) {
      print("Error in login provider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<String?> loginWithGoogleToken(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      await ApiClient.saveToken(token, 'CUSTOMER');
      final user = await AuthRepository.getCurrentUser();
      if (user != null) {
        await ApiClient.saveToken(token, user.role);
        _currentUser = user;
        _isAuthenticated = true;
        return user.role;
      }
    } catch (e) {
      print("Error in Google token login provider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await AuthRepository.register(userData);
      return success;
    } catch (e) {
      print("Error in register provider: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await AuthRepository.logout();
      _currentUser = null;
      _isAuthenticated = false;
    } catch (e) {
      print("Error in logout provider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    try {
      final user = await AuthRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      print("Error refreshing profile: $e");
    }
  }
}
