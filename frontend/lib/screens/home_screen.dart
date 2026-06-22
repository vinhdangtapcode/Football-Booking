import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../models/field.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Field> fields = [];
  List<Field> filteredFields = [];
  List<Field> highRatedFields = [];
  List<Field> nearbyFields = [];
  List<Field> filteredNearbyFields = [];
  bool isLoading = false;
  bool isLoadingLocation = false;
  Position? currentPosition;
  int _currentIndex = 0; //Lưu trạng thái NavBar
  
  // Trạng thái bộ lọc & sắp xếp nâng cao
  String _searchQuery = '';
  String _selectedQuickFilter = 'all';
  String _sortType = 'none';
  String _sortOrder = 'desc';
  List<String> _selectedTypes = [];
  List<String> _selectedGrassTypes = [];
  RangeValues _priceRange = const RangeValues(0, 2000000);
  double _minRating = 0;

  bool get _isFilterActive {
    return _selectedTypes.isNotEmpty ||
        _selectedGrassTypes.isNotEmpty ||
        _priceRange.start > 0 ||
        _priceRange.end < 2000000 ||
        _minRating > 0 ||
        _sortType != 'none';
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedTypes.isNotEmpty) count += 1;
    if (_selectedGrassTypes.isNotEmpty) count += 1;
    if (_priceRange.start > 0 || _priceRange.end < 2000000) count += 1;
    if (_minRating > 0) count += 1;
    if (_sortType != 'none') count += 1;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    fetchFields();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void fetchFields() async {
    setState(() {
      isLoading = true;
    });
    List<Field> fetchedFields = await ApiService.getPublicFields();
    fields = fetchedFields;
    highRatedFields = fetchedFields.where((f) => (f.rating ?? 0) >= 4).toList();
    _applyFiltersAndSort();
    setState(() {
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

    nearbyFields = fieldsWithDistance;
    _applyFiltersAndSort();
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

  void _applyFiltersAndSort() {
    filteredFields = _filterAndSortList(fields);
    filteredNearbyFields = _filterAndSortList(nearbyFields, keepDistanceSort: _sortType == 'none');
    setState(() {});
  }

  List<Field> _filterAndSortList(List<Field> source, {bool keepDistanceSort = false}) {
    List<Field> result = [...source];

    // 1. Lọc theo tìm kiếm
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      final normalizedQuery = removeDiacritics(_searchQuery).trim().toLowerCase();
      result = result.where((field) {
        final name = field.name.toLowerCase();
        if (name.contains(q)) return true;
        final normalizedName = removeDiacritics(field.name).toLowerCase();
        return normalizedName.contains(normalizedQuery);
      }).toList();
    }

    // 2. Lọc theo phím lọc nhanh
    if (_selectedQuickFilter == 'sân 5') {
      result = result.where((f) => f.type == '5').toList();
    } else if (_selectedQuickFilter == 'sân 7') {
      result = result.where((f) => f.type == '7').toList();
    } else if (_selectedQuickFilter == 'sân 11') {
      result = result.where((f) => f.type == '11').toList();
    } else if (_selectedQuickFilter == 'natural_grass') {
      result = result.where((f) => f.grassType == 'natural').toList();
    } else if (_selectedQuickFilter == 'good_price') {
      result = result.where((f) => f.pricePerHour <= 200000).toList();
    } else if (_selectedQuickFilter == 'high_rating') {
      result = result.where((f) => (f.rating ?? 0) >= 4.5).toList();
    }

    // 3. Lọc nâng cao từ Bottom Sheet
    if (_selectedTypes.isNotEmpty) {
      final mappedTypes = _selectedTypes.map((t) {
        if (t == 'Sân 5') return '5';
        if (t == 'Sân 7') return '7';
        if (t == 'Sân 11') return '11';
        return t;
      }).toList();
      result = result.where((f) => mappedTypes.contains(f.type)).toList();
    }
    if (_selectedGrassTypes.isNotEmpty) {
      final mappedGrass = _selectedGrassTypes.map((g) {
        if (g == 'Cỏ nhân tạo') return 'artificial';
        if (g == 'Cỏ tự nhiên') return 'natural';
        return g;
      }).toList();
      result = result.where((f) => mappedGrass.contains(f.grassType)).toList();
    }
    result = result.where((f) => f.pricePerHour >= _priceRange.start && f.pricePerHour <= _priceRange.end).toList();
    if (_minRating > 0) {
      result = result.where((f) => (f.rating ?? 0) >= _minRating).toList();
    }

    // 4. Sắp xếp
    if (!keepDistanceSort) {
      if (_sortType == 'price') {
        result.sort((a, b) => _sortOrder == 'asc'
            ? a.pricePerHour.compareTo(b.pricePerHour)
            : b.pricePerHour.compareTo(a.pricePerHour));
      } else if (_sortType == 'rating') {
        result.sort((a, b) => _sortOrder == 'asc'
            ? (a.rating ?? 0).compareTo(b.rating ?? 0)
            : (b.rating ?? 0).compareTo(a.rating ?? 0));
      } else {
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }
    }

    return result;
  }

  Widget _buildQuickFilterChip(String key, String label) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isModern = themeProvider.isModernMode;
    final isSelected = _selectedQuickFilter == key;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: isSelected
                ? (isModern ? Colors.black : Colors.white)
                : (isModern ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedQuickFilter = key;
          });
          _applyFiltersAndSort();
        },
        selectedColor: isModern ? Colors.white : Colors.amber,
        backgroundColor: isModern ? const Color(0xFF16181D) : Colors.grey[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? (isModern ? Colors.white : Colors.amber)
                : (isModern ? Colors.white10 : Colors.transparent),
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildFilterChoiceChip(
    StateSetter setSheetState,
    String key,
    String label,
    bool isSelected,
    Function(bool) onSelected,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isModern = themeProvider.isModernMode;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: isSelected
              ? (isModern ? Colors.black : Colors.white)
              : (isModern ? Colors.white70 : Colors.black87),
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: isModern ? Colors.white : Colors.amber,
      backgroundColor: isModern ? const Color(0xFF16181D) : Colors.grey[100],
      showCheckmark: false,
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isModern = themeProvider.isModernMode;

    String tempSortType = _sortType;
    String tempSortOrder = _sortOrder;
    List<String> tempSelectedTypes = List.from(_selectedTypes);
    List<String> tempSelectedGrassTypes = List.from(_selectedGrassTypes);
    RangeValues tempPriceRange = _priceRange;
    double tempMinRating = _minRating;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: isModern ? const Color(0xE60A0B0E) : Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(
                      color: isModern ? Colors.white12 : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  padding: EdgeInsets.only(
                    top: 16,
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isModern ? Colors.white30 : Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bộ lọc nâng cao',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isModern ? Colors.white : Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  tempSortType = 'none';
                                  tempSortOrder = 'desc';
                                  tempSelectedTypes.clear();
                                  tempSelectedGrassTypes.clear();
                                  tempPriceRange = const RangeValues(0, 2000000);
                                  tempMinRating = 0;
                                });
                              },
                              child: Text(
                                'Đặt lại',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: isModern ? themeProvider.accentColor : Colors.amber[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          'Sắp xếp theo',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isModern ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildFilterChoiceChip(
                              setSheetState,
                              'none',
                              'Mặc định',
                              tempSortType == 'none',
                              (selected) {
                                setSheetState(() {
                                  tempSortType = 'none';
                                });
                              },
                            ),
                            _buildFilterChoiceChip(
                              setSheetState,
                              'price_asc',
                              'Giá tăng dần',
                              tempSortType == 'price' && tempSortOrder == 'asc',
                              (selected) {
                                setSheetState(() {
                                  tempSortType = 'price';
                                  tempSortOrder = 'asc';
                                });
                              },
                            ),
                            _buildFilterChoiceChip(
                              setSheetState,
                              'price_desc',
                              'Giá giảm dần',
                              tempSortType == 'price' && tempSortOrder == 'desc',
                              (selected) {
                                setSheetState(() {
                                  tempSortType = 'price';
                                  tempSortOrder = 'desc';
                                });
                              },
                            ),
                            _buildFilterChoiceChip(
                              setSheetState,
                              'rating_desc',
                              'Đánh giá cao',
                              tempSortType == 'rating',
                              (selected) {
                                setSheetState(() {
                                  tempSortType = 'rating';
                                  tempSortOrder = 'desc';
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Loại sân',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isModern ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['Sân 5', 'Sân 7', 'Sân 11'].map((type) {
                            final isSelected = tempSelectedTypes.contains(type);
                            return FilterChip(
                              label: Text(
                                type,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: isSelected
                                      ? (isModern ? Colors.black : Colors.white)
                                      : (isModern ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setSheetState(() {
                                  if (selected) {
                                    tempSelectedTypes.add(type);
                                  } else {
                                    tempSelectedTypes.remove(type);
                                  }
                                });
                              },
                              selectedColor: isModern ? Colors.white : Colors.amber,
                              backgroundColor: isModern ? const Color(0xFF16181D) : Colors.grey[100],
                              checkmarkColor: isModern ? Colors.black : Colors.white,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Mặt cỏ',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isModern ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['Cỏ nhân tạo', 'Cỏ tự nhiên'].map((grass) {
                            final isSelected = tempSelectedGrassTypes.contains(grass);
                            return FilterChip(
                              label: Text(
                                grass,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: isSelected
                                      ? (isModern ? Colors.black : Colors.white)
                                      : (isModern ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setSheetState(() {
                                  if (selected) {
                                    tempSelectedGrassTypes.add(grass);
                                  } else {
                                    tempSelectedGrassTypes.remove(grass);
                                  }
                                });
                              },
                              selectedColor: isModern ? Colors.white : Colors.amber,
                              backgroundColor: isModern ? const Color(0xFF16181D) : Colors.grey[100],
                              checkmarkColor: isModern ? Colors.black : Colors.white,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Khoảng giá (VNĐ/giờ)',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isModern ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            Text(
                              '${tempPriceRange.start.toInt() ~/ 1000}k - ${tempPriceRange.end.toInt() ~/ 1000}k${tempPriceRange.end.toInt() == 2000000 ? '+' : ''}',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.bold,
                                color: isModern ? themeProvider.accentColor : Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: tempPriceRange,
                          min: 0,
                          max: 2000000,
                          divisions: 40,
                          activeColor: isModern ? Colors.white : Colors.amber,
                          inactiveColor: isModern ? Colors.white24 : Colors.grey[300],
                          labels: RangeLabels(
                            '${tempPriceRange.start.toInt()}đ',
                            '${tempPriceRange.end.toInt()}đ',
                          ),
                          onChanged: (values) {
                            setSheetState(() {
                              tempPriceRange = values;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đánh giá tối thiểu',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isModern ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            Text(
                              tempMinRating == 0 ? 'Tất cả' : '${tempMinRating.toStringAsFixed(1)} ⭐ trở lên',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.bold,
                                color: isModern ? themeProvider.accentColor : Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [0.0, 3.0, 4.0, 4.5].map((rating) {
                            final isSelected = tempMinRating == rating;
                            return ChoiceChip(
                              label: Text(
                                rating == 0 ? 'Tất cả' : '$rating ⭐',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: isSelected
                                      ? (isModern ? Colors.black : Colors.white)
                                      : (isModern ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setSheetState(() {
                                  tempMinRating = rating.toDouble();
                                });
                              },
                              selectedColor: isModern ? Colors.white : Colors.amber,
                              backgroundColor: isModern ? const Color(0xFF16181D) : Colors.grey[100],
                              showCheckmark: false,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _sortType = tempSortType;
                                _sortOrder = tempSortOrder;
                                _selectedTypes = tempSelectedTypes;
                                _selectedGrassTypes = tempSelectedGrassTypes;
                                _priceRange = tempPriceRange;
                                _minRating = tempMinRating;
                              });
                              _applyFiltersAndSort();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isModern ? Colors.white : Colors.amber,
                              foregroundColor: isModern ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Áp dụng bộ lọc',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void navigateToFieldDetails(Field field) {
    Navigator.pushNamed(context, '/fieldDetail', arguments: field);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = themeProvider.isModernMode;

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: isModern ? const Color(0xFF0A0B0E) : Colors.amberAccent,
          elevation: 0,
          title: Row(
            children: [
              Image.asset(
                'lib/assets/images/logo.png',
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.sports_soccer,
                    color: isModern ? Colors.white : Colors.black87,
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Đặt sân nhanh',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isModern ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.favorite,
                color: isModern ? Colors.white70 : Colors.black87,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/favorites');
              },
            ),
            IconButton(
              icon: Icon(
                Icons.history,
                color: isModern ? Colors.white70 : Colors.black87,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/bookingHistory');
              },
            ),
            IconButton(
              icon: Icon(
                Icons.person,
                color: isModern ? Colors.white70 : Colors.black87,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isModern ? const Color(0xFF16181D) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isModern ? Colors.white24 : Colors.amber,
                    width: 1.5,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: isModern ? const Color(0x26FFFFFF) : Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: isModern ? Colors.white54 : Colors.amber,
                  tabs: const [
                    Tab(text: 'Tất cả sân'),
                    Tab(text: 'Sân gần bạn'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isModern ? const Color(0xFF16181D) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isModern ? Colors.white10 : Colors.grey[300]!,
                        ),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          _searchQuery = val;
                          _applyFiltersAndSort();
                        },
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: isModern ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm sân bóng...',
                          hintStyle: TextStyle(
                            color: isModern ? Colors.white30 : Colors.black45,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: isModern ? Colors.white54 : Colors.black54,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  if (_selectedQuickFilter == 'all') ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _showFilterBottomSheet(context),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: _isFilterActive
                                  ? (isModern ? themeProvider.accentColor : Colors.amber)
                                  : (isModern ? const Color(0xFF16181D) : Colors.amber[50]),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isFilterActive
                                    ? (isModern ? themeProvider.accentColor : Colors.amber[700]!)
                                    : (isModern ? Colors.white10 : Colors.amber[200]!),
                                width: 1.5,
                              ),
                              boxShadow: _isFilterActive
                                  ? [
                                      BoxShadow(
                                        color: (isModern ? themeProvider.accentColor : Colors.amber).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              Icons.tune,
                              color: _isFilterActive
                                  ? (isModern ? Colors.black : Colors.white)
                                  : (isModern ? themeProvider.accentColor : Colors.amber[800]),
                            ),
                          ),
                          if (_isFilterActive)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isModern ? Colors.redAccent : Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isModern ? const Color(0xFF0A0B0E) : Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    '$_activeFilterCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildQuickFilterChip('all', 'Tất cả'),
                  _buildQuickFilterChip('sân 7', 'Sân 7'),
                  _buildQuickFilterChip('sân 11', 'Sân 11'),
                  _buildQuickFilterChip('good_price', 'Giá tốt 💵'),
                  _buildQuickFilterChip('high_rating', 'Đánh giá cao ⭐'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () async {
                            fetchFields();
                          },
                          child: filteredFields.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.6,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              fields.isEmpty ? Icons.sports_soccer : Icons.filter_list_off,
                                              size: 80,
                                              color: isModern ? Colors.white30 : Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              fields.isEmpty ? 'Không có sân bóng nào' : 'Không có sân phù hợp bộ lọc',
                                              style: TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isModern ? Colors.white70 : Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              fields.isEmpty
                                                  ? 'Vui lòng quay lại sau'
                                                  : 'Thử điều chỉnh hoặc xóa bớt tiêu chí lọc',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 14,
                                                color: isModern ? Colors.white54 : Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: filteredFields.length,
                                  itemBuilder: (context, index) {
                                    Field field = filteredFields[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
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
                                                          : CachedNetworkImage(
                                                              imageUrl: field.imageUrl!,
                                                              fit: BoxFit.cover,
                                                              placeholder: (_, __) => Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                              errorWidget: (_, __, ___) => Image.asset(
                                                                'lib/assets/images/san_bong.png',
                                                                fit: BoxFit.cover,
                                                              ),
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
                                                          style: TextStyle(
                                                            fontFamily: 'Roboto',
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: isModern ? Colors.white : Colors.black87,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          field.address ?? '',
                                                          style: TextStyle(
                                                            fontFamily: 'Roboto',
                                                            fontSize: 14,
                                                            color: isModern ? Colors.white54 : Colors.grey[600],
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
                                                              style: TextStyle(
                                                                fontFamily: 'Roboto',
                                                                color: isModern ? Colors.white70 : Colors.black87,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            const Spacer(),
                                                            Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Icon(
                                                                  Icons.monetization_on,
                                                                  color: isModern ? themeProvider.accentColor : Colors.green[600],
                                                                  size: 16,
                                                                ),
                                                                const SizedBox(width: 2),
                                                                Text(
                                                                  '${field.pricePerHour.toInt()} VNĐ/giờ',
                                                                  style: TextStyle(
                                                                    fontFamily: 'Roboto',
                                                                    fontWeight: FontWeight.bold,
                                                                    color: isModern ? themeProvider.accentColor : Colors.green[700],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
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
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : currentPosition == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_off,
                                    size: 80,
                                    color: isModern ? Colors.white30 : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Bật vị trí để xem sân gần bạn',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isModern ? Colors.white70 : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Chúng tôi cần quyền truy cập vị trí để\nhiển thị các sân gần nhất với bạn',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 14,
                                      color: isModern ? Colors.white54 : Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: isLoadingLocation ? null : getCurrentLocation,
                                    icon: isLoadingLocation
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: isModern ? Colors.black : Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.my_location),
                                    label: Text(
                                      isLoadingLocation ? 'Đang lấy vị trí...' : 'Bật vị trí',
                                      style: const TextStyle(fontFamily: 'Roboto'),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isModern ? Colors.white : Colors.amber,
                                      foregroundColor: isModern ? Colors.black : Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                                        color: isModern ? Colors.white : Colors.amber,
                                        strokeWidth: 3,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'Đang tìm kiếm sân gần bạn...',
                                        style: TextStyle(
                                          fontFamily: 'Roboto',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isModern ? Colors.white70 : Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Vui lòng đợi trong giây lát',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Roboto',
                                          fontSize: 14,
                                          color: isModern ? Colors.white54 : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : filteredNearbyFields.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            nearbyFields.isEmpty ? Icons.location_searching : Icons.filter_list_off,
                                            size: 80,
                                            color: isModern ? Colors.white30 : Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            nearbyFields.isEmpty ? 'Không tìm thấy sân gần bạn' : 'Không có sân phù hợp bộ lọc',
                                            style: TextStyle(
                                              fontFamily: 'Roboto',
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isModern ? Colors.white70 : Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            nearbyFields.isEmpty
                                                ? 'Các sân chưa có thông tin vị trí\nhoặc không có sân nào trong khu vực'
                                                : 'Thử điều chỉnh hoặc xóa bớt tiêu chí lọc',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Roboto',
                                              fontSize: 14,
                                              color: isModern ? Colors.white54 : Colors.grey[500],
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
                                        itemCount: filteredNearbyFields.length,
                                        itemBuilder: (context, index) {
                                          Field field = filteredNearbyFields[index];
                                          return Card(
                                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
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
                                                                style: TextStyle(
                                                                  fontFamily: 'Roboto',
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: isModern ? Colors.white : Colors.black87,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 4),
                                                              Text(
                                                                field.address ?? '',
                                                                style: TextStyle(
                                                                  fontFamily: 'Roboto',
                                                                  fontSize: 14,
                                                                  color: isModern ? Colors.white54 : Colors.grey[600],
                                                                ),
                                                              ),
                                                              const SizedBox(height: 4),
                                                              Wrap(
                                                                spacing: 8,
                                                                runSpacing: 4,
                                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                                children: [
                                                                  Row(
                                                                    mainAxisSize: MainAxisSize.min,
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
                                                                        style: TextStyle(
                                                                          fontFamily: 'Roboto',
                                                                          fontSize: 12,
                                                                          fontWeight: FontWeight.bold,
                                                                          color: isModern ? Colors.white70 : Colors.black87,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(
                                                                        Icons.location_on,
                                                                        size: 16,
                                                                        color: isModern ? themeProvider.accentColor : Colors.blue[600],
                                                                      ),
                                                                      const SizedBox(width: 4),
                                                                      Text(
                                                                        field.distance != null
                                                                            ? '${field.distance!.toStringAsFixed(1)} km'
                                                                            : 'N/A',
                                                                        style: TextStyle(
                                                                          fontFamily: 'Roboto',
                                                                          fontSize: 12,
                                                                          color: isModern ? themeProvider.accentColor : Colors.blue[600],
                                                                          fontWeight: FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(
                                                                        Icons.monetization_on,
                                                                        color: isModern ? themeProvider.accentColor : Colors.green[600],
                                                                        size: 16,
                                                                      ),
                                                                      const SizedBox(width: 2),
                                                                      Text(
                                                                        '${field.pricePerHour.toInt()} VNĐ/giờ',
                                                                        style: TextStyle(
                                                                          fontFamily: 'Roboto',
                                                                          fontWeight: FontWeight.bold,
                                                                          fontSize: 12,
                                                                          color: isModern ? themeProvider.accentColor : Colors.green[700],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
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
            ),
          ],
        ),
        bottomNavigationBar: null,
      );
  }
}
