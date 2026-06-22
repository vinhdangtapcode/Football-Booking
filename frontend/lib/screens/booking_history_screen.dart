import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/booking.dart';
import '../models/field.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  @override
  _BookingHistoryScreenState createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List<Booking> bookings = [];
  bool isLoading = false;
  String? errorMsg;
  int _currentIndex = 1; // BookingHistory có index 1 trong Bottom Navigation
  Field? selectedField;

  @override
  void initState() {
    super.initState();
    fetchBookingHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> fetchBookingHistory() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      List<Booking> fetchedBookings = await ApiService.getBookingHistory();

      // Sắp xếp danh sách booking theo fromTime, booking mới nhất sẽ đứng đầu (sắp xếp giảm dần)
      fetchedBookings.sort((a, b) {
        if (a.fromTime == null && b.fromTime == null) return 0;
        if (a.fromTime == null) return 1;
        if (b.fromTime == null) return -1;
        return b.fromTime.compareTo(a.fromTime);
      });

      setState(() {
        bookings = fetchedBookings;
        isLoading = false;
      });
    } catch (error) {
      print("Error when fetching booking history: $error");
      setState(() {
        isLoading = false;
        errorMsg = "Failed to load booking history.";
      });
    }
  }

  // Mỗi thẻ sân gồm hình ảnh bên trái và thông tin bên phải (tên sân, ngày đặt, giờ đặt)
  Widget buildBookingItem(Booking booking, bool isModern) {
    return Card(
      color: isModern ? Color(0xFF121212) : null,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isModern ? BorderSide(color: Colors.white24) : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: InkWell(
        onTap: () => _showBookingDetailDialog(context, booking, isModern),
        child: SizedBox(
          height: 120,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: booking.field.imageUrl?.isEmpty ?? true
                    ? Image.asset(
                  'lib/assets/images/san_bong.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                )
                    : CachedNetworkImage(
                  imageUrl: booking.field.imageUrl!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox(
                    width: 120,
                    height: 120,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Image.asset(
                    'lib/assets/images/san_bong.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (booking.fieldName != null &&
                            booking.fieldName!.isNotEmpty)
                        ? booking.fieldName!
                        : (booking.field.name.isNotEmpty
                            ? booking.field.name
                            : '(Không có tên sân)'),
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isModern ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Dòng 1: Ngày đặt
                      Text(
                        booking.fromTime != null
                        ? 'Ngày đặt: ${booking.fromTime.day}/${booking.fromTime.month}/${booking.fromTime.year}'
                        : '',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: isModern ? Colors.white70 : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Dòng 2: Giờ đặt với icon đồng hồ
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 16, color: isModern ? Colors.white54 : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            (booking.fromTime != null && booking.toTime != null)
                            ? '${booking.fromTime.hour.toString().padLeft(2, '0')}:${booking.fromTime.minute.toString().padLeft(2, '0')} - ${booking.toTime.hour.toString().padLeft(2, '0')}:${booking.toTime.minute.toString().padLeft(2, '0')}'
                            : '',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: isModern ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isModern ? Colors.white24 : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 12),
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
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(selectedField != null
            ? "Lịch sử đặt sân: ${selectedField!.name}"
            : "Lịch sử đặt sân", style: TextStyle(color: isModern ? Colors.white : null)),
        backgroundColor: isModern ? Colors.black : Colors.amberAccent,
        foregroundColor: isModern ? Colors.white : null,
        elevation: 0,
        bottom: isModern ? PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(color: Colors.white12, height: 1),
        ) : null,
      ),
      body: RefreshIndicator(
        onRefresh: fetchBookingHistory,
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber))
            : errorMsg != null
            ? ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Center(child: Text(errorMsg!, style: TextStyle(color: isModern ? Colors.white : null))),
            ),
          ],
        )
            : bookings.isEmpty
            ? ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Center(
                  child: Text("Chưa có lịch sử đặt sân.", style: TextStyle(color: isModern ? Colors.white54 : null))),
            ),
          ],
        )
            : ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return buildBookingItem(bookings[index], isModern);
          },
        ),
      ),
      bottomNavigationBar: null,
    );
  }

  void _showBookingDetailDialog(BuildContext context, Booking booking, bool isModern) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // Tính toán số tiền đã thanh toán
    final durationInMinutes = booking.toTime.difference(booking.fromTime).inMinutes;
    final durationInHours = durationInMinutes / 60.0;
    final totalPrice = durationInHours * booking.field.pricePerHour;

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
                      
                      // Hình ảnh sân bóng (nếu có)
                      if (booking.field.imageUrl?.isNotEmpty ?? false) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: booking.field.imageUrl!,
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const SizedBox(
                              height: 140,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Thông tin sân
                      Text(
                        (booking.fieldName != null && booking.fieldName!.isNotEmpty)
                        ? booking.fieldName!
                        : booking.field.name,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isModern ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, size: 14, color: isModern ? Colors.white54 : Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              booking.field.address ?? '',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 13,
                                color: isModern ? Colors.white70 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Chi tiết thời gian và giá
                      _buildPopupRow(
                        icon: Icons.calendar_today,
                        label: 'Ngày đặt',
                        value: booking.fromTime != null
                        ? '${booking.fromTime.day}/${booking.fromTime.month}/${booking.fromTime.year}'
                        : '-',
                        isModern: isModern,
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 10),
                      _buildPopupRow(
                        icon: Icons.access_time,
                        label: 'Khung giờ',
                        value: '${booking.fromTime.hour.toString().padLeft(2, '0')}:${booking.fromTime.minute.toString().padLeft(2, '0')} - ${booking.toTime.hour.toString().padLeft(2, '0')}:${booking.toTime.minute.toString().padLeft(2, '0')}',
                        isModern: isModern,
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 10),
                      _buildPopupRow(
                        icon: Icons.person_outline,
                        label: 'Người đặt',
                        value: booking.customerName ?? booking.customer?.name ?? '-',
                        isModern: isModern,
                        themeProvider: themeProvider,
                      ),
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
                            'Số tiền đã thanh toán',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isModern ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${totalPrice.toInt()} VNĐ',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isModern ? themeProvider.accentColor : Colors.green.shade700,
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
        Icon(icon, size: 16, color: isModern ? themeProvider.accentColor : Colors.amber.shade700),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isModern ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isModern ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
