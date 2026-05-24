import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/map_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final String? initialAddress;
  final LatLng? initialLocation;

  const LocationPickerScreen({
    Key? key,
    this.initialAddress,
    this.initialLocation,
  }) : super(key: key);

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? mapController;
  LatLng? selectedLocation;
  String selectedAddress = '';
  bool isLoading = true;
  bool isGettingAddress = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    mapController?.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      LatLng initialPos;

      if (widget.initialLocation != null) {
        initialPos = widget.initialLocation!;
        selectedLocation = initialPos;
        if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
          selectedAddress = widget.initialAddress!;
          searchController.text = selectedAddress;
        } else {
          // Nếu có tọa độ nhưng không có địa chỉ, lấy địa chỉ từ tọa độ
          await _getAddressFromLocation(initialPos);
        }
      } else if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
        // Chuyển đổi địa chỉ thành tọa độ với error handling tốt hơn
        try {
          Location? location = await MapService.getCoordinatesFromAddress(widget.initialAddress!);
          if (location != null) {
            initialPos = LatLng(location.latitude, location.longitude);
            selectedLocation = initialPos;
            selectedAddress = widget.initialAddress!;
            searchController.text = selectedAddress;
          } else {
            // Fallback về vị trí hiện tại nếu không tìm được địa chỉ
            initialPos = await _getCurrentLocationOrDefault();
            searchController.text = ''; // Xóa text để hiển thị placeholder
          }
        } catch (e) {
          print('Error converting initial address to coordinates: $e');
          initialPos = await _getCurrentLocationOrDefault();
          searchController.text = ''; // Xóa text để hiển thị placeholder
        }
      } else {
        // Lấy vị trí hiện tại
        initialPos = await _getCurrentLocationOrDefault();
        searchController.text = ''; // Đảm bảo placeholder hiển thị
      }

      selectedLocation ??= initialPos;

      // Chỉ lấy địa chỉ nếu chưa có
      if (selectedAddress.isEmpty && selectedLocation != null) {
        await _getAddressFromLocation(selectedLocation!);
      }

    } catch (e) {
      print('Error initializing location: $e');
      selectedLocation = const LatLng(10.762622, 106.660172); // Default TP.HCM
      selectedAddress = '';
      searchController.text = '';
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<LatLng> _getCurrentLocationOrDefault() async {
    try {
      Position? position = await MapService.getCurrentLocation();
      if (position != null) {
        return LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
    return const LatLng(10.762622, 106.660172); // Default TP.HCM
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    setState(() {
      isGettingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = '';

        // Xây dựng địa chỉ một cách an toàn
        List<String> addressParts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        address = addressParts.join(', ');

        setState(() {
          selectedAddress = address.isNotEmpty ? address : 'Địa chỉ không xác định';
          // Xóa nội dung ô tìm kiếm để hiển thị placeholder
          searchController.clear();
        });
      } else {
        setState(() {
          selectedAddress = 'Không thể xác định địa chỉ';
          // Xóa nội dung ô tìm kiếm
          searchController.clear();
        });
      }
    } catch (e) {
      print('Error getting address from coordinates: $e');
      // Fallback: tạo địa chỉ từ tọa độ
      String fallbackAddress = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      setState(() {
        selectedAddress = fallbackAddress;
        // Xóa nội dung ô tìm kiếm
        searchController.clear();
      });
    } finally {
      setState(() {
        isGettingAddress = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onMapTap(LatLng location) {
    setState(() {
      selectedLocation = location;
    });
    _getAddressFromLocation(location);
  }

  Future<void> _searchAddress() async {
    String query = searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Sử dụng MapService để tìm kiếm địa chỉ
      Location? location = await MapService.getCoordinatesFromAddress(query);
      if (location != null) {
        LatLng newLocation = LatLng(location.latitude, location.longitude);
        setState(() {
          selectedLocation = newLocation;
          selectedAddress = query;
        });

        // Di chuyển camera đến vị trí mới
        try {
          if (mapController != null) {
            await mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: newLocation,
                  zoom: 16.0,
                ),
              ),
            );
          }
        } catch (cameraError) {
          // Lỗi camera không ảnh hưởng đến việc tìm kiếm thành công
          print('Camera animation error: $cameraError');
        }

        // Hiển thị thông báo thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('Đã tìm thấy địa chỉ thành công!')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _showError('Không tìm thấy địa chỉ. Vui lòng thử lại với địa chỉ khác.');
      }
    } catch (e) {
      print('Search address error: $e');
      _showError('Lỗi tìm kiếm địa chỉ. Vui lòng kiểm tra kết nối mạng và thử lại.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _confirmLocation() {
    if (selectedLocation != null) {
      // Đảm bảo có địa chỉ để trả về
      String finalAddress = selectedAddress;

      // Nếu không có địa chỉ hoặc địa chỉ không hợp lệ, tạo từ tọa độ
      if (selectedAddress.isEmpty || selectedAddress == 'Địa chỉ không xác định' || selectedAddress == 'Không thể xác định địa chỉ') {
        finalAddress = '${selectedLocation!.latitude.toStringAsFixed(6)}, ${selectedLocation!.longitude.toStringAsFixed(6)}';
      }

      // Debug logging
      print('Location Picker - Confirming location:');
      print('selectedLocation: $selectedLocation');
      print('selectedAddress: "$selectedAddress"');
      print('finalAddress: "$finalAddress"');

      // Trả về kết quả với đầy đủ thông tin
      Map<String, dynamic> result = {
        'location': selectedLocation,
        'address': finalAddress,
        'coordinates': '${selectedLocation!.latitude},${selectedLocation!.longitude}',
      };

      print('Returning result: $result');
      Navigator.pop(context, result);
    } else {
      _showError('Vui lòng chọn một vị trí trước khi xác nhận.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chọn vị trí sân',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amberAccent,
        elevation: 0,
        actions: [
          if (selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: _confirmLocation,
              tooltip: 'Xác nhận vị trí',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Column(
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.amber[50],
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm địa chỉ...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        searchController.clear();
                                      });
                                    },
                                    tooltip: 'Xóa nội dung',
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (value) {
                            setState(() {}); // Cập nhật để hiển thị/ẩn nút X
                          },
                          onSubmitted: (_) => _searchAddress(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _searchAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Tìm'),
                      ),
                    ],
                  ),
                ),

                // Map
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: selectedLocation ?? const LatLng(10.762622, 106.660172),
                          zoom: 15.0,
                        ),
                        onTap: _onMapTap,
                        markers: selectedLocation != null
                            ? {
                                Marker(
                                  markerId: const MarkerId('selected'),
                                  position: selectedLocation!,
                                  infoWindow: InfoWindow(
                                    title: 'Vị trí đã chọn',
                                    snippet: selectedAddress,
                                  ),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueGreen,
                                  ),
                                ),
                              }
                            : {},
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        mapType: MapType.normal,
                        zoomControlsEnabled: false,
                        compassEnabled: true,
                      ),

                      // Crosshair in center
                      const Center(
                        child: Icon(
                          Icons.add,
                          size: 30,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

                // Selected address info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text(
                            'Địa chỉ đã chọn:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (isGettingAddress)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedAddress.isNotEmpty
                            ? selectedAddress
                            : 'Chạm vào bản đồ để chọn vị trí',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: selectedLocation != null ? _confirmLocation : null,
                          icon: const Icon(Icons.check),
                          label: const Text('Xác nhận vị trí này'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
