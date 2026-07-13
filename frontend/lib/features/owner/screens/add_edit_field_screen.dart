import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../models/field.dart';
import '../../../services/api_service.dart';
import '../../../services/map_service.dart';
import '../../../services/image_compressor.dart';
import '../../../services/theme_service.dart';
import '../../field/screens/location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddEditFieldScreen extends StatefulWidget {
  @override
  _AddEditFieldScreenState createState() => _AddEditFieldScreenState();
}

class _AddEditFieldScreenState extends State<AddEditFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController typeController = TextEditingController();
  TextEditingController facilitiesController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController peakPriceController = TextEditingController();
  TextEditingController depositController = TextEditingController();
  TextEditingController lengthController = TextEditingController();
  TextEditingController widthController = TextEditingController();
  TextEditingController grassTypeController = TextEditingController();
  TextEditingController openingTimeController = TextEditingController();
  TextEditingController closingTimeController = TextEditingController();
  bool available = true;
  bool outdoor = true;
  bool isLoading = false;
  Field? field;
  LatLng? selectedLocation;
  bool _hasInitialized = false;

  // Image upload state
  List<File> _newImages = [];
  List<Map<String, dynamic>> _existingImages = [];
  bool _isUploadingImages = false;
  String _imageStatusText = 'Đang xử lý...';
  final ImagePicker _picker = ImagePicker();

  void _showCustomSnackBar({
    required String message,
    required Color iconColor,
    required IconData icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isModern = themeProvider.isModernMode;

    final defaultBg = isModern ? const Color(0xFF1E222B) : Colors.grey[900]!;
    final bg = backgroundColor ?? defaultBg;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isModern 
              ? BorderSide(color: iconColor.withValues(alpha: 0.3), width: 1.5) 
              : BorderSide.none,
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitialized) {
      final Field? args = ModalRoute.of(context)?.settings.arguments as Field?;
      if (args != null) {
        field = args;
        nameController.text = field!.name;
        addressController.text = field!.address;
        typeController.text = field!.type ?? "";
        facilitiesController.text = field!.facilities ?? "";
        priceController.text = field!.pricePerHour.toInt().toString();
        peakPriceController.text = field!.pricePerHourPeak?.toInt().toString() ?? "";
        depositController.text = field!.depositAmount.toInt().toString();
        lengthController.text = field!.length?.toString() ?? "70";
        widthController.text = field!.width?.toString() ?? "50";
        grassTypeController.text = field!.grassType ?? "";
        if (field!.openingTime != null && field!.openingTime!.isNotEmpty) {
          try {
            int h = int.parse(field!.openingTime!.split(':')[0]);
            openingTimeController.text = '${h}h';
          } catch (_) {
            openingTimeController.text = field!.openingTime!;
          }
        }
        if (field!.closingTime != null && field!.closingTime!.isNotEmpty) {
          try {
            int h = int.parse(field!.closingTime!.split(':')[0]);
            closingTimeController.text = '${h}h';
          } catch (_) {
            closingTimeController.text = field!.closingTime!;
          }
        }
        if (field!.latitude != null && field!.longitude != null) {
          selectedLocation = LatLng(field!.latitude!, field!.longitude!);
        }
        available = field!.available ?? true;
        outdoor = field!.outdoor ?? true;
        if (field!.id != null) {
          _loadExistingImages();
        }
      } else {
        lengthController.text = "70";
        widthController.text = "50";
        depositController.text = "0";
      }
      _hasInitialized = true;
    }
  }

  Future<void> _loadExistingImages() async {
    if (field?.id == null) return;
    final images = await ApiService.getFieldImages(field!.id!);
    setState(() {
      _existingImages = images;
    });
  }

  Future<void> _pickImages() async {
    final totalImages = _existingImages.length + _newImages.length;
    if (totalImages >= 5) {
      _showCustomSnackBar(
        message: 'Tối đa 5 ảnh sân bóng!',
        iconColor: Colors.orangeAccent,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }
    final remaining = 5 - totalImages;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Chọn ảnh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.amber[100], child: Icon(Icons.photo_library, color: Colors.amber[800])),
                title: Text('Chọn từ thư viện'),
                subtitle: Text('Chọn tối đa $remaining ảnh'),
                onTap: () async {
                  Navigator.pop(context);
                  final List<XFile> images = await _picker.pickMultiImage(maxWidth: 1920, imageQuality: 85);
                  if (images.isNotEmpty) {
                    final toAdd = images.take(remaining).toList();
                    setState(() {
                      _isUploadingImages = true;
                      _imageStatusText = 'Đang nén và chuyển đổi WebP...';
                    });
                    for (var x in toAdd) {
                      File? compressed = await ImageCompressor.compressToWebp(File(x.path));
                      if (compressed != null) {
                        setState(() { _newImages.add(compressed); });
                      } else {
                        setState(() { _newImages.add(File(x.path)); });
                      }
                    }
                    setState(() { _isUploadingImages = false; });
                  }
                },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue[100], child: Icon(Icons.camera_alt, color: Colors.blue[800])),
                title: Text('Chụp ảnh mới'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1920, imageQuality: 85);
                  if (image != null) {
                    setState(() {
                      _isUploadingImages = true;
                      _imageStatusText = 'Đang nén và chuyển đổi WebP...';
                    });
                    File? compressed = await ImageCompressor.compressToWebp(File(image.path));
                    if (compressed != null) {
                      setState(() { _newImages.add(compressed); });
                    } else {
                      setState(() { _newImages.add(File(image.path)); });
                    }
                    setState(() { _isUploadingImages = false; });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeNewImage(int index) {
    setState(() { _newImages.removeAt(index); });
  }

  Future<void> _removeExistingImage(int imageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa ảnh'),
        content: Text('Bạn có chắc muốn xóa ảnh này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    bool success = await ApiService.deleteFieldImage(imageId);
    if (success) {
      await _loadExistingImages();
      _showCustomSnackBar(
        message: 'Đã xóa ảnh thành công!',
        iconColor: Colors.greenAccent,
        icon: Icons.check_circle_outline,
      );
    }
  }

  Widget _buildImageSection(bool isModern) {
    final totalImages = _existingImages.length + _newImages.length;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isModern ? Colors.white12 : Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isModern ? Colors.white24 : Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.photo_camera, color: isModern ? Colors.white70 : Colors.amber[800]),
            SizedBox(width: 8),
            Text('Hình ảnh sân bóng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isModern ? Colors.white70 : Colors.amber[800])),
            Spacer(),
            Text('$totalImages/5', style: TextStyle(color: isModern ? Colors.white54 : Colors.grey[600], fontSize: 14)),
          ]),
          SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._existingImages.asMap().entries.map((entry) {
                  final img = entry.value;
                  final isPrimary = img['isPrimary'] == true;
                  return _buildImageTile(
                    child: Stack(fit: StackFit.expand, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onTap: isPrimary ? null : () async {
                            bool success = await ApiService.setPrimaryImage(img['id']);
                            if (success) {
                              await _loadExistingImages();
                              _showCustomSnackBar(
                                message: 'Đã thiết lập làm ảnh đại diện thành công!',
                                iconColor: Colors.greenAccent,
                                icon: Icons.star_border_rounded,
                              );
                            }
                          },
                          child: CachedNetworkImage(
                            imageUrl: img['url'],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isModern ? Colors.white : Colors.amber,
                              ),
                            ),
                            errorWidget: (_, __, ___) => Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                      if (isPrimary) Positioned(top: 4, left: 4, child: Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isModern ? Colors.white : Colors.amber, borderRadius: BorderRadius.circular(8)), child: Text('★', style: TextStyle(fontSize: 12, color: isModern ? Colors.black : Colors.white)))),
                      Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => _removeExistingImage(img['id']), child: Container(padding: EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Icon(Icons.close, color: Colors.white, size: 14)))),
                    ]),
                  );
                }),
                ..._newImages.asMap().entries.map((entry) {
                  return _buildImageTile(
                    child: Stack(fit: StackFit.expand, children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(entry.value, fit: BoxFit.cover)),
                      Positioned(top: 4, left: 4, child: Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isModern ? Colors.white : Colors.blue, borderRadius: BorderRadius.circular(8)), child: Text('Mới', style: TextStyle(fontSize: 10, color: isModern ? Colors.black : Colors.white)))),
                      Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => _removeNewImage(entry.key), child: Container(padding: EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Icon(Icons.close, color: Colors.white, size: 14)))),
                    ]),
                  );
                }),
                if (totalImages < 5)
                  _buildImageTile(
                    child: GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isModern ? Colors.white10 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isModern ? Colors.white24 : Colors.grey[400]!),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate, color: isModern ? Colors.white60 : Colors.grey[600], size: 32),
                          SizedBox(height: 4),
                          Text('Thêm ảnh', style: TextStyle(color: isModern ? Colors.white60 : Colors.grey[600], fontSize: 11)),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isUploadingImages)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: isModern ? Colors.white : Colors.amber)),
                SizedBox(width: 8),
                Text(_imageStatusText, style: TextStyle(color: isModern ? Colors.white70 : Colors.amber[800], fontSize: 13)),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildImageTile({required Widget child}) {
    return Container(width: 100, height: 100, margin: EdgeInsets.only(right: 8), child: child);
  }

  void submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() { isLoading = true; });
      String openingStr = openingTimeController.text.trim();
      String closingStr = closingTimeController.text.trim();
      String opening = "";
      if (openingStr.isNotEmpty) {
        int h = int.tryParse(openingStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        opening = '${h.toString().padLeft(2, '0')}:00:00';
      }
      String closing = "";
      if (closingStr.isNotEmpty) {
        int h = int.tryParse(closingStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        closing = '${h.toString().padLeft(2, '0')}:00:00';
      }

      Field newField = Field(
        id: field?.id,
        name: nameController.text,
        address: addressController.text,
        type: typeController.text,
        facilities: facilitiesController.text,
        pricePerHour: double.tryParse(priceController.text) ?? 0.0,
        pricePerHourPeak: double.tryParse(peakPriceController.text),
        depositAmount: double.tryParse(depositController.text) ?? 0.0,
        length: double.tryParse(lengthController.text),
        width: double.tryParse(widthController.text),
        grassType: grassTypeController.text,
        openingTime: opening,
        closingTime: closing,
        available: available,
        outdoor: outdoor,
        imageUrl: field?.imageUrl,
        latitude: selectedLocation?.latitude ?? field?.latitude,
        longitude: selectedLocation?.longitude ?? field?.longitude,
      );

      if (field == null) {
        Field? createdField = await ApiService.createField(newField);
        if (createdField != null) {
          if (_newImages.isNotEmpty && createdField.id != null) {
            setState(() {
              _isUploadingImages = true;
              _imageStatusText = 'Đang upload ảnh lên server...';
            });
            await ApiService.uploadFieldImages(createdField.id!, _newImages);
            setState(() { _isUploadingImages = false; });
          }
          _showCustomSnackBar(
            message: 'Tạo sân bóng mới thành công!',
            iconColor: Colors.greenAccent,
            icon: Icons.check_circle_outline,
          );
          Navigator.pop(context);
        } else {
          _showCustomSnackBar(
            message: 'Tạo sân bóng mới thất bại. Vui lòng kiểm tra lại thông tin!',
            iconColor: Colors.redAccent,
            icon: Icons.error_outline,
          );
        }
      } else {
        bool success = await ApiService.updateField(newField);
        if (success) {
          if (_newImages.isNotEmpty && field!.id != null) {
            setState(() {
              _isUploadingImages = true;
              _imageStatusText = 'Đang upload ảnh lên server...';
            });
            await ApiService.uploadFieldImages(field!.id!, _newImages);
            setState(() { _isUploadingImages = false; });
          }
          _showCustomSnackBar(
            message: 'Cập nhật thông tin sân bóng thành công!',
            iconColor: Colors.greenAccent,
            icon: Icons.check_circle_outline,
          );
          Navigator.pop(context);
        } else {
          _showCustomSnackBar(
            message: 'Cập nhật thông tin sân bóng thất bại!',
            iconColor: Colors.redAccent,
            icon: Icons.error_outline,
          );
        }
      }
      setState(() { isLoading = false; });
    }
  }

  Future<void> _openLocationPicker() async {
    try {
      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPickerScreen(initialAddress: addressController.text.trim(), initialLocation: selectedLocation)));
      if (result != null && result is Map<String, dynamic>) {
        var locationData = result['location'];
        var addressData = result['address'];
        String newAddress = '';
        if (addressData != null) newAddress = addressData.toString().trim();
        setState(() {
          selectedLocation = locationData as LatLng?;
          if (newAddress.isNotEmpty && newAddress != 'null' && newAddress != 'Địa chỉ không xác định') {
            addressController.text = newAddress;
          }
        });
        await Future.delayed(Duration(milliseconds: 100));
        setState(() {});
        _showCustomSnackBar(
          message: 'Đã xác định vị trí thành công!\n📍 ${addressController.text}',
          iconColor: Colors.greenAccent,
          icon: Icons.my_location_rounded,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      _showCustomSnackBar(
        message: 'Lỗi khởi chạy bản đồ: $e',
        iconColor: Colors.redAccent,
        icon: Icons.map_outlined,
      );
    }
  }

  Future<int?> _selectHour(BuildContext context, int initialHour, String title, {int? minHour, int? maxHour, required bool isModern}) async {
    return await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isModern ? Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isModern ? Colors.white : Colors.amber[800]), textAlign: TextAlign.center),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1),
              itemCount: 25,
              itemBuilder: (context, index) {
                int hour = index;
                bool isSelected = hour == initialHour;
                bool isDisabled = false;
                if (minHour != null && hour < minHour) isDisabled = true;
                if (maxHour != null && hour > maxHour) isDisabled = true;
                if (isDisabled) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isModern ? Colors.white10 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isModern ? Colors.white12 : Colors.grey[200]!),
                    ),
                    alignment: Alignment.center,
                    child: Text('${hour}h', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: isModern ? Colors.white30 : Colors.grey[400])),
                  );
                }
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, hour),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? (isModern ? Colors.white : Colors.amber) : (isModern ? Colors.white10 : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? (isModern ? Colors.white : Colors.amber[700]!) : (isModern ? Colors.white24 : Colors.grey[300]!),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [BoxShadow(color: (isModern ? Colors.white24 : Colors.amber.withOpacity(0.4)), blurRadius: 6, offset: Offset(0, 3))] : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${hour}h',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? (isModern ? Colors.black : Colors.white) : (isModern ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy", style: TextStyle(color: isModern ? Colors.white70 : Colors.grey)))],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = themeProvider.isModernMode;
    String title = field == null ? "Thêm sân mới" : "Chỉnh sửa sân";

    return Scaffold(
      backgroundColor: isModern ? Colors.black : Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isModern ? Colors.white : Colors.amber[800])),
        backgroundColor: isModern ? Colors.black : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isModern ? Colors.white : Colors.amber[800]),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageSection(isModern),
                SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  style: TextStyle(color: isModern ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: "Tên sân",
                    labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                    prefixIcon: Icon(Icons.sports_soccer, color: isModern ? Colors.white70 : Colors.green[700]),
                    filled: true,
                    fillColor: isModern ? Colors.white12 : Colors.amber[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: isModern ? BorderSide(color: Colors.white24) : const BorderSide(),
                    ),
                    enabledBorder: isModern ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white12),
                    ) : null,
                  ),
                  validator: (value) => value!.isEmpty ? "Bắt buộc" : null,
                ),
                SizedBox(height: 18),
                TextFormField(
                  controller: addressController,
                  readOnly: true,
                  style: TextStyle(color: isModern ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: "Địa chỉ",
                    labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                    hintText: "Vui lòng chọn vị trí",
                    hintStyle: TextStyle(color: isModern ? Colors.white30 : null),
                    prefixIcon: Icon(Icons.location_on, color: isModern ? Colors.white70 : Colors.redAccent),
                    filled: true,
                    fillColor: selectedLocation != null
                        ? (isModern ? Colors.green.withOpacity(0.1) : Colors.green[50])
                        : (isModern ? Colors.white12 : Colors.grey[100]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: isModern ? BorderSide(color: Colors.white24) : const BorderSide(),
                    ),
                    enabledBorder: isModern ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white12),
                    ) : null,
                    suffixIcon: GestureDetector(
                      onTap: _openLocationPicker,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: selectedLocation != null
                            ? Icon(Icons.check_circle, color: Colors.green, size: 28)
                            : Icon(Icons.map_outlined, color: isModern ? Colors.white70 : Colors.blue[600], size: 28),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Vui lòng chọn vị trí trên bản đồ";
                    if (field == null && selectedLocation == null) return "Vui lòng chọn vị trí trên bản đồ";
                    return null;
                  },
                  onTap: () { _openLocationPicker(); },
                ),
                if (selectedLocation != null)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isModern ? Colors.green.withOpacity(0.1) : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isModern ? Colors.green.withOpacity(0.3) : Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vị trí đã được chọn trên bản đồ\nTọa độ: ${selectedLocation!.latitude.toStringAsFixed(6)}, ${selectedLocation!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(color: isModern ? Colors.green[300] : Colors.green[800], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: typeController.text.isNotEmpty ? typeController.text : null,
                  dropdownColor: isModern ? Color(0xFF1E1E1E) : Colors.white,
                  style: TextStyle(color: isModern ? Colors.white : Colors.black),
                  items: [
                    DropdownMenuItem(value: '5', child: Text('Sân 5 người', style: TextStyle(color: isModern ? Colors.white : Colors.black))),
                    DropdownMenuItem(value: '7', child: Text('Sân 7 người', style: TextStyle(color: isModern ? Colors.white : Colors.black))),
                    DropdownMenuItem(value: '11', child: Text('Sân 11 người', style: TextStyle(color: isModern ? Colors.white : Colors.black))),
                  ],
                  onChanged: (val) { setState(() => typeController.text = val ?? ''); },
                  decoration: InputDecoration(
                    labelText: "Loại sân",
                    labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                    prefixIcon: Icon(Icons.category, color: isModern ? Colors.white70 : Colors.blueAccent),
                    filled: true,
                    fillColor: isModern ? Colors.white12 : Colors.amber[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: isModern ? BorderSide(color: Colors.white24) : const BorderSide(),
                    ),
                    enabledBorder: isModern ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white12),
                    ) : null,
                  ),
                ),
                SizedBox(height: 18),
                TextFormField(
                  controller: facilitiesController,
                  style: TextStyle(color: isModern ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: "Tiện ích",
                    labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                    prefixIcon: Icon(Icons.wifi, color: isModern ? Colors.white70 : Colors.teal),
                    filled: true,
                    fillColor: isModern ? Colors.white12 : Colors.amber[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: isModern ? BorderSide(color: Colors.white24) : const BorderSide(),
                    ),
                    enabledBorder: isModern ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white12),
                    ) : null,
                  ),
                ),
                SizedBox(height: 18),
                TextFormField(
                  controller: priceController,
                  style: TextStyle(color: isModern ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: "Giá mỗi giờ (VNĐ)",
                    labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                    prefixIcon: Icon(Icons.attach_money, color: isModern ? Colors.white70 : Colors.deepOrange),
                    filled: true,
                    fillColor: isModern ? Colors.white12 : Colors.amber[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: isModern ? BorderSide(color: Colors.white24) : const BorderSide(),
                    ),
                    enabledBorder: isModern ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white12),
                    ) : null,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? "Bắt buộc" : null,
                ),
                SizedBox(height: 18),
                TextFormField(
                  controller: peakPriceController,
                  style: TextStyle(color: isModern ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: "Giá giờ cao điểm (VNĐ)",
                    labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                    helperText: "Mặc định bằng 1.3 lần giá thường nếu để trống",
                    helperStyle: TextStyle(color: isModern ? Colors.white30 : Colors.grey[600], fontSize: 12),
                    prefixIcon: Icon(Icons.flash_on, color: isModern ? Colors.white70 : Colors.amber),
                    filled: true,
                    fillColor: isModern ? Colors.white12 : Colors.amber[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: isModern ? BorderSide(color: Colors.white24) : const BorderSide(),
                    ),
                    enabledBorder: isModern ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white12),
                    ) : null,
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 18),
                TextFormField(
                  controller: depositController,
                  style: TextStyle(color: isModern ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: "Số tiền cọc (VNĐ)",
                    labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                    prefixIcon: Icon(Icons.security, color: isModern ? Colors.white70 : Colors.green),
                    filled: true,
                    fillColor: isModern ? Colors.white12 : Colors.amber[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: isModern ? BorderSide(color: Colors.white24) : const BorderSide(),
                    ),
                    enabledBorder: isModern ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white12),
                    ) : null,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? "Bắt buộc" : null,
                ),
                SizedBox(height: 18),
                TextFormField(
                  controller: lengthController,
                  style: TextStyle(color: isModern ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: "Chiều dài (m)",
                    labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                    prefixIcon: Icon(Icons.straighten, color: isModern ? Colors.white70 : Colors.green),
                    filled: true,
                    fillColor: isModern ? Colors.white12 : Colors.amber[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: isModern ? BorderSide(color: Colors.white24) : const BorderSide(),
                    ),
                    enabledBorder: isModern ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white12),
                    ) : null,
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 18),
                TextFormField(
                  controller: widthController,
                  style: TextStyle(color: isModern ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: "Chiều rộng (m)",
                    labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                    prefixIcon: Icon(Icons.straighten, color: isModern ? Colors.white70 : Colors.blue),
                    filled: true,
                    fillColor: isModern ? Colors.white12 : Colors.amber[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: isModern ? BorderSide(color: Colors.white24) : const BorderSide(),
                    ),
                    enabledBorder: isModern ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white12),
                    ) : null,
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: grassTypeController.text.isNotEmpty ? grassTypeController.text : null,
                  dropdownColor: isModern ? Color(0xFF1E1E1E) : Colors.white,
                  style: TextStyle(color: isModern ? Colors.white : Colors.black),
                  items: [
                    DropdownMenuItem(value: 'artificial', child: Text('Cỏ nhân tạo', style: TextStyle(color: isModern ? Colors.white : Colors.black))),
                    DropdownMenuItem(value: 'natural', child: Text('Cỏ tự nhiên', style: TextStyle(color: isModern ? Colors.white : Colors.black))),
                  ],
                  onChanged: (val) { setState(() => grassTypeController.text = val ?? ''); },
                  decoration: InputDecoration(
                    labelText: "Loại cỏ",
                    labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                    prefixIcon: Icon(Icons.grass, color: isModern ? Colors.white70 : Colors.teal),
                    filled: true,
                    fillColor: isModern ? Colors.white12 : Colors.amber[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: isModern ? BorderSide(color: Colors.white24) : const BorderSide(),
                    ),
                    enabledBorder: isModern ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white12),
                    ) : null,
                  ),
                ),
                SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: openingTimeController,
                        readOnly: true,
                        style: TextStyle(color: isModern ? Colors.white : Colors.black),
                        onTap: () async {
                          int initial = 7;
                          if (openingTimeController.text.isNotEmpty) {
                            try { initial = int.parse(openingTimeController.text.replaceAll(RegExp(r'[^0-9]'), '')); } catch (_) {}
                          }
                          int? maxHour;
                          if (closingTimeController.text.isNotEmpty) {
                            try { maxHour = int.parse(closingTimeController.text.replaceAll(RegExp(r'[^0-9]'), '')) - 1; } catch (_) {}
                          }
                          final int? pickedHour = await _selectHour(context, initial, "Chọn giờ mở cửa", maxHour: maxHour, isModern: isModern);
                          if (pickedHour != null) { setState(() { openingTimeController.text = '${pickedHour}h'; }); }
                        },
                        decoration: InputDecoration(
                          labelText: "Mở cửa",
                          labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                          hintText: "6h",
                          hintStyle: TextStyle(color: isModern ? Colors.white30 : null),
                          prefixIcon: Icon(Icons.access_time, color: isModern ? Colors.white70 : Colors.purple),
                          filled: true,
                          fillColor: isModern ? Colors.white12 : Colors.amber[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: isModern ? BorderSide(color: Colors.white24) : const BorderSide(),
                          ),
                          enabledBorder: isModern ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white12),
                          ) : null,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: closingTimeController,
                        readOnly: true,
                        style: TextStyle(color: isModern ? Colors.white : Colors.black),
                        onTap: () async {
                          int initial = 22;
                          if (closingTimeController.text.isNotEmpty) {
                            try { initial = int.parse(closingTimeController.text.replaceAll(RegExp(r'[^0-9]'), '')); } catch (_) {}
                          }
                          int? minHour;
                          if (openingTimeController.text.isNotEmpty) {
                            try { minHour = int.parse(openingTimeController.text.replaceAll(RegExp(r'[^0-9]'), '')) + 1; } catch (_) {}
                          }
                          final int? pickedHour = await _selectHour(context, initial, "Chọn giờ đóng cửa", minHour: minHour, isModern: isModern);
                          if (pickedHour != null) { setState(() { closingTimeController.text = '${pickedHour}h'; }); }
                        },
                        decoration: InputDecoration(
                          labelText: "Đóng cửa",
                          labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                          hintText: "22h",
                          hintStyle: TextStyle(color: isModern ? Colors.white30 : null),
                          prefixIcon: Icon(Icons.access_time_filled, color: isModern ? Colors.white70 : Colors.deepPurple),
                          filled: true,
                          fillColor: isModern ? Colors.white12 : Colors.amber[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: isModern ? BorderSide(color: Colors.white24) : const BorderSide(),
                          ),
                          enabledBorder: isModern ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white12),
                          ) : null,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                SwitchListTile(
                  value: available,
                  onChanged: (val) => setState(() => available = val),
                  title: Text(
                    "Có sẵn để đặt?",
                    style: TextStyle(fontWeight: FontWeight.w500, color: isModern ? Colors.white : Colors.black87),
                  ),
                  secondary: Icon(Icons.check_circle, color: Colors.green),
                  activeColor: isModern ? Colors.white : Colors.amber,
                  activeTrackColor: isModern ? Colors.white24 : null,
                  inactiveTrackColor: isModern ? Colors.white10 : null,
                ),
                SwitchListTile(
                  value: outdoor,
                  onChanged: (val) => setState(() => outdoor = val),
                  title: Text(
                    "Sân ngoài trời?",
                    style: TextStyle(fontWeight: FontWeight.w500, color: isModern ? Colors.white : Colors.black87),
                  ),
                  secondary: Icon(Icons.wb_sunny, color: Colors.orange),
                  activeColor: isModern ? Colors.white : Colors.amber,
                  activeTrackColor: isModern ? Colors.white24 : null,
                  inactiveTrackColor: isModern ? Colors.white10 : null,
                ),
                SizedBox(height: 32),
                isLoading
                    ? Center(child: CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber))
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: submit,
                          icon: Icon(field == null ? Icons.add : Icons.save, color: isModern ? Colors.black : Colors.white),
                          label: Text(field == null ? "Thêm sân" : "Lưu thay đổi"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isModern ? Colors.white : Colors.amber,
                            foregroundColor: isModern ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                SizedBox(height: 12),
                if (field != null)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.cancel, color: isModern ? Colors.white70 : Colors.amber),
                    label: Text("Hủy"),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isModern ? Colors.white70 : Colors.amber, width: 2),
                      foregroundColor: isModern ? Colors.white70 : Colors.amber,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
