import 'package:flutter/material.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String _selectedFilter = 'ALL';

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;

  List<Map<String, dynamic>> get filteredNotifications {
    if (_selectedFilter == 'ALL') return _notifications;
    if (_selectedFilter == 'BOOKING_CANCELLED') {
      return _notifications.where((n) {
        final type = (n['type'] ?? '').toString();
        return type == 'BOOKING_CANCELLED_BY_USER' || type == 'BOOKING_CANCELLED_BY_ADMIN';
      }).toList();
    }
    if (_selectedFilter == 'SYSTEM') {
      return _notifications.where((n) {
        final type = (n['type'] ?? '').toString();
        return type == 'SYSTEM_BROADCAST' || type == 'SYSTEM_MAINTENANCE';
      }).toList();
    }
    return _notifications.where((n) => (n['type'] ?? 'GENERAL') == _selectedFilter).toList();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final notis = await NotificationRepository.getNotifications();
      notis.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
      _notifications = notis;
    } catch (e) {
      print("Error loading notifications in provider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<bool> markAsRead(int id) async {
    try {
      final success = await NotificationRepository.markNotificationAsRead(id);
      if (success) {
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1) {
          _notifications[index]['read'] = true;
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      print("Error marking notification as read in provider: $e");
      return false;
    }
  }

  Future<bool> deleteNotification(int id) async {
    try {
      final success = await NotificationRepository.deleteNotification(id);
      if (success) {
        _notifications.removeWhere((n) => n['id'] == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print("Error deleting notification in provider: $e");
      return false;
    }
  }
}
