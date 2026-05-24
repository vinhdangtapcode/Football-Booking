import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math';
import '../models/field.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Field> fields = [];
  List<Field> filteredFields = [];
  List<Field> highRatedFields = [];
  List<Field> nearbyFields = [];
  bool isLoading = false;
  bool isLoadingLocation = false;
  Position? currentPosition;
  int _currentIndex = 0; //Lưu trạng thái NavBar
  String _sortType = 'none';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    fetchFields();
  }

  void fetchFields() async {
    setState(() {
      isLoading = true;
    });
    List<Field> fetchedFields = await ApiService.getPublicFields();
    setState(() {
      fields = fetchedFields;
      filteredFields = fetchedFields;
      highRatedFields = fetchedFields.where((f) => (f.rating ?? 0) >= 4).toList();
      isLoading = false;
    });
  }

  // Tính khoảng cách giữa 2 điểm (Haversine formula)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Bán kính Trái Đất tính bằng km

    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
        sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  // Yêu cầu quyền vị trí và lấy vị trí hiện tại
  Future<void> getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      // Kiểm tra quyền vị trí
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Quyền truy cập vị trí bị từ chối')),
          );
          setState(() {
            isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng cấp quyền trong cài đặt.'),
            action: SnackBarAction(
              label: 'Cài đặt',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      // Lấy vị trí hiện tại
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentPosition = position;
      });

      // Tính khoảng cách và sắp xếp sân gần nhất
      await calculateNearbyFields();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lấy vị trí hiện tại: $e')),
      );
    } finally {
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  // Chuyển đổi địa chỉ thành tọa độ và tính khoảng cách
  Future<void> calculateNearbyFields() async {
    if (currentPosition == null) return;

    List<Field> fieldsWithDistance = [];

    for (Field field in fields) {
      try {
        String? address = field.address;
        if (address != null && address.isNotEmpty) {
          // Sử dụng geocoding để chuyển địa chỉ thành tọa độ
          List<Location> locations = await locationFromAddress(address);

          if (locations.isNotEmpty) {
            Location location = locations.first;
            double distance = calculateDistance(
              currentPosition!.latitude,
              currentPosition!.longitude,
              location.latitude,
              location.longitude,
            );

            // Tạo field copy với distance và tọa độ
            Field fieldWithDistance = Field(
              id: field.id,
              name: field.name,
              address: field.address,
              type: field.type,
              facilities: field.facilities,
              pricePerHour: field.pricePerHour,
              rating: field.rating,
              openingTime: field.openingTime,
              closingTime: field.closingTime,
              grassType: field.grassType,
              length: field.length,
              width: field.width,
              available: field.available,
              outdoor: field.outdoor,
              owner: field.owner,
              imageUrl: field.imageUrl,
              latitude: location.latitude,
              longitude: location.longitude,
              distance: distance,
            );

            fieldsWithDistance.add(fieldWithDistance);
          }
        }
      } catch (e) {
        // Nếu không thể geocode, bỏ qua sân này
        print('Không thể chuyển đổi địa chỉ "${field.address}": $e');
        continue;
      }
    }

    // Sắp xếp theo khoảng cách gần nhất
    fieldsWithDistance.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));

    setState(() {
      nearbyFields = fieldsWithDistance;
    });
  }

  // Hàm bỏ dấu tiếng Việt (Map implementation)
  String removeDiacritics(String str) {
    const vietnameseMap = <String, String>{
      'á': 'a', 'à': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a', 'â': 'a', 'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a', 'ă': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'é': 'e', 'è': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e', 'ê': 'e', 'ế': 'e', 'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'í': 'i', 'ì': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ó': 'o', 'ò': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o', 'ô': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o', 'ơ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ú': 'u', 'ù': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u', 'ư': 'u', 'ứ': 'u', 'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ý': 'y', 'ỳ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'đ': 'd',
      'Á': 'A', 'À': 'A', 'Ả': 'A', 'Ã': 'A', 'Ạ': 'A', 'Â': 'A', 'Ấ': 'A', 'Ầ': 'A', 'Ẩ': 'A', 'Ẫ': 'A', 'Ậ': 'A', 'Ă': 'A', 'Ắ': 'A', 'Ằ': 'A', 'Ẳ': 'A', 'Ẵ': 'A', 'Ặ': 'A',
      'É': 'E', 'È': 'E', 'Ẻ': 'E', 'Ẽ': 'E', 'Ẹ': 'E', 'Ê': 'E', 'Ế': 'E', 'Ề': 'E', 'Ể': 'E', 'Ễ': 'E', 'Ệ': 'E',
      'Í': 'I', 'Ì': 'I', 'Ỉ': 'I', 'Ĩ': 'I', 'Ị': 'I',
      'Ó': 'O', 'Ò': 'O', 'Ỏ': 'O', 'Õ': 'O', 'Ọ': 'O', 'Ô': 'O', 'Ố': 'O', 'Ồ': 'O', 'Ổ': 'O', 'Ỗ': 'O', 'Ộ': 'O', 'Ơ': 'O', 'Ớ': 'O', 'Ờ': 'O', 'Ở': 'O', 'Ỡ': 'O', 'Ợ': 'O',
      'Ú': 'U', 'Ù': 'U', 'Ủ': 'U', 'Ũ': 'U', 'Ụ': 'U', 'Ư': 'U', 'Ứ': 'U', 'Ừ': 'U', 'Ử': 'U', 'Ữ': 'U', 'Ự': 'U',
      'Ý': 'Y', 'Ỳ': 'Y', 'Ỷ': 'Y', 'Ỹ': 'Y', 'Ỵ': 'Y',
      'Đ': 'D'
    };
    
    for (var key in vietnameseMap.keys) {
      str = str.replaceAll(key, vietnameseMap[key]!);
    }
    return str;
  }

  void _filterFields(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredFields = fields;
      } else {
        final q = query.trim().toLowerCase();
        final normalizedQuery = removeDiacritics(query).trim().toLowerCase();
        
        filteredFields = fields.where((field) {
          final name = field.name.toLowerCase();
          // 1. Tìm chính xác (có dấu)
          if (name.contains(q)) return true;
          
          // 2. Tìm tương đối (không dấu)
          final normalizedName = removeDiacritics(field.name).toLowerCase();
          return normalizedName.contains(normalizedQuery);
        }).toList();
      }
    });
  }

  void _sortFields() {
    List<Field> list = [...filteredFields];
    if (_sortType == 'price') {
      list.sort((a, b) => _sortOrder == 'asc'
          ? a.pricePerHour.compareTo(b.pricePerHour)
          : b.pricePerHour.compareTo(a.pricePerHour));
    } else if (_sortType == 'rating') {
      list.sort((a, b) => _sortOrder == 'asc'
          ? (a.rating ?? 0).compareTo(b.rating ?? 0)
          : (b.rating ?? 0).compareTo(a.rating ?? 0));
    } else {
      // Mặc định: sắp xếp theo tên sân (tăng dần, không phân biệt hoa thường)
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    setState(() {
      filteredFields = list;
    });
  }

  void navigateToFieldDetails(Field field) {
    Navigator.pushNamed(context, '/fieldDetail', arguments: field);
  }

  @override
  Widget build(BuildContext context) {
    // Nếu đang được nhúng trong MainTabScaffold thì không cần BottomNavigationBar nữa
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.amberAccent,
          elevation: 0,
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _filterFields,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sân',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(Icons.sort, color: Colors.amber[800]),
                  tooltip: 'Sắp xếp',
                  onSelected: (value) {
                    if (value == 'price_asc') {
                      _sortType = 'price'; _sortOrder = 'asc';
                    } else if (value == 'price_desc') {
                      _sortType = 'price'; _sortOrder = 'desc';
                    } else if (value == 'rating_asc') {
                      _sortType = 'rating'; _sortOrder = 'asc';
                    } else if (value == 'rating_desc') {
                      _sortType = 'rating'; _sortOrder = 'desc';
                    } else {
                      _sortType = 'none';
                    }
                    _sortFields();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'price_asc', child: Text('Giá tăng dần')),
                    PopupMenuItem(value: 'price_desc', child: Text('Giá giảm dần')),
                    PopupMenuItem(value: 'rating_asc', child: Text('Đánh giá tăng dần')),
                    PopupMenuItem(value: 'rating_desc', child: Text('Đánh giá giảm dần')),
                    PopupMenuItem(value: 'none', child: Text('Mặc định')),
                  ],
                ),
              ],
            ),
          ),
          actions: [

            IconButton(
              icon: Icon(Icons.favorite),
              onPressed: () {
                Navigator.pushNamed(context, '/favorites');
              },
            ),
            IconButton(
              icon: Icon(Icons.history),
              onPressed: () {
                Navigator.pushNamed(context, '/bookingHistory');
              },
            ),
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
          // Thêm TabBar vào AppBar bằng thuộc tính "bottom"
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50), // điều chỉnh chiều cao của TabBar tùy ý
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Padding 2 lề & padding dọc
              child: Container(
                height:40,
                decoration: BoxDecoration(
                  color: Colors.white, // Màu nền cho toàn bộ thanh TabBar
                  borderRadius: BorderRadius.circular(20), // Bo góc cho Container chứa TabBar
                  border: Border.all(
                    color: Colors.amber, // Border màu amber
                    width: 1.5,           // Độ dày của border
                  ),
                ),
                child: TabBar(
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent, //loại bỏ đường màu đen
                  indicator: BoxDecoration(
                    color: Colors.amber, // Nền vàng cho tab được chọn
                    borderRadius: BorderRadius.circular(20), // Bo góc cho indicator
                  ),
                  indicatorSize: TabBarIndicatorSize.tab, // Indicator bao phủ toàn bộ tab
                  labelColor: Colors.white,        // Chữ trắng cho tab được chọn
                  unselectedLabelColor: Colors.amber, // Chữ đen cho các tab không chọn
                  tabs: [
                    Tab(text: 'Tất cả sân'),
                    Tab(text: 'Sân gần bạn'),
                  ],
                ),
              ),
            ),
          ),

        ),
        // Hiển thị nội dung tùy thuộc vào tab đang chọn
        body: TabBarView(
          children: [
            // Tab "Tất cả sân": danh sách sân công cộng
            isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                  itemCount: filteredFields.length,
                  itemBuilder: (context, index) {
                    Field field = filteredFields[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      child: InkWell(
                        onTap: () => navigateToFieldDetails(field),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Tính toán chiều rộng cho hình ảnh (1/5 tổng chiều rộng của Card)
                            double imageWidth = constraints.maxWidth / 5;
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Phần hiển thị hình ảnh ở bên trái
                                  Container(
                                    width: imageWidth,
                                    height: imageWidth * 0.75,
                                    // Điều chỉnh tỉ lệ aspect theo mong muốn
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child:
                                          (field.imageUrl?.isEmpty ?? true)
                                              ? Image.asset(
                                                'lib/assets/images/san_bong.png',
                                                fit: BoxFit.cover,
                                              )
                                              : Image.network(
                                                field.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Image.asset(
                                                    'lib/assets/images/san_bong.png',
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                              ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Phần nội dung hiển thị thông tin chi tiết của field
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          field.name,
                                          style: const TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          field.address ?? '',
                                          style: TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 16,
                                              color: Colors.yellow,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              field.rating != null
                                                  ? (field.rating % 1 == 0
                                                      ? field.rating.toInt().toString()
                                                      : field.rating.toStringAsFixed(1))
                                                  : '0',
                                              style: const TextStyle(
                                                fontFamily: 'Roboto',
                                              ),
                                            ),
                                            const Spacer(),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.monetization_on, color: Colors.green[600], size: 16),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${field.pricePerHour.toInt()} VNĐ/giờ',
                                                  style: const TextStyle(
                                                    fontFamily: 'Roboto',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Icon trailing (nếu muốn hiển thị)
                                  Icon(
                                    field.available == true ? Icons.check_circle : Icons.cancel,
                                    color: field.available == true ? Colors.green : Colors.red,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

            // Tab "Sân gần bạn": hiển thị sân theo khoảng cách gần nhất
            isLoading
                ? Center(child: CircularProgressIndicator())
                : currentPosition == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Bật vị trí để xem sân gần bạn',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Chúng tôi cần quyền truy cập vị trí để\nhiển thị các sân gần nhất với bạn',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: isLoadingLocation ? null : getCurrentLocation,
                            icon: isLoadingLocation
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(Icons.my_location),
                            label: Text(
                              isLoadingLocation ? 'Đang lấy vị trí...' : 'Bật vị trí',
                              style: TextStyle(fontFamily: 'Roboto'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : isLoadingLocation
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.amber,
                              strokeWidth: 3,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Đang tìm kiếm sân gần bạn...',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Vui lòng đợi trong giây lát',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : nearbyFields.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_searching,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Không tìm thấy sân gần bạn',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Các sân chưa có thông tin vị trí\nhoặc không có sân nào trong khu vực',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await getCurrentLocation();
                        },
                        child: ListView.builder(
                          itemCount: nearbyFields.length,
                          itemBuilder: (context, index) {
                            Field field = nearbyFields[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              child: InkWell(
                                onTap: () => navigateToFieldDetails(field),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    double imageWidth = constraints.maxWidth / 5;
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: imageWidth,
                                            height: imageWidth * 0.75,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8.0),
                                              child: (field.imageUrl?.isEmpty ?? true)
                                                  ? Image.asset(
                                                    'lib/assets/images/san_bong.png',
                                                    fit: BoxFit.cover,
                                                  )
                                                  : Image.network(
                                                    field.imageUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        'lib/assets/images/san_bong.png',
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  field.name,
                                                  style: const TextStyle(
                                                    fontFamily: 'Roboto',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  field.address ?? '',
                                                  style: TextStyle(
                                                    fontFamily: 'Roboto',
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                // Hiển thị đánh giá, khoảng cách và giá tiền trên cùng 1 dòng
                                                Row(
                                                  children: [
                                                    // Đánh giá
                                                    const Icon(
                                                      Icons.star,
                                                      size: 16,
                                                      color: Colors.yellow,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      field.rating != null
                                                          ? (field.rating % 1 == 0
                                                              ? field.rating.toInt().toString()
                                                              : field.rating.toStringAsFixed(1))
                                                          : '0',
                                                      style: const TextStyle(
                                                        fontFamily: 'Roboto',
                                                        fontSize: 12,
                                                      ),
                                                    ),

                                                    // Spacer
                                                    const SizedBox(width: 12),

                                                    // Khoảng cách
                                                    Icon(
                                                      Icons.location_on,
                                                      size: 16,
                                                      color: Colors.blue[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      field.distance != null
                                                          ? '${field.distance!.toStringAsFixed(1)} km'
                                                          : 'N/A',
                                                      style: TextStyle(
                                                        fontFamily: 'Roboto',
                                                        fontSize: 12,
                                                        color: Colors.blue[600],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),

                                                    const Spacer(),

                                                    // Giá tiền
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.monetization_on, color: Colors.green[600], size: 16),
                                                        const SizedBox(width: 2),
                                                        Text(
                                                          '${field.pricePerHour.toInt()} VNĐ/giờ',
                                                          style: const TextStyle(
                                                            fontFamily: 'Roboto',
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Icon hiển thị trạng thái sân
                                          Icon(
                                            field.available == true ? Icons.check_circle : Icons.cancel,
                                            color: field.available == true ? Colors.green : Colors.red,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
        bottomNavigationBar: null,
      ),
    );
  }
}
