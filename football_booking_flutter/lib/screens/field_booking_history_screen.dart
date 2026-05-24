import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/field.dart';
import '../services/api_service.dart';

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
      // Sắp xếp danh sách booking theo từ booking.fromTime (mới nhất trước)
      fetched.sort((a, b) {
        if (a.fromTime == null && b.fromTime == null) return 0;
        if (a.fromTime == null) return 1;
        if (b.fromTime == null) return -1;
        return b.fromTime.compareTo(a.fromTime);
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

  Widget buildBookingItem(Booking booking) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2 dòng đầu: ngày và giờ
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.calendar_today, color: Colors.amber),
                const SizedBox(width: 8),
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
                        style: TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Dòng 2: Giờ với icon đồng hồ
                      Row(
                        children: [
                          Text(
                            (booking.fromTime != null && booking.toTime != null)
                                ? 'Giờ đặt: ${booking.fromTime.hour.toString().padLeft(2, '0')}:${booking.fromTime.minute.toString().padLeft(2, '0')} - ${booking.toTime.hour.toString().padLeft(2, '0')}:${booking.toTime.minute.toString().padLeft(2, '0')}'
                                : '',
                            style: TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Nếu có ghi chú thì hiển thị bên dưới
            if (booking.additional != null && booking.additional!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Ghi chú: ${booking.additional!}', style: TextStyle(color: Colors.black54, fontSize: 13)),
              ),
            // Thông tin khách hàng đặt (nếu có)
            if (booking.customerName != null && booking.customerName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text('Người đặt: ${booking.customerName!}', style: TextStyle(fontSize: 13, color: Colors.blueGrey[700])),
                    if (booking.customerPhone != null && booking.customerPhone!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.phone, size: 16, color: Colors.green),
                      const SizedBox(width: 2),
                      Text(booking.customerPhone!, style: TextStyle(fontSize: 13, color: Colors.green[700])),
                    ]
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(field != null ? 'Lịch sử đặt: ${field!.name}' : 'Lịch sử đặt sân'),
        backgroundColor: Colors.amberAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMsg != null
          ? Center(child: Text(errorMsg!))
          : bookings.isEmpty
          ? Center(child: Text('Chưa có lịch sử đặt sân này.'))
          : RefreshIndicator(
        onRefresh: fetchBookings,
        child: ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) => buildBookingItem(bookings[index]),
        ),
      ),
    );
  }
}
