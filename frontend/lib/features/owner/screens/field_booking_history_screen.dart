import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../../models/booking.dart';
import '../../../models/field.dart';
import '../../../services/api_service.dart';
import '../../../services/theme_service.dart';

class FieldBookingHistoryScreen extends StatefulWidget {
  @override
  _FieldBookingHistoryScreenState createState() => _FieldBookingHistoryScreenState();
}

class _FieldBookingHistoryScreenState extends State<FieldBookingHistoryScreen> {
  List<Booking> bookings = [];
  bool isLoading = false;
  String? errorMsg;
  Field? field;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Field) {
      field = args;
      fetchBookings();
    }
  }

  Future<void> fetchBookings() async {
    if (field == null) return;
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      List<Booking> fetched = await ApiService.getBookingsForField(field!.id!);
      // Sắp xếp danh sách booking theo từ booking.fromTime (mới nhất trước), nếu trùng giờ thì theo ID giảm dần
      fetched.sort((a, b) {
        if (a.fromTime == null && b.fromTime == null) return 0;
        if (a.fromTime == null) return 1;
        if (b.fromTime == null) return -1;
        
        final timeCompare = b.fromTime.compareTo(a.fromTime);
        if (timeCompare != 0) {
          return timeCompare;
        }
        
        // Nếu trùng giờ đặt, lịch đặt nào tạo sau (ID lớn hơn) sẽ hiển thị ở trên
        if (a.id != null && b.id != null) {
          return b.id!.compareTo(a.id!);
        }
        return 0;
      });
      setState(() {
        bookings = fetched;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMsg = 'Không thể tải lịch sử đặt sân.';
      });
    }
  }

  Widget _buildStatusBadge(String? status, bool isModern) {
    String text = "Chờ thanh toán";
    Color bgColor = isModern ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50;
    Color textColor = isModern ? Colors.orange : Colors.orange.shade800;

    if (status == 'APPROVED') {
      text = "Thành công";
      bgColor = isModern ? Colors.green.withOpacity(0.15) : Colors.green.shade50;
      textColor = isModern ? Colors.green : Colors.green.shade800;
    } else if (status == 'CANCELLED') {
      text = "Đã hủy";
      bgColor = isModern ? Colors.red.withOpacity(0.15) : Colors.red.shade50;
      textColor = isModern ? Colors.red : Colors.red.shade800;
    } else if (status == 'EXPIRED') {
      text = "Hết hạn";
      bgColor = isModern ? Colors.grey.withOpacity(0.15) : Colors.grey.shade100;
      textColor = isModern ? Colors.grey : Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _getStatusName(String? status) {
    if (status == 'APPROVED') return 'Thành công';
    if (status == 'CANCELLED') return 'Đã hủy';
    if (status == 'EXPIRED') return 'Đã hết hạn';
    return 'Chờ thanh toán';
  }

  Widget _buildPopupRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isModern,
    required ThemeProvider themeProvider,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isModern ? themeProvider.accentColor : Colors.grey.shade600,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: isModern ? Colors.white38 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isModern ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBookingDetailDialog(BuildContext context, Booking booking, bool isModern) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // Tính toán số tiền đã thanh toán
    final durationInMinutes = booking.toTime.difference(booking.fromTime).inMinutes;
    final durationInHours = durationInMinutes / 60.0;
    final totalPrice = durationInHours * booking.field.pricePerHour;

    final depositPaid = (booking.status == 'APPROVED' || booking.status == 'CANCELLED')
        ? (booking.totalPrice ?? 0.0)
        : 0.0;
    final remainingPayment = (booking.status == 'CANCELLED' || booking.status == 'EXPIRED')
        ? 0.0
        : (totalPrice - (booking.totalPrice ?? 0.0));

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isModern ? const Color(0xE616181D) : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isModern ? Colors.white12 : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header với icon hoặc logo
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isModern ? Colors.white10 : Colors.amber.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long,
                              color: isModern ? themeProvider.accentColor : Colors.amber.shade800,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chi tiết đặt sân',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isModern ? Colors.white : Colors.black87,
                                  ),
                                ),
                                if (booking.id != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Mã đặt sân: #${booking.id}',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 12,
                                      color: isModern ? Colors.white54 : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: isModern ? Colors.white54 : Colors.grey),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),
                      
                      // Chi tiết thông tin
                      _buildPopupRow(
                        icon: Icons.sports_soccer,
                        label: 'Sân bóng',
                        value: booking.field.name,
                        isModern: isModern,
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 10),
                      _buildPopupRow(
                        icon: Icons.calendar_today,
                        label: 'Ngày đá',
                        value: '${booking.fromTime.day}/${booking.fromTime.month}/${booking.fromTime.year}',
                        isModern: isModern,
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 10),
                      _buildPopupRow(
                        icon: Icons.access_time,
                        label: 'Giờ đá',
                        value: '${booking.fromTime.hour.toString().padLeft(2, '0')}:${booking.fromTime.minute.toString().padLeft(2, '0')} - ${booking.toTime.hour.toString().padLeft(2, '0')}:${booking.toTime.minute.toString().padLeft(2, '0')}',
                        isModern: isModern,
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 10),
                      _buildPopupRow(
                        icon: Icons.info_outline,
                        label: 'Trạng thái',
                        value: _getStatusName(booking.status),
                        isModern: isModern,
                        themeProvider: themeProvider,
                      ),
                      
                      // Thông tin khách hàng
                      if (booking.customerName != null && booking.customerName!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildPopupRow(
                          icon: Icons.person_outline,
                          label: 'Khách hàng',
                          value: booking.customerName!,
                          isModern: isModern,
                          themeProvider: themeProvider,
                        ),
                      ],
                      if (booking.customerPhone != null && booking.customerPhone!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildPopupRow(
                          icon: Icons.phone_android,
                          label: 'Số điện thoại',
                          value: booking.customerPhone!,
                          isModern: isModern,
                          themeProvider: themeProvider,
                        ),
                      ],
                      if (booking.additional != null && booking.additional!.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildPopupRow(
                          icon: Icons.notes,
                          label: 'Ghi chú thêm',
                          value: booking.additional!,
                          isModern: isModern,
                          themeProvider: themeProvider,
                        ),
                      ],
                      const Divider(height: 24, thickness: 1),
                      
                      // Chi tiết thanh toán
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Giá thuê sân',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: isModern ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${booking.field.pricePerHour.toInt()} VNĐ/giờ',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isModern ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Thời gian thuê',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: isModern ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${durationInHours.toStringAsFixed(1).replaceAll('.0', '')} giờ',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isModern ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng tiền sân',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: isModern ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${totalPrice.toInt()} VNĐ',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isModern ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tiền cọc đã thanh toán',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isModern ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${depositPaid.toInt()} VNĐ',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isModern ? themeProvider.accentColor : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Còn lại (Thanh toán tại sân)',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isModern ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${remainingPayment.toInt()} VNĐ',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isModern ? Colors.orange : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Nút đóng
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isModern ? Colors.white : Colors.amber,
                            foregroundColor: isModern ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Đóng',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
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
          ),
        );
      },
    );
  }

  Widget buildBookingItem(Booking booking, bool isModern) {
    return Card(
      color: isModern ? const Color(0xFF121212) : null,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isModern ? const BorderSide(color: Colors.white24) : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: InkWell(
        onTap: () => _showBookingDetailDialog(context, booking, isModern),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2 dòng đầu: ngày và giờ
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.calendar_today, color: isModern ? Colors.white70 : Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dòng 1: Ngày
                        Text(
                          booking.fromTime != null
                              ? 'Ngày đặt: ${booking.fromTime.day}/${booking.fromTime.month}/${booking.fromTime.year}'
                              : '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isModern ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Dòng 2: Giờ với icon đồng hồ
                        Text(
                          (booking.fromTime != null && booking.toTime != null)
                              ? 'Giờ đặt: ${booking.fromTime.hour.toString().padLeft(2, '0')}:${booking.fromTime.minute.toString().padLeft(2, '0')} - ${booking.toTime.hour.toString().padLeft(2, '0')}:${booking.toTime.minute.toString().padLeft(2, '0')}'
                              : '',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isModern ? Colors.white70 : Colors.black54,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(booking.status, isModern),
                ],
              ),
              // Ghi chú (nếu có)
              if (booking.additional != null && booking.additional!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 30.0),
                  child: Text(
                    'Ghi chú: ${booking.additional!}',
                    style: TextStyle(color: isModern ? Colors.white54 : Colors.black54, fontSize: 13),
                  ),
                ),
              // Thông tin khách hàng đặt (nếu có)
              if (booking.customerName != null && booking.customerName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 30.0),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 16, color: isModern ? Colors.white54 : Colors.blueGrey),
                      const SizedBox(width: 6),
                      Text(
                        'Người đặt: ${booking.customerName!}',
                        style: TextStyle(fontSize: 13, color: isModern ? Colors.white70 : Colors.blueGrey[700]),
                      ),
                      if (booking.customerPhone != null && booking.customerPhone!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.phone, size: 16, color: isModern ? Colors.greenAccent : Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          booking.customerPhone!,
                          style: TextStyle(fontSize: 13, color: isModern ? Colors.greenAccent : Colors.green[700]),
                        ),
                      ]
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = themeProvider.isModernMode;

    return Scaffold(
      backgroundColor: isModern ? Colors.black : null,
      appBar: AppBar(
        title: Text(
          field != null ? 'Lịch sử đặt: ${field!.name}' : 'Lịch sử đặt sân',
          style: TextStyle(color: isModern ? Colors.white : null),
        ),
        backgroundColor: isModern ? Colors.black : Colors.amberAccent,
        foregroundColor: isModern ? Colors.white : null,
        elevation: 0,
        bottom: isModern ? PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white12, height: 1),
        ) : null,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber))
          : errorMsg != null
          ? Center(child: Text(errorMsg!, style: TextStyle(color: isModern ? Colors.white : null)))
          : bookings.isEmpty
          ? Center(child: Text('Chưa có lịch sử đặt sân này.', style: TextStyle(color: isModern ? Colors.white54 : null)))
          : RefreshIndicator(
              onRefresh: fetchBookings,
              color: isModern ? Colors.white : Colors.amber,
              child: ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) => buildBookingItem(bookings[index], isModern),
              ),
            ),
    );
  }
}
