import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/field.dart';
import '../services/api_service.dart';
import '../services/image_compressor.dart';
import 'location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminAddEditFieldScreen extends StatefulWidget {
  @override
  _AdminAddEditFieldScreenState createState() => _AdminAddEditFieldScreenState();
}

class _AdminAddEditFieldScreenState extends State<AdminAddEditFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController typeController = TextEditingController();
  TextEditingController facilitiesController = TextEditingController();
  TextEditingController priceController = TextEditingController();
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
  LatLng? selectedLocation; // Thêm biến lưu vị trí đã chọn
  bool _hasInitialized = false; // Thêm flag để tránh override

  // Image upload state
  List<File> _newImages = [];
  List<Map<String, dynamic>> _existingImages = [];
  bool _isUploadingImages = false;
  String _imageStatusText = 'Đang xử lý...';
  final ImagePicker _picker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Chỉ initialize một lần để tránh override sau khi user đã chọn location
    if (!_hasInitialized) {
      final Field? args = ModalRoute.of(context)?.settings.arguments as Field?;
      if (args != null) {
        field = args;
        nameController.text = field!.name;
        addressController.text = field!.address;
        typeController.text = field!.type ?? "";
        facilitiesController.text = field!.facilities ?? "";
        priceController.text = field!.pricePerHour.toString();
        depositController.text = field!.depositAmount.toString();
        lengthController.text = field!.length?.toString() ?? "70";
        widthController.text = field!.width?.toString() ?? "50";
        grassTypeController.text = field!.grassType ?? "";
        openingTimeController.text = field!.openingTime ?? "";
        closingTimeController.text = field!.closingTime ?? "";
        available = field!.available ?? true;
        outdoor = field!.outdoor ?? true;
        if (field!.latitude != null && field!.longitude != null) {
          selectedLocation = LatLng(field!.latitude!, field!.longitude!);
        }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tối đa 5 ảnh!'), backgroundColor: Colors.orange),
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
                leading: CircleAvatar(backgroundColor: Colors.green[100], child: Icon(Icons.photo_library, color: Colors.green[800])),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Đã xóa ảnh'), backgroundColor: Colors.green));
    }
  }

  Widget _buildImageSection() {
    final totalImages = _existingImages.length + _newImages.length;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.photo_camera, color: Colors.green[800]),
            SizedBox(width: 8),
            Text('Hình ảnh sân bóng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[800])),
            Spacer(),
            Text('$totalImages/5', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
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
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Đã chọn làm ảnh đại diện'), backgroundColor: Colors.green));
                            }
                          },
                          child: CachedNetworkImage(
                            imageUrl: img['url'],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (_, __, ___) => Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                      if (isPrimary) Positioned(top: 4, left: 4, child: Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)), child: Text('★', style: TextStyle(fontSize: 12, color: Colors.white)))),
                      Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => _removeExistingImage(img['id']), child: Container(padding: EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Icon(Icons.close, color: Colors.white, size: 14)))),
                    ]),
                  );
                }),
                ..._newImages.asMap().entries.map((entry) {
                  return _buildImageTile(
                    child: Stack(fit: StackFit.expand, children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(entry.value, fit: BoxFit.cover)),
                      Positioned(top: 4, left: 4, child: Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)), child: Text('Mới', style: TextStyle(fontSize: 10, color: Colors.white)))),
                      Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => _removeNewImage(entry.key), child: Container(padding: EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Icon(Icons.close, color: Colors.white, size: 14)))),
                    ]),
                  );
                }),
                if (totalImages < 5)
                  _buildImageTile(
                    child: GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[400]!)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate, color: Colors.grey[600], size: 32),
                          SizedBox(height: 4),
                          Text('Thêm ảnh', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
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
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text(_imageStatusText, style: TextStyle(color: Colors.green[800], fontSize: 13)),
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
      setState(() {
        isLoading = true;
      });
      // Đảm bảo openingTime/closingTime đúng định dạng HH:mm:ss
      String opening = openingTimeController.text.trim();
      String closing = closingTimeController.text.trim();
      if (opening.length == 5) opening += ':00';
      if (closing.length == 5) closing += ':00';
      Field newField = Field(
        id: field?.id,
        name: nameController.text,
        address: addressController.text,
        type: typeController.text,
        facilities: facilitiesController.text,
        pricePerHour: double.tryParse(priceController.text) ?? 0.0,
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
        // Tạo mới sân
        Field? createdField = await ApiService.adminCreateField(newField);
        if (createdField != null) {
          if (_newImages.isNotEmpty && createdField.id != null) {
            setState(() {
              _isUploadingImages = true;
              _imageStatusText = 'Đang upload ảnh lên server...';
            });
            await ApiService.uploadFieldImages(createdField.id!, _newImages);
            setState(() { _isUploadingImages = false; });
          }
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Tạo sân thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Trả về true để báo hiệu cần refresh
        } else {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Tạo sân thất bại")));
        }
      } else {
        // Cập nhật sân
        bool success = await ApiService.adminUpdateField(newField);
        if (success) {
          if (_newImages.isNotEmpty && field!.id != null) {
            setState(() {
              _isUploadingImages = true;
              _imageStatusText = 'Đang upload ảnh lên server...';
            });
            await ApiService.uploadFieldImages(field!.id!, _newImages);
            setState(() { _isUploadingImages = false; });
          }
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Cập nhật sân thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Trả về true để báo hiệu cần refresh
        } else {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Cập nhật sân thất bại")));
        }
      }
    }
  }

  // Thêm method để mở Location Picker
  Future<void> _openLocationPicker() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationPickerScreen(
            initialAddress: addressController.text.trim(),
            initialLocation: selectedLocation,
          ),
        ),
      );

      // Debug logging
      print('Admin Add Edit Field - Received result from LocationPicker:');
      print('result: $result');
      print('result type: ${result.runtimeType}');

      if (result != null && result is Map<String, dynamic>) {
        print('Processing result map...');

        // Lấy location
        var locationData = result['location'];
        print('locationData: $locationData (${locationData.runtimeType})');

        // Lấy address
        var addressData = result['address'];
        print('addressData: "$addressData" (${addressData.runtimeType})');

        // Cải thiện xử lý address
        String newAddress = '';
        if (addressData != null) {
          newAddress = addressData.toString().trim();
        }

        print('newAddress after processing: "$newAddress"');
        print('Current addressController.text before update: "${addressController.text}"');

        setState(() {
          selectedLocation = locationData as LatLng?;

          // Chỉ cập nhật nếu địa chỉ không rỗng và không phải null string
          if (newAddress.isNotEmpty && newAddress != 'null' && newAddress != 'Địa chỉ không xác định') {
            addressController.text = newAddress;
            print('Updated addressController.text to: "${addressController.text}"');
          } else {
            print('Address was empty or invalid, not updating');
          }
        });

        // Force refresh UI
        await Future.delayed(Duration(milliseconds: 100));
        setState(() {});

        print('Final addressController.text after setState: "${addressController.text}"');

        // Hiển thị thông báo thành công với địa chỉ đã chọn
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Đã chọn vị trí thành công!'),
                Text('📍 ${addressController.text}',
                     style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        print('Result is null or not a Map');
      }
    } catch (e) {
      print('Error opening location picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi mở bản đồ: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = field == null ? "Thêm sân mới" : "Chỉnh sửa sân";
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: Icon(Icons.admin_panel_settings, color: Colors.green, size: 60),
                ),
                SizedBox(height: 16),
                _buildImageSection(),
                SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Tên sân",
                    prefixIcon: Icon(Icons.sports_soccer, color: Colors.green[700]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (value) => value!.isEmpty ? "Bắt buộc" : null,
                ),
                SizedBox(height: 18),
                // Thay đổi TextFormField địa chỉ thành read-only
                TextFormField(
                  controller: addressController,
                  readOnly: true, // Không cho phép nhập thủ công
                  decoration: InputDecoration(
                    labelText: "Địa chỉ (bấm vào icon để chọn)",
                    hintText: "Bấm vào icon bản đồ để chọn vị trí",
                    prefixIcon: Icon(Icons.location_on, color: Colors.redAccent),
                    filled: true,
                    fillColor: selectedLocation != null ? Colors.green[50] : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    suffixIcon: GestureDetector(
                      onTap: _openLocationPicker,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: selectedLocation != null
                            ? Icon(Icons.check_circle, color: Colors.green, size: 28)
                            : Icon(Icons.map_outlined, color: Colors.green, size: 28),
                      ),
                    ),
                  ),
                  validator: (value) {
                    // Nếu đang edit sân và đã có địa chỉ, không cần validate selectedLocation
                    if (field != null && value != null && value.isNotEmpty) {
                      return null; // Đã có địa chỉ từ trước, không cần chọn lại
                    }
                    // Nếu đang tạo mới hoặc chưa có địa chỉ thì mới kiểm tra selectedLocation
                    if (value == null || value.isEmpty || selectedLocation == null) {
                      return "Vui lòng chọn vị trí trên bản đồ";
                    }
                    return null;
                  },
                  onTap: () {
                    // Khi tap vào field, mở location picker
                    _openLocationPicker();
                  },
                ),
                // Hiển thị thông tin vị trí đã chọn
                if (selectedLocation != null)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vị trí đã được chọn trên bản đồ\nTọa độ: ${selectedLocation!.latitude.toStringAsFixed(6)}, ${selectedLocation!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: typeController.text.isNotEmpty ? typeController.text : null,
                  items: [
                    DropdownMenuItem(value: '5', child: Text('Sân 5 người')),
                    DropdownMenuItem(value: '7', child: Text('Sân 7 người')),
                    DropdownMenuItem(value: '11', child: Text('Sân 11 người')),
                  ],
                  onChanged: (val) {
                    setState(() => typeController.text = val ?? '');
                  },
                  decoration: InputDecoration(
                    labelText: "Loại sân",
                    prefixIcon: Icon(Icons.category, color: Colors.blueAccent),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                SizedBox(height: 18),
                TextFormField(
                  controller: facilitiesController,
                  decoration: InputDecoration(
                    labelText: "Tiện ích",
                    prefixIcon: Icon(Icons.wifi, color: Colors.teal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                SizedBox(height: 18),
                TextFormField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: "Giá mỗi giờ (VNĐ)",
                    prefixIcon: Icon(Icons.attach_money, color: Colors.deepOrange),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? "Bắt buộc" : null,
                ),
                SizedBox(height: 18),
                TextFormField(
                  controller: depositController,
                  decoration: InputDecoration(
                    labelText: "Số tiền cọc (VNĐ)",
                    prefixIcon: Icon(Icons.security, color: Colors.green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? "Bắt buộc" : null,
                ),
                SizedBox(height: 18),
                TextFormField(
                  controller: lengthController,
                  decoration: InputDecoration(
                    labelText: "Chiều dài (m)",
                    prefixIcon: Icon(Icons.straighten, color: Colors.green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 18),
                TextFormField(
                  controller: widthController,
                  decoration: InputDecoration(
                    labelText: "Chiều rộng (m)",
                    prefixIcon: Icon(Icons.straighten, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: grassTypeController.text.isNotEmpty ? grassTypeController.text : null,
                  items: [
                    DropdownMenuItem(value: 'artificial', child: Text('Cỏ nhân tạo')),
                    DropdownMenuItem(value: 'natural', child: Text('Cỏ tự nhiên')),
                  ],
                  onChanged: (val) {
                    setState(() => grassTypeController.text = val ?? '');
                  },
                  decoration: InputDecoration(
                    labelText: "Loại cỏ",
                    prefixIcon: Icon(Icons.grass, color: Colors.teal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                SizedBox(height: 18),
                TextFormField(
                  controller: openingTimeController,
                  readOnly: true,
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: openingTimeController.text.isNotEmpty
                        ? TimeOfDay(
                            hour: int.tryParse(openingTimeController.text.split(":")[0]) ?? 7,
                            minute: int.tryParse(openingTimeController.text.split(":")[1]) ?? 0)
                        : TimeOfDay(hour: 7, minute: 0),
                    );
                    if (picked != null) {
                      setState(() {
                        openingTimeController.text = picked.format(context);
                        // Lưu lại theo định dạng HH:mm
                        final hour = picked.hour.toString().padLeft(2, '0');
                        final min = picked.minute.toString().padLeft(2, '0');
                        openingTimeController.text = '$hour:$min';
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: "Giờ mở cửa (HH:mm)",
                    prefixIcon: Icon(Icons.access_time, color: Colors.purple),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                SizedBox(height: 18),
                TextFormField(
                  controller: closingTimeController,
                  readOnly: true,
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: closingTimeController.text.isNotEmpty
                        ? TimeOfDay(
                            hour: int.tryParse(closingTimeController.text.split(":")[0]) ?? 22,
                            minute: int.tryParse(closingTimeController.text.split(":")[1]) ?? 0)
                        : TimeOfDay(hour: 22, minute: 0),
                    );
                    if (picked != null) {
                      setState(() {
                        closingTimeController.text = picked.format(context);
                        final hour = picked.hour.toString().padLeft(2, '0');
                        final min = picked.minute.toString().padLeft(2, '0');
                        closingTimeController.text = '$hour:$min';
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: "Giờ đóng cửa (HH:mm)",
                    prefixIcon: Icon(Icons.access_time, color: Colors.deepPurple),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SwitchListTile(
                    value: available,
                    onChanged: (val) => setState(() => available = val),
                    title: Text("Có sẵn để đặt?", style: TextStyle(fontWeight: FontWeight.w500)),
                    secondary: Icon(Icons.check_circle, color: Colors.green),
                    activeColor: Colors.green,
                  ),
                ),
                SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SwitchListTile(
                    value: outdoor,
                    onChanged: (val) => setState(() => outdoor = val),
                    title: Text("Sân ngoài trời?", style: TextStyle(fontWeight: FontWeight.w500)),
                    secondary: Icon(Icons.wb_sunny, color: Colors.orange),
                    activeColor: Colors.green,
                  ),
                ),
                SizedBox(height: 32),
                isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.green))
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: submit,
                          icon: Icon(field == null ? Icons.add : Icons.save, color: Colors.white),
                          label: Text(field == null ? "Thêm sân" : "Lưu thay đổi"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
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
                    icon: Icon(Icons.cancel, color: Colors.green),
                    label: Text("Hủy"),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.green, width: 2),
                      foregroundColor: Colors.green,
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


