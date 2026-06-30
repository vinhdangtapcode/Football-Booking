import 'package:flutter/material.dart';
import '../../../models/booking.dart';
import '../repositories/booking_repository.dart';

class BookingProvider extends ChangeNotifier {
  List<Booking> _bookings = [];
  bool _isLoading = false;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;

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
