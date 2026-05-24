import 'package:flutter/material.dart';
import '../models/field.dart';
import '../services/api_service.dart';
import '../services/map_service.dart';
import 'location_picker_screen.dart';
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
      } else {
        lengthController.text = "70";
        widthController.text = "50";
      }
      _hasInitialized = true;
    }
  }

  void submit() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
      // Đảm bảo openingTime/closingTime đúng định dạng HH:mm:ss
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
        length: double.tryParse(lengthController.text),
        width: double.tryParse(widthController.text),
        grassType: grassTypeController.text,
        openingTime: opening,
        closingTime: closing,
        available: available,
        outdoor: outdoor,
        latitude: selectedLocation?.latitude ?? field?.latitude,
        longitude: selectedLocation?.longitude ?? field?.longitude,
      );
      if (field == null) {
        // Tạo mới sân
        ApiService.createField(newField).then((success) {
          setState(() {
            isLoading = false;
          });
          if (success) {
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Field creation failed")));
          }
        });
      } else {
        // Cập nhật sân
        ApiService.updateField(newField).then((success) {
          setState(() {
            isLoading = false;
          });
          if (success) {
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Field update failed")));
          }
        });
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
      print('Add Edit Field - Received result from LocationPicker:');
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

  // Cải thiện method để xem vị trí trên bản đồ
  Future<void> _viewOnMap() async {
    String address = addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập địa chỉ hoặc chọn vị trí trên bản đồ trước'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Hiển thị loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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
        backgroundColor: Colors.blue,
      ),
    );

    try {
      await MapService.openDirectionsWithAddress(address);

      // Nếu đến được đây nghĩa là đã mở thành công, hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã mở Google Maps thành công'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error opening maps: $e');
      // Chỉ hiển thị lỗi khi thực sự không thể mở Maps
      if (e.toString().contains('Không thể mở Google Maps')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở Google Maps. Vui lòng kiểm tra kết nối internet hoặc cài đặt Google Maps.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _viewOnMap,
            ),
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        // Với các lỗi khác, chỉ log và không hiển thị cho user
        print('Maps opened but with minor issues: $e');
      }
    }
  }

  Future<int?> _selectHour(BuildContext context, int initialHour, String title, {int? minHour, int? maxHour}) async {
    return await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800]), textAlign: TextAlign.center),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: 25,
              itemBuilder: (context, index) {
                int hour = index;
                bool isSelected = hour == initialHour;
                
                // Check if disabled
                bool isDisabled = false;
                if (minHour != null && hour < minHour) isDisabled = true;
                if (maxHour != null && hour > maxHour) isDisabled = true;
                
                if (isDisabled) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${hour}h',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[400],
                      ),
                    ),
                  );
                }
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, hour),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.amber : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.amber[700]! : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 6, offset: Offset(0, 3))]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${hour}h',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Hủy", style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = field == null ? "Thêm sân mới" : "Chỉnh sửa sân";
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800])),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.amber[800]),
      ),
      backgroundColor: Color(0xFFF8F8F8),
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
                  child: Icon(Icons.sports_soccer, color: Colors.amber, size: 60),
                ),
                SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Tên sân",
                    prefixIcon: Icon(Icons.sports_soccer, color: Colors.green[700]),
                    filled: true,
                    fillColor: Colors.amber[50],
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
                    labelText: "Địa chỉ",
                    hintText: "Vui lòng chọn vị trí",
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
                            : Icon(Icons.map_outlined, color: Colors.blue[600], size: 28),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Vui lòng chọn vị trí trên bản đồ";
                    }
                    // Nếu tạo mới, bắt buộc phải có location
                    if (field == null && selectedLocation == null) {
                       return "Vui lòng chọn vị trí trên bản đồ";
                    }
                    // Nếu edit, cho phép pass nếu đã có address text (kể cả khi không có tọa độ)
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
                    fillColor: Colors.amber[50],
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
                    fillColor: Colors.amber[50],
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
                    fillColor: Colors.amber[50],
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
                    fillColor: Colors.amber[50],
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
                    fillColor: Colors.amber[50],
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
                    fillColor: Colors.amber[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: openingTimeController,
                        readOnly: true,
                        onTap: () async {
                          int initial = 7;
                          if (openingTimeController.text.isNotEmpty) {
                            try {
                              initial = int.parse(openingTimeController.text.replaceAll(RegExp(r'[^0-9]'), ''));
                            } catch (_) {}
                          }
                          
                          int? maxHour;
                          if (closingTimeController.text.isNotEmpty) {
                             try {
                              maxHour = int.parse(closingTimeController.text.replaceAll(RegExp(r'[^0-9]'), '')) - 1;
                            } catch (_) {}
                          }
                          
                          final int? pickedHour = await _selectHour(context, initial, "Chọn giờ mở cửa", maxHour: maxHour);
                          
                          if (pickedHour != null) {
                            setState(() {
                              openingTimeController.text = '${pickedHour}h';
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: "Mở cửa",
                          hintText: "6h",
                          prefixIcon: Icon(Icons.access_time, color: Colors.purple),
                          filled: true,
                          fillColor: Colors.amber[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: closingTimeController,
                        readOnly: true,
                        onTap: () async {
                          int initial = 22;
                          if (closingTimeController.text.isNotEmpty) {
                            try {
                              initial = int.parse(closingTimeController.text.replaceAll(RegExp(r'[^0-9]'), ''));
                            } catch (_) {}
                          }
                          
                          int? minHour;
                          if (openingTimeController.text.isNotEmpty) {
                             try {
                              minHour = int.parse(openingTimeController.text.replaceAll(RegExp(r'[^0-9]'), '')) + 1;
                            } catch (_) {}
                          }
                          
                          final int? pickedHour = await _selectHour(context, initial, "Chọn giờ đóng cửa", minHour: minHour);
                          
                          if (pickedHour != null) {
                            setState(() {
                              closingTimeController.text = '${pickedHour}h';
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: "Đóng cửa",
                          hintText: "22h",
                          prefixIcon: Icon(Icons.access_time_filled, color: Colors.deepPurple),
                          filled: true,
                          fillColor: Colors.amber[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                  title: Text("Có sẵn để đặt?", style: TextStyle(fontWeight: FontWeight.w500)),
                  secondary: Icon(Icons.check_circle, color: Colors.green),
                  activeColor: Colors.amber,
                ),
                SwitchListTile(
                  value: outdoor,
                  onChanged: (val) => setState(() => outdoor = val),
                  title: Text("Sân ngoài trời?", style: TextStyle(fontWeight: FontWeight.w500)),
                  secondary: Icon(Icons.wb_sunny, color: Colors.orange),
                  activeColor: Colors.amber,
                ),
                SizedBox(height: 32),
                isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.amber))
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: submit,
                          icon: Icon(field == null ? Icons.add : Icons.save, color: Colors.white),
                          label: Text(field == null ? "Thêm sân" : "Lưu thay đổi"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
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
                    icon: Icon(Icons.cancel, color: Colors.amber),
                    label: Text("Hủy"),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.amber, width: 2),
                      foregroundColor: Colors.amber,
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
