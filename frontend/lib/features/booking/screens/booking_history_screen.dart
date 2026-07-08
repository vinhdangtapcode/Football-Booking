import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../../models/booking.dart';
import '../../../models/field.dart';
import '../../../services/theme_service.dart';
import '../providers/booking_provider.dart';

class BookingHistoryScreen extends StatefulWidget {
  @override
  _BookingHistoryScreenState createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  bool isLoading = false;
  String? errorMsg;
  int _currentIndex = 1; // BookingHistory có index 1 trong Bottom Navigation
  Field? selectedField;
  String selectedStatusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadBookingHistory();
    });
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
      await context.read<BookingProvider>().loadBookingHistory();
      setState(() {
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

  Widget _buildFilterRow(bool isModern) {
    final filters = [
      {'key': 'ALL', 'label': 'Tất cả'},
      {'key': 'PENDING_PAYMENT', 'label': 'Chờ TT'},
      {'key': 'APPROVED', 'label': 'Thành công'},
      {'key': 'CANCELLED', 'label': 'Đã hủy'},
      {'key': 'EXPIRED', 'label': 'Hết hạn'},
    ];

    final Color activeBgColor = isModern ? Colors.white : Colors.amber;
    final Color activeTextColor = isModern ? Colors.black : Colors.white;
    final Color inactiveBgColor = isModern ? const Color(0xFF1E1E1E) : Colors.grey[200]!;
    final Color inactiveTextColor = isModern ? Colors.white70 : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: filters.map((filter) {
          final isSelected = selectedStatusFilter == filter['key'];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedStatusFilter = filter['key']!;
                  });
                },
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? activeBgColor : inactiveBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? (isModern ? Colors.white : Colors.amber)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    filter['label']!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? activeTextColor : inactiveTextColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildStatusBadge(booking.status, isModern),
                        ],
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
    final bookingProvider = context.watch<BookingProvider>();

    final filteredBookings = bookingProvider.bookings.where((b) {
      if (selectedStatusFilter == 'ALL') return true;
      if (selectedStatusFilter == 'APPROVED') return b.status == 'APPROVED';
      if (selectedStatusFilter == 'PENDING_PAYMENT') return b.status == 'PENDING_PAYMENT';
      if (selectedStatusFilter == 'CANCELLED') return b.status == 'CANCELLED';
      if (selectedStatusFilter == 'EXPIRED') return b.status == 'EXPIRED';
      return true;
    }).toList();

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
      body: Column(
        children: [
          _buildFilterRow(isModern),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchBookingHistory,
              child: bookingProvider.isLoading || isLoading
                  ? Center(child: CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber))
                  : errorMsg != null
                  ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(child: Text(errorMsg!, style: TextStyle(color: isModern ? Colors.white : null))),
                  ),
                ],
              )
                  : filteredBookings.isEmpty
                  ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                        child: Text(selectedStatusFilter == 'ALL'
                            ? "Chưa có lịch sử đặt sân."
                            : "Không có lịch đặt nào phù hợp.",
                            style: TextStyle(color: isModern ? Colors.white54 : null))),
                  ),
                ],
              )
                  : ListView.builder(
                itemCount: filteredBookings.length,
                itemBuilder: (context, index) {
                  return buildBookingItem(filteredBookings[index], isModern);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }

  void _confirmCancelBooking(BuildContext parentContext, Booking booking) {
    final isApproved = booking.status == 'APPROVED';
    final depositAmount = (booking.totalPrice ?? 0).toInt();

    showDialog(
      context: parentContext,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text("Xác nhận hủy đặt sân", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            isApproved
                ? "Bạn có chắc chắn muốn hủy lịch đặt sân này?\n\n⚠️ LƯU Ý: Số tiền đặt cọc ($depositAmount VNĐ) đã thanh toán qua QR sẽ KHÔNG được hoàn trả theo chính sách của hệ thống."
                : "Bạn có chắc chắn muốn hủy lịch đặt sân này?\n\nLịch đặt chưa thanh toán này sẽ bị hủy ngay lập tức.",
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy bỏ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Đóng alert dialog
                Navigator.pop(parentContext); // Đóng booking detail dialog
                
                // Show loading indicator
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Row(
                    children: [
                      const CircularProgressIndicator(strokeWidth: 2),
                      const SizedBox(width: 15),
                      const Text("Đang xử lý hủy sân..."),
                    ],
                  )),
                );

                final success = await context.read<BookingProvider>().cancelBooking(booking.id!);
                ScaffoldMessenger.of(parentContext).hideCurrentSnackBar();

                if (success) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text("Hủy đặt sân thành công! Khung giờ đã được giải phóng."),
                      backgroundColor: Colors.green,
                    ),
                  );
                  fetchBookingHistory(); // Reload history list
                } else {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text("Hủy đặt sân thất bại. Vui lòng thử lại."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Xác nhận hủy", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
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
                      const SizedBox(height: 10),
                      _buildPopupRow(
                        icon: Icons.info_outline,
                        label: 'Trạng thái',
                        value: _getStatusName(booking.status),
                        isModern: isModern,
                        themeProvider: themeProvider,
                      ),
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
                      if (booking.status == 'PENDING_PAYMENT' && booking.paymentUrl != null) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context); // Đóng dialog
                              final isSuccess = await Navigator.pushNamed(
                                context,
                                '/payment',
                                arguments: booking,
                              );
                              if (isSuccess == true) {
                                fetchBookingHistory(); // Reload history
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isModern ? Colors.white : Colors.amber,
                              foregroundColor: isModern ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payment, size: 20, color: isModern ? Colors.black : Colors.white),
                                const SizedBox(width: 8),
                                const Text(
                                  'Thanh toán ngay',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (booking.status == 'PENDING_PAYMENT' || booking.status == 'APPROVED') ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => _confirmCancelBooking(context, booking),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cancel_outlined, size: 20, color: Colors.red),
                                const SizedBox(width: 8),
                                const Text(
                                  'Hủy đặt sân',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
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
