import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/field.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = themeProvider.isModernMode;

    if (field == null) {
      return Scaffold(
        backgroundColor: isModern ? const Color(0xFF0A0B0E) : Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isModern ? const Color(0xFF0A0B0E) : Colors.white,
      appBar: AppBar(
        title: Text(
          "Đặt sân",
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            color: isModern ? Colors.white : Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        backgroundColor: isModern ? const Color(0xFF0A0B0E) : Colors.amber,
        foregroundColor: isModern ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          if (isModern)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {},
            )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card thông tin sân
              Card(
                color: isModern ? const Color(0xFF16181D) : Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: isModern ? const BorderSide(color: Colors.white24) : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sports_soccer, color: isModern ? const Color(0xFF00E676) : Colors.amber[800]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              field!.name,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isModern ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              field!.address,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                color: isModern ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.green, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'Giá: ',
                            style: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Roboto', color: isModern ? Colors.white : Colors.black),
                          ),
                          Text(
                            '${field!.pricePerHour.toInt()} VNĐ/giờ',
                            style: TextStyle(fontFamily: 'Roboto', color: isModern ? Colors.white70 : Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Chọn ngày
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Chọn ngày đặt sân",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isModern ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.calendar_month,
                      color: isModern ? const Color(0xFF00E676) : Colors.amber[800],
                      size: 20,
                    ),
                    onPressed: () => _selectDate(context),
                    tooltip: 'Chọn ngày bất kỳ',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              HorizontalCalendar(
                selectedDate: selectedDate,
                isModern: isModern,
                onDateSelected: (date) {
                  setState(() {
                    selectedDate = date;
                    selectedSlots.clear();
                  });
                  _fetchBookedTimes();
                },
              ),
              const SizedBox(height: 16),
              
              // Tiêu đề chọn khung giờ
              Text(
                "Chọn khung giờ",
                style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 16, color: isModern ? Colors.white : Colors.black),
              ),
              Text(
                "Nhấn để chọn/bỏ chọn khung giờ.",
                style: TextStyle(fontFamily: 'Roboto', fontSize: 12, color: isModern ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(height: 8),
              
              // Grid chọn khung giờ
              TimeSlotGrid(
                openingHour: openingHour,
                closingHour: closingHour,
                selectedSlots: selectedSlots,
                isSlotBooked: isSlotBooked,
                onSlotTap: _toggleSlot,
                isModern: isModern,
              ),
              const SizedBox(height: 12),
              
              // Chú thích
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildLegend(isModern ? Colors.red[900]!.withValues(alpha: 0.5) : Colors.red[400]!, 'Đã đặt', isModern),
                  _buildLegend(isModern ? Colors.white : Colors.amber[600]!, 'Đang chọn', isModern),
                  _buildLegend(isModern ? const Color(0xFF1A1A1A) : Colors.grey[200]!, 'Còn trống', isModern),
                  _buildLegend(isModern ? const Color(0xFF231709) : Colors.orange.shade50, 'Giờ vàng 🔥', isModern),
                ],
              ),
              const SizedBox(height: 16),
              
              // Yêu cầu bổ sung
              TextFormField(
                controller: additionalController,
                style: TextStyle(fontSize: 14, fontFamily: 'Roboto', color: isModern ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Yêu cầu bổ sung (nếu có)",
                  labelStyle: TextStyle(fontSize: 14, color: isModern ? Colors.white70 : null),
                  prefixIcon: Icon(Icons.note_add, color: isModern ? const Color(0xFF00E676) : Colors.amber, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  filled: true,
                  fillColor: isModern ? const Color(0xFF1A1A1A) : Colors.amber[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: isModern ? const BorderSide(color: Colors.white24) : BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: isModern ? const BorderSide(color: Colors.white12) : BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isModern ? const Color(0xFF00E676) : Colors.amber),
                  ),
                  isDense: true,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              
              // Thông tin đặt sân
              Card(
                color: isModern ? const Color(0xFF16181D) : Colors.amber[50],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isModern ? const BorderSide(color: Colors.white24) : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Khung giờ đã chọn:', style: TextStyle(fontFamily: 'Roboto', color: isModern ? Colors.white54 : Colors.black54)),
                          Text(
                            selectedSlots.isEmpty ? '-' : _formatSelectedSlots(),
                            style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, color: isModern ? Colors.white : Colors.amber[900]),
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
                              Text('Số giờ', style: TextStyle(fontFamily: 'Roboto', color: isModern ? Colors.white54 : Colors.black54)),
                              const SizedBox(height: 4),
                              Text(
                                selectedHoursCount > 0 ? '$selectedHoursCount giờ' : '-',
                                style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 18, color: isModern ? Colors.white : Colors.amber[900]),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Tổng tiền', style: TextStyle(fontFamily: 'Roboto', color: isModern ? Colors.white54 : Colors.black54)),
                              const SizedBox(height: 4),
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                tween: Tween<double>(begin: 0, end: totalPrice.toDouble()),
                                builder: (context, value, child) {
                                  final intPrice = value.round();
                                  return Text(
                                    intPrice > 0 ? '$intPrice VNĐ' : '-',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: isModern ? const Color(0xFF00E676) : Colors.green[800],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Nút xác nhận
              Center(
                child: isLoading
                    ? CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber)
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: selectedSlots.isEmpty ? null : confirmBooking,
                          icon: Icon(Icons.check_circle, color: isModern ? Colors.black : Colors.white),
                          label: const Text(
                            "Xác nhận đặt sân",
                            style: TextStyle(fontSize: 16, fontFamily: 'Roboto', fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isModern ? Colors.white : Colors.amber[800],
                            foregroundColor: isModern ? Colors.black : Colors.white,
                            disabledBackgroundColor: isModern ? Colors.white12 : Colors.grey[400],
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

  Widget _buildLegend(Color color, String text, bool isModern) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: isModern ? Border.all(color: Colors.white24, width: 0.5) : Border.all(color: Colors.black12, width: 0.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Roboto',
            color: isModern ? Colors.white70 : Colors.black87,
          ),
        ),
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
  final bool isModern;

  const TimeSlotGrid({
    required this.openingHour,
    required this.closingHour,
    required this.selectedSlots,
    required this.isSlotBooked,
    required this.onSlotTap,
    this.isModern = false,
  });

  @override
  Widget build(BuildContext context) {
    int totalSlots = closingHour - openingHour;
    int crossAxisCount = 4; // 4 cột
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 2.1,
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
          isModern: isModern,
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
  final bool isModern;

  const _TimeSlotButton({
    required this.hour,
    required this.isBooked,
    required this.isSelected,
    required this.onTap,
    this.isModern = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    final bool isGoldHour = hour >= 17 && hour < 20;

    if (isBooked) {
      backgroundColor = isModern ? Colors.red[900]!.withValues(alpha: 0.5) : Colors.red[400]!;
      textColor = Colors.white;
      borderColor = isModern ? Colors.red : Colors.red[600]!;
    } else if (isSelected) {
      if (isGoldHour) {
        backgroundColor = isModern ? const Color(0xFFFFB300) : Colors.orange[700]!;
        textColor = isModern ? Colors.black : Colors.white;
        borderColor = isModern ? const Color(0xFFFFD54F) : Colors.orange[800]!;
      } else {
        backgroundColor = isModern ? Colors.white : Colors.amber[600]!;
        textColor = isModern ? Colors.black : Colors.white;
        borderColor = isModern ? Colors.white : Colors.amber[800]!;
      }
    } else {
      if (isGoldHour) {
        backgroundColor = isModern ? const Color(0xFF231709) : Colors.orange.shade50;
        textColor = isModern ? const Color(0xFFFF9100) : Colors.orange.shade900;
        borderColor = isModern ? const Color(0xFFFF9100).withValues(alpha: 0.4) : Colors.orange.shade300;
      } else {
        backgroundColor = isModern ? const Color(0xFF1A1A1A) : Colors.grey[200]!;
        textColor = isModern ? Colors.white70 : Colors.black87;
        borderColor = isModern ? Colors.white12 : Colors.grey[400]!;
      }
    }

    String timeLabel = '${hour.toString().padLeft(2, '0')}:00 - ${(hour + 1).toString().padLeft(2, '0')}:00';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBooked ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isModern ? 0.5 : 1.5),
            boxShadow: (isSelected && !isModern)
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isGoldHour && !isBooked)
                      const Text('🔥 ', style: TextStyle(fontSize: 11)),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontFamily: 'Roboto',
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HorizontalCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool isModern;

  const HorizontalCalendar({
    required this.selectedDate,
    required this.onDateSelected,
    this.isModern = false,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return SizedBox(
      height: 75,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = today.add(Duration(days: index));
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          // Format day of week and day number
          final dayOfWeek = _getDayOfWeekName(date.weekday);
          final dayNumber = date.day.toString();

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 54,
              margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isModern ? Colors.white : Colors.amber.shade700)
                    : (isModern ? const Color(0xFF16181D) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? (isModern ? Colors.white : Colors.amber.shade800)
                      : (isModern ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade300),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected && !isModern
                    ? [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayOfWeek,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? (isModern ? Colors.black : Colors.white)
                          : (isModern ? Colors.white54 : Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNumber,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isSelected
                          ? (isModern ? Colors.black : Colors.white)
                          : (isModern ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getDayOfWeekName(int weekday) {
    switch (weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return '';
    }
  }
}
