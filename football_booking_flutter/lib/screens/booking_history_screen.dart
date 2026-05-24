import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/field.dart';
import '../services/api_service.dart';

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
    // Không lọc theo field nữa, chỉ lấy toàn bộ lịch sử đặt sân của user
    // final args = ModalRoute.of(context)?.settings.arguments;
    // if (args is Field) {
    //   selectedField = args;
    // }
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
  Widget buildBookingItem(Booking booking) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: InkWell(
        onTap: () {
          // Điều hướng đến chi tiết booking nếu cần
        },
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
                    : Image.network(
                  booking.field.imageUrl!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'lib/assets/images/san_bong.png',
                      fit: BoxFit.cover,
                    );
                  },
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
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Dòng 1: Ngày đặt
                      Text(
                        booking.fromTime != null
                            ? 'Ngày đặt: ${booking.fromTime.day}/${booking.fromTime.month}/${booking.fromTime.year}'
                            : '',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Dòng 2: Giờ đặt với icon đồng hồ
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            (booking.fromTime != null && booking.toTime != null)
                                ? '${booking.fromTime.hour.toString().padLeft(2, '0')}:${booking.fromTime.minute.toString().padLeft(2, '0')} - ${booking.toTime.hour.toString().padLeft(2, '0')}:${booking.toTime.minute.toString().padLeft(2, '0')}'
                                : '',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(selectedField != null
            ? "Lịch sử đặt sân: ${selectedField!.name}"
            : "Lịch sử đặt sân"),
        backgroundColor: Colors.amberAccent,
      ),
      body: RefreshIndicator(
        onRefresh: fetchBookingHistory,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMsg != null
            ? ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Center(child: Text(errorMsg!)),
            ),
          ],
        )
            : bookings.isEmpty
            ? ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: const Center(
                  child: Text("Chưa có lịch sử đặt sân.")),
            ),
          ],
        )
            : ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return buildBookingItem(bookings[index]);
          },
        ),
      ),
      bottomNavigationBar: null,
    );
  }
}
