import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class MapService {

  // Lấy vị trí hiện tại của người dùng
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra xem GPS có được bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Kiểm tra quyền vị trí
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // Lấy vị trí hiện tại
    return await Geolocator.getCurrentPosition();
  }

  // Chuyển đổi địa chỉ thành tọa độ
  static Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      // Kiểm tra địa chỉ có hợp lệ không
      if (address.trim().isEmpty) {
        return null;
      }

      List<Location> locations = await locationFromAddress(address).timeout(
        Duration(seconds: 10), // Timeout sau 10 giây
        onTimeout: () {
          throw Exception('Timeout khi tìm kiếm địa chỉ');
        },
      );

      if (locations.isNotEmpty) {
        return locations.first;
      }
    } on PlatformException catch (e) {
      print('PlatformException in getCoordinatesFromAddress: ${e.message}');
      // Xử lý các lỗi platform cụ thể
      if (e.code == 'NOT_FOUND') {
        print('Địa chỉ không tìm thấy: $address');
      } else if (e.code == 'NETWORK_ERROR') {
        print('Lỗi mạng khi tìm kiếm địa chỉ');
      }
      return null;
    } catch (e) {
      print('Error getting coordinates from address: $e');
      return null;
    }
    return null;
  }

  // Mở Google Maps để chỉ đường
  static Future<void> openDirections({
    required double destinationLat,
    required double destinationLng,
    String? destinationName,
  }) async {
    try {
      Position? currentPosition = await getCurrentLocation();

      String url;
      if (currentPosition != null) {
        // Có vị trí hiện tại, chỉ đường từ vị trí hiện tại đến đích
        url = 'https://www.google.com/maps/dir/${currentPosition.latitude},${currentPosition.longitude}/$destinationLat,$destinationLng';

        // Thêm tên địa điểm nếu có
        if (destinationName != null && destinationName.isNotEmpty) {
          final encodedName = Uri.encodeComponent(destinationName);
          url += '?destination_place_id=$encodedName';
        }
      } else {
        // Không có vị trí hiện tại, mở Google Maps với đích đến
        url = 'https://www.google.com/maps/search/?api=1&query=$destinationLat,$destinationLng';

        if (destinationName != null && destinationName.isNotEmpty) {
          final encodedName = Uri.encodeComponent(destinationName);
          url = 'https://www.google.com/maps/search/?api=1&query=$encodedName';
        }
      }

      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Không thể mở Google Maps. Vui lòng kiểm tra kết nối internet hoặc cài đặt Google Maps.';
      }
    } catch (e) {
      throw 'Lỗi khi mở chỉ đường: $e';
    }
  }

  // Mở Google Maps với địa chỉ
  static Future<void> openDirectionsWithAddress(String address) async {
    try {
      Location? location = await getCoordinatesFromAddress(address);
      if (location != null) {
        // Đã tìm thấy tọa độ, thử mở Google Maps
        try {
          await openDirections(
            destinationLat: location.latitude,
            destinationLng: location.longitude,
            destinationName: address,
          );
        } catch (e) {
          // Nếu lỗi khi mở Google Maps với tọa độ, thử fallback
          print('Lỗi khi mở Google Maps với tọa độ: $e');
          await _openMapsFallback(address);
        }
      } else {
        // Không tìm thấy tọa độ, sử dụng fallback
        await _openMapsFallback(address);
      }
    } catch (e) {
      throw 'Lỗi khi xử lý địa chỉ: $e';
    }
  }

  // Phương thức fallback để mở Google Maps
  static Future<void> _openMapsFallback(String address) async {
    final String encodedAddress = Uri.encodeComponent(address);
    final String url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Không thể mở Google Maps. Vui lòng kiểm tra kết nối internet hoặc cài đặt Google Maps.';
    }
  }

  // Tính khoảng cách giữa hai điểm
  static double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Lấy khoảng cách từ vị trí hiện tại đến địa chỉ
  static Future<double?> getDistanceToAddress(String address) async {
    Position? currentPosition = await getCurrentLocation();
    Location? destination = await getCoordinatesFromAddress(address);

    if (currentPosition != null && destination != null) {
      return calculateDistance(
        startLat: currentPosition.latitude,
        startLng: currentPosition.longitude,
        endLat: destination.latitude,
        endLng: destination.longitude,
      );
    }
    return null;
  }
}
