import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/field.dart';
import '../services/map_service.dart';

class MapScreen extends StatefulWidget {
  final Field field;

  const MapScreen({Key? key, required this.field}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  GoogleMapController? mapController;
  LatLng? fieldLocation;
  LatLng? currentLocation;
  Set<Marker> markers = {};
  bool isLoading = true;
  String? errorMessage;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMap();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // Tạm dừng các hoạt động Maps khi app bị pause
      mapController?.dispose();
      mapController = null;
    } else if (state == AppLifecycleState.resumed && mapController == null) {
      // Khởi tạo lại Maps khi app resume
      _reinitializeMap();
    }
  }

  Future<void> _reinitializeMap() async {
    if (!_isDisposed && mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      await _initializeMap();
    }
  }

  Future<void> _initializeMap() async {
    try {
      // Lấy tọa độ của sân bóng từ địa chỉ
      Location? location = await MapService.getCoordinatesFromAddress(widget.field.address);

      if (location != null) {
        fieldLocation = LatLng(location.latitude, location.longitude);

        // Thêm marker cho sân bóng
        markers.add(
          Marker(
            markerId: MarkerId('field_${widget.field.id}'),
            position: fieldLocation!,
            infoWindow: InfoWindow(
              title: widget.field.name,
              snippet: widget.field.address,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );

        // Lấy vị trí hiện tại
        Position? position = await MapService.getCurrentLocation();
        if (position != null) {
          currentLocation = LatLng(position.latitude, position.longitude);

          // Thêm marker cho vị trí hiện tại
          markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: currentLocation!,
              infoWindow: const InfoWindow(
                title: 'Vị trí của bạn',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
          );
        }
      } else {
        errorMessage = 'Không thể tìm thấy vị trí của sân bóng';
      }
    } catch (e) {
      errorMessage = 'Lỗi khi tải bản đồ: $e';
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    if (fieldLocation != null) {
      // Di chuyển camera đến vị trí sân bóng
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: fieldLocation!,
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  Future<void> _openDirections() async {
    try {
      // Hiển thị loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Đang mở Google Maps...'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.amber,
        ),
      );

      await MapService.openDirectionsWithAddress(widget.field.address);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở chỉ đường: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: _openDirections,
          ),
        ),
      );
    }
  }

  Future<void> _showFieldOnMap() async {
    if (fieldLocation != null && mapController != null) {
      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: fieldLocation!,
            zoom: 18.0,
          ),
        ),
      );
    }
  }

  Future<void> _showCurrentLocation() async {
    if (currentLocation != null && mapController != null) {
      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation!,
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bản đồ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        backgroundColor: Colors.amberAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.directions, color: Colors.amber[900]),
            onPressed: _openDirections,
            tooltip: 'Chỉ đường',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                        ),
                        child: const Text('Quay lại'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: fieldLocation ?? const LatLng(10.762622, 106.660172), // Mặc định ở TP.HCM
                        zoom: 14.0,
                      ),
                      markers: markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      // Thêm các cấu hình để tránh crash
                      buildingsEnabled: true,
                      compassEnabled: true,
                      mapType: MapType.normal,
                      rotateGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      zoomGesturesEnabled: true,
                      // Tắt các tính năng có thể gây crash
                      trafficEnabled: false,
                      indoorViewEnabled: false,
                    ),
                    // Panel thông tin sân
                    Positioned(
                      bottom: 20,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.field.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.amber[600], size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.field.address,
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _openDirections,
                                    icon: const Icon(Icons.directions, size: 20),
                                    label: const Text('Chỉ đường'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _showFieldOnMap,
                                  icon: const Icon(Icons.my_location),
                                  tooltip: 'Hiện vị trí sân',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.amber[100],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Nút vị trí hiện tại
                    if (currentLocation != null)
                      Positioned(
                        top: 20,
                        right: 16,
                        child: FloatingActionButton(
                          mini: true,
                          onPressed: _showCurrentLocation,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.gps_fixed, color: Colors.amber[800]),
                        ),
                      ),
                  ],
                ),
    );
  }
}
