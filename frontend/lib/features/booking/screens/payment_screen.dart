import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/booking.dart';
import '../../../services/api_service.dart';
import '../../../services/theme_service.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;

  const PaymentScreen({Key? key, required this.booking}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Timer _timer;
  int _secondsRemaining = 600; // 10 minutes
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _checkStatusPeriodically();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer.cancel();
        _handleTimeout();
      }
    });
  }

  // Tự động kiểm tra trạng thái mỗi 5 giây để cập nhật tức thì khi khách hàng quét xong
  void _checkStatusPeriodically() {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || _secondsRemaining <= 0) {
        timer.cancel();
        return;
      }
      final isPaid = await _checkPaymentStatus(silent: true);
      if (isPaid) {
        timer.cancel();
      }
    });
  }

  void _handleTimeout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thời gian thanh toán đã hết hạn! Lịch đặt của bạn đã bị hủy.'),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.of(context).pop();
  }

  Future<bool> _checkPaymentStatus({bool silent = false}) async {
    if (widget.booking.id == null) return false;
    
    if (!silent) {
      setState(() {
        _isChecking = true;
      });
    }

    try {
      // Gọi API lấy thông tin lịch đặt hiện tại
      final freshBooking = await ApiService.getBookingById(widget.booking.id!);
      
      if (!silent) {
        setState(() {
          _isChecking = false;
        });
      }

      if (freshBooking != null && freshBooking.status == 'APPROVED') {
        if (mounted) {
          await closeInAppWebView();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đặt sân và thanh toán thành công! ⚽'),
              backgroundColor: Colors.green,
            ),
          );
          // Quay lại màn hình chính hoặc lịch sử đặt sân
          Navigator.of(context).pop(true);
        }
        return true;
      } else if (freshBooking != null && freshBooking.status == 'EXPIRED') {
        if (mounted) {
          await closeInAppWebView();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lịch đặt sân đã hết hạn do không nhận được thanh toán!'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop(false);
        }
        return true;
      } else {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hệ thống chưa nhận được thanh toán chuyển khoản.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          _isChecking = false;
        });
      }
      print("Error checking payment status: $e");
    }
    return false;
  }

  Future<void> _launchPaymentUrl() async {
    final urlString = widget.booking.paymentUrl;
    if (urlString == null) return;
    
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.inAppWebView);
    } catch (e) {
      print("Error launching url: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở liên kết thanh toán: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTimer(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = themeProvider.isModernMode;

    final primaryColor = isModern ? Colors.white : Colors.amber.shade700;
    final backgroundColor = isModern ? const Color(0xFF0F1115) : Colors.grey.shade50;
    final cardColor = isModern ? const Color(0xFF16181D) : Colors.white;
    final textColor = isModern ? Colors.white : Colors.black87;
    final subTextColor = isModern ? Colors.white70 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Thanh toán VietQR",
          style: TextStyle(color: isModern ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isModern ? const Color(0xFF16181D) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isModern ? Colors.white : Colors.black87),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hộp thông tin đếm ngược thời gian
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: isModern ? const Color(0xFF1C1E24) : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isModern ? Colors.white.withOpacity(0.08) : Colors.amber.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Thời gian chờ thanh toán còn lại",
                      style: TextStyle(
                        fontSize: 14,
                        color: isModern ? Colors.white70 : Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimer(_secondsRemaining),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: _secondsRemaining < 60 ? Colors.red : (isModern ? Colors.white : Colors.amber.shade800),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Chi tiết thông tin đặt sân
              Card(
                color: cardColor,
                elevation: isModern ? 0 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isModern ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Chi tiết lịch đặt sân",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const Divider(height: 24, thickness: 1),
                      _buildDetailRow("Sân bóng", widget.booking.field.name, textColor, subTextColor),
                      const SizedBox(height: 12),
                      _buildDetailRow("Ngày", "${widget.booking.fromTime.day}/${widget.booking.fromTime.month}/${widget.booking.fromTime.year}", textColor, subTextColor),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        "Thời gian",
                        "${widget.booking.fromTime.hour.toString().padLeft(2, '0')}:00 - ${widget.booking.toTime.hour.toString().padLeft(2, '0')}:00",
                        textColor,
                        subTextColor,
                      ),
                      const Divider(height: 24, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Tổng số tiền đặt cọc",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
                          ),
                          Text(
                            "${widget.booking.totalPrice?.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isModern ? Colors.white : Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Hướng dẫn thanh toán
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hướng dẫn thanh toán:",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    _buildInstructionStep("1", "Nhấn nút 'Tiến hành thanh toán' phía dưới.", subTextColor),
                    const SizedBox(height: 6),
                    _buildInstructionStep("2", "Quét mã VietQR hiển thị hoặc chọn mở ứng dụng ngân hàng trực tiếp để tự động điền số tài khoản, số tiền và nội dung chuyển khoản.", subTextColor),
                    const SizedBox(height: 6),
                    _buildInstructionStep("3", "Sau khi chuyển khoản thành công, hệ thống sẽ tự động xác nhận và duyệt sân ngay lập tức.", subTextColor),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Các nút hành động
              ElevatedButton(
                onPressed: _launchPaymentUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isModern ? Colors.black : Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, color: isModern ? Colors.black : Colors.white),
                    const SizedBox(width: 10),
                    const Text(
                      "Tiến hành thanh toán",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              OutlinedButton(
                onPressed: _isChecking ? null : () => _checkPaymentStatus(silent: false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isModern ? Colors.white : Colors.amber.shade800,
                  side: BorderSide(color: isModern ? Colors.white24 : Colors.amber.shade700),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        "Tôi đã chuyển khoản thành công",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  "Quay lại (Thanh toán sau)",
                  style: TextStyle(color: isModern ? Colors.white54 : Colors.grey.shade600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: valueColor)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String text, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: textColor),
          ),
        ),
      ],
    );
  }
}
