import 'package:flutter/material.dart';
import '../../../models/booking.dart';
import '../repositories/booking_repository.dart';
import '../../../services/api_service.dart';

class BookingProvider extends ChangeNotifier {
  List<Booking> _bookings = [];
  bool _isLoading = false;

  // Trạng thái cho màn hình đặt sân hiện tại
  DateTime _selectedDate = DateTime.now();
  List<Map<String, DateTime>> _bookedTimes = [];
  Set<int> _selectedSlots = {};
  bool _isFetchingSlots = false;
  int? _currentViewingFieldId;
  String? _conflictMessage;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  
  DateTime get selectedDate => _selectedDate;
  List<Map<String, DateTime>> get bookedTimes => _bookedTimes;
  Set<int> get selectedSlots => _selectedSlots;
  bool get isFetchingSlots => _isFetchingSlots;
  int? get currentViewingFieldId => _currentViewingFieldId;
  String? get conflictMessage => _conflictMessage;

  void setCurrentViewingFieldId(int? fieldId) {
    _currentViewingFieldId = fieldId;
  }

  void clearConflictMessage() {
    _conflictMessage = null;
  }

  bool _isSlotHourBooked(int hour) {
    final slotStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour, 0);
    final slotEnd = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour + 1, 0);
    
    for (final booking in _bookedTimes) {
      final bookedFrom = booking['fromTime']!;
      final bookedTo = booking['toTime']!;
      
      // Kiểm tra xem slot có nằm trong cùng ngày và overlap với booking không
      if (slotStart.year == bookedFrom.year && 
          slotStart.month == bookedFrom.month && 
          slotStart.day == bookedFrom.day) {
        if (slotStart.isBefore(bookedTo) && slotEnd.isAfter(bookedFrom)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> fetchBookedTimes(int fieldId) async {
    _isFetchingSlots = true;
    notifyListeners();
    try {
      final times = await ApiService.getBookedTimes(fieldId);
      _bookedTimes = times;

      // Kiểm tra và đẩy các slot bị trùng ra
      if (_selectedSlots.isNotEmpty) {
        final List<int> removedSlots = [];
        for (final hour in List.from(_selectedSlots)) {
          if (_isSlotHourBooked(hour)) {
            _selectedSlots.remove(hour);
            removedSlots.add(hour);
          }
        }
        
        if (removedSlots.isNotEmpty) {
          removedSlots.sort();
          final fromStr = "${removedSlots.first.toString().padLeft(2, '0')}:00";
          final toStr = "${(removedSlots.last + 1).toString().padLeft(2, '0')}:00";
          _conflictMessage = "Khung giờ $fromStr - $toStr vừa có người đặt. Hệ thống đã tự động bỏ chọn cho bạn!";
        }
      }
    } catch (e) {
      print("Error fetching booked times in provider: $e");
    } finally {
      _isFetchingSlots = false;
      notifyListeners();
    }
  }

  void selectDate(DateTime date, int fieldId) {
    _selectedDate = date;
    _selectedSlots.clear(); // Xóa các slot đã chọn của ngày cũ
    notifyListeners();
    fetchBookedTimes(fieldId);
  }

  void toggleSlot(int hour) {
    if (_selectedSlots.contains(hour)) {
      _selectedSlots.remove(hour);
    } else {
      _selectedSlots.add(hour);
    }
    notifyListeners();
  }

  void resetBookingSelection() {
    _selectedSlots.clear();
    _selectedDate = DateTime.now();
    _bookedTimes = [];
  }


  Future<void> loadBookingHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await BookingRepository.getBookingHistory();
      // Sắp xếp đơn đặt mới nhất lên đầu
      list.sort((a, b) {
        final timeCompare = b.fromTime.compareTo(a.fromTime);
        if (timeCompare != 0) {
          return timeCompare;
        }
        if (a.id != null && b.id != null) {
          return b.id!.compareTo(a.id!);
        }
        return 0;
      });
      _bookings = list;
    } catch (e) {
      print("Error in loadBookingHistory provider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Booking?> createBooking({
    required int fieldId,
    required DateTime from,
    required DateTime to,
    required String additional,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final booking = await BookingRepository.confirmBookingWithAdditional(fieldId, from, to, additional);
      if (booking != null) {
        _bookings.insert(0, booking);
        notifyListeners();
        return booking;
      }
    } catch (e) {
      print("Error in createBooking provider: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> cancelBooking(int bookingId) async {
    try {
      final success = await BookingRepository.cancelBooking(bookingId);
      if (success) {
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          // Cập nhật trạng thái hủy ở local
          _bookings[index].status = 'CANCELLED';
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      print("Error cancelling booking in provider: $e");
    }
    return false;
  }
}
