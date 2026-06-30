import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../services/theme_service.dart';

class OwnerRevenueScreen extends StatefulWidget {
  const OwnerRevenueScreen({Key? key}) : super(key: key);

  @override
  State<OwnerRevenueScreen> createState() => _OwnerRevenueScreenState();
}

class _OwnerRevenueScreenState extends State<OwnerRevenueScreen> {
  double totalPlatformHeld = 0.0;
  List<dynamic> bookings = [];
  List<dynamic> settlements = [];
  bool isLoading = true;
  String? errorMsg;
  String _sortBy = 'orderTime'; // 'playTime' or 'orderTime'
  int _subTab = 0; // 0: Lịch đặt cọc, 1: Sao kê đối soát
  String bankName = '';
  String bankAccountNo = '';
  String bankAccountName = '';

  @override
  void initState() {
    super.initState();
    _fetchRevenue();
  }

  void _sortBookings() {
    bookings.sort((a, b) {
      if (_sortBy == 'playTime') {
        final aTime = a['fromTime'] != null ? DateTime.parse(a['fromTime']) : DateTime.now();
        final bTime = b['fromTime'] != null ? DateTime.parse(b['fromTime']) : DateTime.now();
        return bTime.compareTo(aTime);
      } else {
        final aTime = a['createdAt'] != null ? DateTime.parse(a['createdAt']) : DateTime.now();
        final bTime = b['createdAt'] != null ? DateTime.parse(b['createdAt']) : DateTime.now();
        return bTime.compareTo(aTime);
      }
    });
  }

  Future<void> _fetchRevenue() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    try {
      final data = await ApiService.getOwnerRevenue();
      setState(() {
        totalPlatformHeld = (data['totalPlatformHeld'] as num?)?.toDouble() ?? 0.0;
        bookings = data['bookings'] ?? [];
        settlements = data['settlements'] ?? [];
        bankName = data['bankName'] ?? '';
        bankAccountNo = data['bankAccountNo'] ?? '';
        bankAccountName = data['bankAccountName'] ?? '';
        _sortBookings();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMsg = "Không thể tải thông tin doanh thu.";
      });
    }
  }

  String _formatMoney(double amount) {
    return amount.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    ) + 'đ';
  }

  Future<void> _showBankConfigDialog() async {
    final nameController = TextEditingController(text: bankName);
    final noController = TextEditingController(text: bankAccountNo);
    final ownerController = TextEditingController(text: bankAccountName);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cấu hình tài khoản nhận tiền'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên ngân hàng (ví dụ: Vietcombank, MB...)',
                  hintText: 'Nhập tên ngân hàng',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noController,
                decoration: const InputDecoration(
                  labelText: 'Số tài khoản nhận tiền',
                  hintText: 'Nhập số tài khoản',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ownerController,
                decoration: const InputDecoration(
                  labelText: 'Tên chủ tài khoản (Viết hoa không dấu)',
                  hintText: 'Nhập tên chủ tài khoản',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => isLoading = true);
      try {
        final success = await ApiService.updateOwnerBankDetails(
          nameController.text.trim(),
          noController.text.trim(),
          ownerController.text.trim().toUpperCase(),
        );
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật tài khoản nhận tiền thành công!'), backgroundColor: Colors.green),
          );
          await _fetchRevenue();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thất bại!'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildBankInfoRow(String label, String value, bool isModern) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isModern ? Colors.white54 : Colors.grey.shade600, fontSize: 13)),
          Text(value, style: TextStyle(color: isModern ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = themeProvider.isModernMode;

    return Scaffold(
      backgroundColor: isModern ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Ví tiền & Doanh thu cọc",
          style: TextStyle(color: isModern ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isModern ? Colors.black : Colors.amberAccent,
        foregroundColor: isModern ? Colors.white : Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isModern ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRevenue,
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber))
            : errorMsg != null
                ? Center(child: Text(errorMsg!, style: TextStyle(color: isModern ? Colors.white : Colors.black)))
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Glassmorphic Wallet Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isModern
                                  ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
                                  : [Colors.amber.shade700, Colors.amber.shade900],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: (isModern ? Colors.blue.shade900 : Colors.amber.shade900)
                                    .withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Số dư giữ hộ trung gian",
                                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                  Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.8), size: 28),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _formatMoney(totalPlatformHeld),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.white, size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Tiền cọc được chuyển thẳng về hệ thống để giữ bảo đảm. Hệ thống sẽ định kỳ đối soát và chuyển lại cho chủ sân mỗi tuần.",
                                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                          const SizedBox(height: 24),
                          // Sub-tab toggler
                          Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: isModern ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: isModern ? Border.all(color: Colors.white10) : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _subTab = 0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _subTab == 0
                                            ? (isModern ? Colors.white12 : Colors.amber.shade700)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "Lịch đặt cọc",
                                        style: TextStyle(
                                          color: _subTab == 0
                                              ? Colors.white
                                              : (isModern ? Colors.white70 : Colors.black87),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _subTab = 1),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _subTab == 1
                                            ? (isModern ? Colors.white12 : Colors.amber.shade700)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "Sao kê đối soát",
                                        style: TextStyle(
                                          color: _subTab == 1
                                              ? Colors.white
                                              : (isModern ? Colors.white70 : Colors.black87),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_subTab == 0) ...[
                            Builder(
                              builder: (context) {
                                final depositBookingsList = bookings.where((b) {
                                  final double deposit = (b['totalPrice'] as num?)?.toDouble() ?? 0.0;
                                  return deposit > 0;
                                }).toList();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Lịch sử nhận cọc (${depositBookingsList.length})",
                                              style: TextStyle(
                                                color: isModern ? Colors.white : Colors.black87,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Sắp xếp: ${_sortBy == 'playTime' ? 'Giờ đá mới nhất' : 'Giờ đặt mới nhất'}",
                                              style: TextStyle(
                                                color: isModern ? Colors.white38 : Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.sort,
                                            color: isModern ? Colors.white70 : Colors.amber.shade800,
                                          ),
                                          tooltip: "Sắp xếp",
                                          onSelected: (value) {
                                            setState(() {
                                              _sortBy = value;
                                              _sortBookings();
                                            });
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'playTime',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.sports_soccer,
                                                    color: _sortBy == 'playTime'
                                                        ? (isModern ? Colors.white : Colors.amber)
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text("Theo giờ đá"),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'orderTime',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_month,
                                                    color: _sortBy == 'orderTime'
                                                        ? (isModern ? Colors.white : Colors.amber)
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text("Theo giờ đặt"),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    depositBookingsList.isEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 40),
                                            child: Center(
                                              child: Text(
                                                "Chưa có giao dịch đặt lịch nào.",
                                                style: TextStyle(color: isModern ? Colors.white54 : Colors.grey),
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: depositBookingsList.length,
                                            itemBuilder: (context, index) {
                                              final booking = depositBookingsList[index];
                                              final fieldName = booking['field']?['name'] ?? 'Sân bóng';
                                              final customerName = booking['customerName'] ?? booking['customer']?['name'] ?? 'Khách ẩn';
                                              final phone = booking['customerPhone'] ?? booking['customer']?['phone'] ?? '';
                                              final status = booking['status'] ?? 'PENDING_PAYMENT';
                                              final double bookingTotalPrice = (booking['totalPrice'] as num?)?.toDouble() ?? 0.0;
                                              final double deposit = (status == 'APPROVED' || (status == 'CANCELLED' && bookingTotalPrice > 0))
                                                  ? bookingTotalPrice
                                                  : 0.0;

                                              final double pricePerHour = (booking['field']?['pricePerHour'] as num?)?.toDouble() ?? 0.0;
                                              DateTime? fromTime = booking['fromTime'] != null ? DateTime.parse(booking['fromTime']) : null;
                                              DateTime? toTime = booking['toTime'] != null ? DateTime.parse(booking['toTime']) : null;
                                              double hours = 0.0;
                                              if (fromTime != null && toTime != null) {
                                                hours = toTime.difference(fromTime).inMinutes / 60.0;
                                              }
                                              final double fullPrice = hours * pricePerHour;
                                                                              final double remaining = fullPrice - deposit;
                                              DateTime? createdAt = booking['createdAt'] != null ? DateTime.parse(booking['createdAt']).toLocal() : null;

                                              // Giao diện màu trạng thái
                                              Color statusColor = Colors.orange;
                                              String statusText = "Chờ cọc";
                                              if (status == 'APPROVED') {
                                                statusColor = Colors.green;
                                                statusText = "Đã cọc thành công";
                                              } else if (status == 'CANCELLED') {
                                                statusColor = Colors.red;
                                                statusText = deposit > 0 ? "Hủy (Giữ cọc)" : "Đã hủy";
                                              } else if (status == 'EXPIRED') {
                                                statusColor = Colors.grey;
                                                statusText = "Hết hạn";
                                              }

                                              return Card(
                                                color: isModern ? const Color(0xFF1E1E1E) : Colors.white,
                                                margin: const EdgeInsets.only(bottom: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  side: isModern ? const BorderSide(color: Colors.white10) : BorderSide.none,
                                                ),
                                                elevation: 2,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(16),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              fieldName,
                                                              style: TextStyle(
                                                                color: isModern ? Colors.white : Colors.black87,
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: statusColor.withOpacity(0.15),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              statusText,
                                                              style: TextStyle(
                                                                color: statusColor,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 12),
                                                      _buildDetailRow("Khách đặt sân:", customerName, isModern),
                                                      if (phone.isNotEmpty)
                                                        _buildDetailRow("Số điện thoại:", phone, isModern),
                                                      if (fromTime != null && toTime != null)
                                                        _buildDetailRow(
                                                          "Thời gian đá:",
                                                          "${fromTime.hour}:00 - ${toTime.hour}:00 ngày ${fromTime.day}/${fromTime.month}/${fromTime.year}",
                                                          isModern,
                                                        ),
                                                      if (createdAt != null)
                                                        _buildDetailRow(
                                                          "Thời gian đặt:",
                                                          "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')} ngày ${createdAt.day}/${createdAt.month}/${createdAt.year}",
                                                          isModern,
                                                        ),
                                                      const Divider(height: 24, color: Colors.white10),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            "Tiền cọc đã nhận:",
                                                            style: TextStyle(color: isModern ? Colors.white70 : Colors.black54, fontSize: 13),
                                                          ),
                                                          Text(
                                                            _formatMoney(deposit),
                                                            style: const TextStyle(
                                                              color: Colors.green,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 15,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            "Thanh toán offline tại sân:",
                                                            style: TextStyle(color: isModern ? Colors.white70 : Colors.black54, fontSize: 13),
                                                          ),
                                                          Text(
                                                            _formatMoney(remaining > 0 ? remaining : 0.0),
                                                            style: TextStyle(
                                                              color: isModern ? Colors.white : Colors.black87,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ],
                                );
                              }
                            ),
                          ],
                          if (_subTab == 1) ...[
                            Card(
                              color: isModern ? const Color(0xFF1E1E1E) : Colors.amber.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isModern ? Colors.white10 : Colors.amber.shade200,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Tài khoản nhận tiền đối soát",
                                          style: TextStyle(
                                            color: isModern ? Colors.white : Colors.amber.shade900,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: isModern ? Colors.amber : Colors.amber.shade800,
                                            size: 20,
                                          ),
                                          onPressed: _showBankConfigDialog,
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 12, color: Colors.black12),
                                    bankAccountNo.isEmpty
                                        ? Row(
                                            children: [
                                              const Icon(Icons.warning, color: Colors.orange, size: 16),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  "Chưa cấu hình tài khoản nhận tiền. Bấm nút bút chì để thiết lập.",
                                                  style: TextStyle(
                                                    color: isModern ? Colors.white70 : Colors.black87,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            children: [
                                              _buildBankInfoRow("Ngân hàng:", bankName, isModern),
                                              _buildBankInfoRow("Số tài khoản:", bankAccountNo, isModern),
                                              _buildBankInfoRow("Chủ tài khoản:", bankAccountName, isModern),
                                            ],
                                          ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Lịch sử nhận thanh toán đối soát (${settlements.length})",
                          style: TextStyle(
                            color: isModern ? Colors.white : Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        settlements.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    "Chưa có giao dịch đối soát nào từ hệ thống.",
                                    style: TextStyle(color: isModern ? Colors.white54 : Colors.grey),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: settlements.length,
                                itemBuilder: (context, index) {
                                  final item = settlements[index];
                                  final double amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                                  final settledAtStr = item['settledAt'] != null 
                                      ? DateTime.parse(item['settledAt']).toLocal().toString().substring(0, 19)
                                      : '';
                                  final bookingIds = item['bookingIds'] ?? '';

                                  return Card(
                                    color: isModern ? const Color(0xFF1E1E1E) : Colors.white,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: isModern ? const BorderSide(color: Colors.white10) : BorderSide.none,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Đã nhận: +${_formatMoney(amount)}",
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                settledAtStr,
                                                style: TextStyle(
                                                  color: isModern ? Colors.white38 : Colors.grey,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "Mã đơn đối soát: $bookingIds",
                                            style: TextStyle(
                                              color: isModern ? Colors.white54 : Colors.black54,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isModern) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isModern ? Colors.white54 : Colors.grey[600], fontSize: 13)),
          Text(value, style: TextStyle(color: isModern ? Colors.white70 : Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
