import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/field.dart';
import '../services/api_service.dart';

class BookingScreen extends StatefulWidget {
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  Field? field;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  TextEditingController additionalController = TextEditingController();

  List<Map<String, DateTime>> bookedTimes = [];
  
  // Danh sách các khung giờ chẵn được chọn
  Set<int> selectedSlots = {};
  
  // Khung giờ hoạt động của sân (mặc định 6:00 - 22:00)
  int openingHour = 6;
  int closingHour = 22;

  // Tính tổng số giờ đã chọn
  int get selectedHoursCount => selectedSlots.length;

  int get totalPrice {
    if (field == null) return 0;
    return (selectedHoursCount * field!.pricePerHour).round();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Field args = ModalRoute.of(context)!.settings.arguments as Field;
    field = args;
    
    // Parse opening and closing time if available
    if (field?.openingTime != null) {
      try {
        openingHour = int.parse(field!.openingTime!.split(':')[0]);
      } catch (e) {
        print("Error parsing opening time: $e");
      }
    }
    
    if (field?.closingTime != null) {
      try {
        closingHour = int.parse(field!.closingTime!.split(':')[0]);
        // Nếu closingTime là 22:00 thì int.parse ra 22, loop < closingHour nên chỉ chạy đến 21. 
        // Nhưng thường người ta muốn 22h đóng cửa nghĩa là slot cuối là 21-22. 
        // Logic hiện tại loop i < closingHour (ví dụ 6->22 chạy đến 21). 
        // Slot 21 render "21:00 - 22:00". Vậy là đúng.
        // Tuy nhiên cần kiểm tra nếu closingTime là 00:00 sáng hôm sau thì sao -> thường là 24.
        if (closingHour == 0) closingHour = 24;
      } catch (e) {
        print("Error parsing closing time: $e");
      }
    }
    
    _fetchBookedTimes();
  }

  Future<void> _fetchBookedTimes() async {
    if (field?.id == null) return;
    final times = await ApiService.getBookedTimes(field!.id!);
    setState(() {
      bookedTimes = times;
    });
  }

  // Kiểm tra xem khung giờ có bị đặt không
  bool isSlotBooked(int hour) {
    final slotStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour, 0);
    final slotEnd = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour + 1, 0);
    
    for (final booking in bookedTimes) {
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

  // Toggle chọn khung giờ
  void _toggleSlot(int hour) {
    if (isSlotBooked(hour)) return;
    
    // Tạo bản sao danh sách để kiểm tra thử
    Set<int> testSlots = Set.from(selectedSlots);
    
    if (testSlots.contains(hour)) {
      testSlots.remove(hour);
    } else {
      testSlots.add(hour);
    }

    if (testSlots.isNotEmpty) {
      List<int> sorted = testSlots.toList()..sort();
      bool isConsecutive = true;
      for (int i = 1; i < sorted.length; i++) {
        if (sorted[i] != sorted[i - 1] + 1) {
          isConsecutive = false;
          break;
        }
      }

      if (!isConsecutive) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vui lòng chọn khung giờ liền nhau'), 
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
        return; // Không thực hiện thay đổi
      }
    }
    
    setState(() {
      if (selectedSlots.contains(hour)) {
        selectedSlots.remove(hour);
      } else {
        selectedSlots.add(hour);
      }
    });
  }

  // Chọn tất cả các slot liên tiếp
  void _selectConsecutiveSlots(int startHour, int endHour) {
    setState(() {
      selectedSlots.clear();
      for (int h = startHour; h < endHour; h++) {
        if (!isSlotBooked(h)) {
          selectedSlots.add(h);
        }
      }
    });
  }

  void _addNotification(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final noti = "[${now.day}/${now.month} ${now.hour}:${now.minute.toString().padLeft(2, '0')}] $message";
    final List<String> notifications = prefs.getStringList('notifications') ?? [];
    notifications.insert(0, noti);
    await prefs.setStringList('notifications', notifications);
  }

  // Lấy danh sách các khoảng thời gian liên tiếp từ selectedSlots
  List<Map<String, int>> _getConsecutiveRanges() {
    if (selectedSlots.isEmpty) return [];
    
    List<int> sortedSlots = selectedSlots.toList()..sort();
    List<Map<String, int>> ranges = [];
    
    int rangeStart = sortedSlots[0];
    int rangeEnd = sortedSlots[0] + 1;
    
    for (int i = 1; i < sortedSlots.length; i++) {
      if (sortedSlots[i] == rangeEnd) {
        rangeEnd = sortedSlots[i] + 1;
      } else {
        ranges.add({'start': rangeStart, 'end': rangeEnd});
        rangeStart = sortedSlots[i];
        rangeEnd = sortedSlots[i] + 1;
      }
    }
    ranges.add({'start': rangeStart, 'end': rangeEnd});
    
    return ranges;
  }

  void confirmBooking() async {
    if (field == null) return;
    if (selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn ít nhất một khung giờ!'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Kiểm tra xem các slot có liên tiếp không
    List<int> sortedSlots = selectedSlots.toList()..sort();
    bool isConsecutive = true;
    for (int i = 1; i < sortedSlots.length; i++) {
      if (sortedSlots[i] != sortedSlots[i - 1] + 1) {
        isConsecutive = false;
        break;
      }
    }

    if (!isConsecutive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn khung giờ liền nhau'), backgroundColor: Colors.orange),
      );
      return;
    }

    final fromTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      sortedSlots.first,
      0,
    );

    final toTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      sortedSlots.last + 1,
      0,
    );

    setState(() {
      isLoading = true;
    });

    try {
      bool success = await ApiService.confirmBookingWithAdditional(
        field!.id!,
        fromTime,
        toTime,
        additionalController.text.trim(),
      );

      setState(() {
        isLoading = false;
      });

      if (success) {
        _addNotification('Đặt sân "${field!.name}" thành công lúc ${fromTime.hour.toString().padLeft(2, '0')}:00 - ${toTime.hour.toString().padLeft(2, '0')}:00 ngày ${fromTime.day}/${fromTime.month}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đặt sân thành công'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đặt sân thất bại'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      final errorMsg = e.toString();
      if (errorMsg.contains('Sân đã được đặt vào thời điểm này') || 
          errorMsg.contains('overlap') || 
          errorMsg.contains('trùng lịch')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sân đã được đặt vào thời điểm này'), backgroundColor: Colors.red),
        );
        _fetchBookedTimes(); // Refresh booked times
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra khi đặt sân: $errorMsg'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        selectedSlots.clear(); // Clear selection when date changes
      });
      _fetchBookedTimes();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (field == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Đặt sân", style: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        centerTitle: true,
        backgroundColor: Colors.amber,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card thông tin sân
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sports_soccer, color: Colors.amber[800]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              field!.name,
                              style: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              field!.address,
                              style: const TextStyle(fontFamily: 'Roboto', fontSize: 14, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.green, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'Giá: ',
                            style: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
                          ),
                          Text(
                            '${field!.pricePerHour.toInt()} VNĐ/giờ',
                            style: TextStyle(fontFamily: 'Roboto', color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              
              // Chọn ngày
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: Icon(Icons.calendar_today, color: Colors.amber[800]),
                  title: Text("Ngày đặt sân", style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _selectDate(context),
                  trailing: Icon(Icons.edit_calendar, color: Colors.amber[800]),
                ),
              ),
              const SizedBox(height: 4),
              
              // Tiêu đề chọn khung giờ
              Text(
                "Chọn khung giờ",
                style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "Nhấn để chọn/bỏ chọn khung giờ.",
                style: TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              
              // Grid chọn khung giờ
              TimeSlotGrid(
                openingHour: openingHour,
                closingHour: closingHour,
                selectedSlots: selectedSlots,
                isSlotBooked: isSlotBooked,
                onSlotTap: _toggleSlot,
              ),
              const SizedBox(height: 8),
              
              // Chú thích
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegend(Colors.red[400]!, 'Đã đặt'),
                  const SizedBox(width: 16),
                  _buildLegend(Colors.amber[600]!, 'Đang chọn'),
                  const SizedBox(width: 16),
                  _buildLegend(Colors.grey[300]!, 'Còn trống'),
                ],
              ),
              const SizedBox(height: 4),
              
              // Yêu cầu bổ sung
              TextFormField(
                controller: additionalController,
                style: TextStyle(fontSize: 14, fontFamily: 'Roboto'),
                decoration: InputDecoration(
                  labelText: "Yêu cầu bổ sung (nếu có)",
                  labelStyle: TextStyle(fontSize: 14),
                  prefixIcon: Icon(Icons.note_add, color: Colors.amber, size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  filled: true,
                  fillColor: Colors.amber[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              
              // Thông tin đặt sân
              Card(
                color: Colors.amber[50],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Khung giờ đã chọn:', style: TextStyle(fontFamily: 'Roboto', color: Colors.black54)),
                          Text(
                            _formatSelectedSlots(),
                            style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, color: Colors.amber[900]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Số giờ', style: TextStyle(fontFamily: 'Roboto', color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text(
                                selectedHoursCount > 0 ? '$selectedHoursCount giờ' : '-',
                                style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber[900]),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Tổng tiền', style: TextStyle(fontFamily: 'Roboto', color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text(
                                totalPrice > 0 ? '${totalPrice} VNĐ' : '-',
                                style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[800]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Nút xác nhận
              Center(
                child: isLoading
                    ? CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: selectedSlots.isEmpty ? null : confirmBooking,
                          icon: Icon(Icons.check_circle, color: Colors.white),
                          label: Text(
                            "Xác nhận đặt sân",
                            style: TextStyle(fontSize: 16, fontFamily: 'Roboto', fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[800],
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[400],
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, fontFamily: 'Roboto')),
      ],
    );
  }

  String _formatSelectedSlots() {
    if (selectedSlots.isEmpty) return '';
    List<int> sorted = selectedSlots.toList()..sort();
    return '${sorted.first.toString().padLeft(2, '0')}:00 - ${(sorted.last + 1).toString().padLeft(2, '0')}:00';
  }
}

// Widget hiển thị grid các khung giờ
class TimeSlotGrid extends StatelessWidget {
  final int openingHour;
  final int closingHour;
  final Set<int> selectedSlots;
  final bool Function(int) isSlotBooked;
  final void Function(int) onSlotTap;

  const TimeSlotGrid({
    required this.openingHour,
    required this.closingHour,
    required this.selectedSlots,
    required this.isSlotBooked,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    int totalSlots = closingHour - openingHour;
    int crossAxisCount = 4; // 4 cột
    
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        int hour = openingHour + index;
        bool booked = isSlotBooked(hour);
        bool selected = selectedSlots.contains(hour);
        
        return _TimeSlotButton(
          hour: hour,
          isBooked: booked,
          isSelected: selected,
          onTap: () => onSlotTap(hour),
        );
      },
    );
  }
}

class _TimeSlotButton extends StatelessWidget {
  final int hour;
  final bool isBooked;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSlotButton({
    required this.hour,
    required this.isBooked,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    if (isBooked) {
      backgroundColor = Colors.red[400]!;
      textColor = Colors.white;
      borderColor = Colors.red[600]!;
    } else if (isSelected) {
      backgroundColor = Colors.amber[600]!;
      textColor = Colors.white;
      borderColor = Colors.amber[800]!;
    } else {
      backgroundColor = Colors.grey[200]!;
      textColor = Colors.black87;
      borderColor = Colors.grey[400]!;
    }

    String timeLabel = '${hour.toString().padLeft(2, '0')}:00 - ${(hour + 1).toString().padLeft(2, '0')}:00';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBooked ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              timeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontFamily: 'Roboto',
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
