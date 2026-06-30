import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/admin_repository.dart';

class AdminRevenueTab extends StatefulWidget {
  const AdminRevenueTab({Key? key}) : super(key: key);

  @override
  State<AdminRevenueTab> createState() => _AdminRevenueTabState();
}

class _AdminRevenueTabState extends State<AdminRevenueTab> {
  bool _isLoading = true;
  double _totalPlatformHeld = 0.0;
  List<dynamic> _allBookings = [];
  List<dynamic> _ownersRevenue = [];
  int _revenueSubTab = 0; // 0: Đối soát chủ sân, 1: Lịch sử cọc

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AdminRepository.getAdminRevenue(),
        AdminRepository.getAdminOwnersRevenue(),
      ]);

      final revenueData = results[0] as Map<String, dynamic>;
      final ownersRevenueData = results[1] as List<dynamic>;

      final bookings = List<dynamic>.from(revenueData['bookings'] ?? []);
      bookings.sort((a, b) {
        final aOwner = a['field']?['owner']?['ownerName']?.toString() ?? 'Chủ sân';
        final bOwner = b['field']?['owner']?['ownerName']?.toString() ?? 'Chủ sân';
        final ownerCompare = aOwner.compareTo(bOwner);
        if (ownerCompare != 0) return ownerCompare;

        final aTime = a['createdAt'] != null ? DateTime.parse(a['createdAt']) : DateTime.now();
        final bTime = b['createdAt'] != null ? DateTime.parse(b['createdAt']) : DateTime.now();
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _totalPlatformHeld = (revenueData['totalPlatformHeld'] as num?)?.toDouble() ?? 0.0;
          _allBookings = bookings;
          _ownersRevenue = ownersRevenueData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading revenue tab data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatMoney(double amount) {
    final int rounded = amount.round();
    final format = NumberFormat('#,###', 'vi_VN');
    String result = format.format(rounded);
    result = result.replaceAll(',', '.');
    return '$result đ';
  }

  Future<void> _settleOwner(int ownerId, String ownerName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Text(
          'Bạn có chắc chắn muốn đánh dấu đã đối soát & thanh toán cho chủ sân "$ownerName"? Việc này sẽ thiết lập số tiền giữ hộ hiện tại về 0đ và lưu vào lịch sử sao kê.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final success = await AdminRepository.settleOwner(ownerId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Thanh toán đối soát thành công cho chủ sân $ownerName!'), backgroundColor: Colors.green),
          );
          await _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thanh toán đối soát thất bại!'), backgroundColor: Colors.red),
          );
          if (mounted) setState(() => _isLoading = false);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đối soát: $e'), backgroundColor: Colors.red),
        );
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildOwnersRevenueList() {
    if (_ownersRevenue.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('Không có chủ sân nào')),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _ownersRevenue.length,
      itemBuilder: (context, index) {
        final item = _ownersRevenue[index];
        final int ownerId = item['ownerId'];
        final String ownerName = item['ownerName'] ?? 'Chủ sân';
        final String email = item['email'] ?? '';
        final String phone = item['contactNumber'] ?? '';
        final double unsettledAmount = (item['unsettledAmount'] as num?)?.toDouble() ?? 0.0;
        final List<dynamic> settlements = item['settlements'] ?? [];
        final String bankName = item['bankName'] ?? '';
        final String bankAccountNo = item['bankAccountNo'] ?? '';
        final String bankAccountName = item['bankAccountName'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ExpansionTile(
            title: Text(
              ownerName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Liên hệ: $email - $phone', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Chờ thanh toán: ', style: TextStyle(fontSize: 13)),
                    Text(
                      _formatMoney(unsettledAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: unsettledAmount > 0 ? Colors.red : Colors.green,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.account_balance,
                    color: bankAccountNo.isEmpty ? Colors.grey : Colors.blue,
                  ),
                  onPressed: () {
                    if (bankAccountNo.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Chủ sân chưa cấu hình tài khoản nhận tiền!"), backgroundColor: Colors.red),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Tài khoản nhận tiền - $ownerName'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBankDetailRow("Ngân hàng:", bankName),
                              const SizedBox(height: 8),
                              _buildBankDetailRow("Số tài khoản:", bankAccountNo),
                              const SizedBox(height: 8),
                              _buildBankDetailRow("Chủ tài khoản:", bankAccountName),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Đóng'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 4),
                unsettledAmount > 0
                    ? ElevatedButton(
                        onPressed: () => _settleOwner(ownerId, ownerName),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Thanh toán', style: TextStyle(fontSize: 12, color: Colors.white)),
                      )
                    : const Icon(Icons.check_circle_outline, color: Colors.green),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LỊCH SỬ SAO KÊ ĐỐI SOÁT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 8),
                    if (settlements.isEmpty)
                      const Text('Chưa có lịch sử sao kê thanh toán nào.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12))
                    else
                      ...settlements.map((s) {
                        final double amount = (s['amount'] as num?)?.toDouble() ?? 0.0;
                        DateTime settledTime = DateTime.now();
                        try {
                          if (s['settledAt'] != null) settledTime = DateTime.parse(s['settledAt']);
                        } catch (_) {}
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(settledTime)}',
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                              Text(
                                _formatMoney(amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBankDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildBookingsHistoryList(List<dynamic> list) {
    final settledBookings = list.where((b) => b['settled'] == true).toList();

    if (settledBookings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('Chưa có lịch sử cọc nào được đối soát')),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: settledBookings.length,
      itemBuilder: (context, index) {
        final b = settledBookings[index];
        final id = b['id'];
        final fieldName = b['field']?['name'] ?? 'Không rõ';
        final custName = b['customerName'] ?? 'Không rõ';
        final double totalPrice = (b['totalPrice'] as num?)?.toDouble() ?? 0.0;
        final status = b['status'] ?? 'APPROVED';

        DateTime? fromTime;
        DateTime? toTime;
        try {
          if (b['fromTime'] != null) fromTime = DateTime.parse(b['fromTime']);
          if (b['toTime'] != null) toTime = DateTime.parse(b['toTime']);
        } catch (_) {}

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text('🏟️ Sân: $fieldName (Đơn #$id)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('👤 Khách: $custName', style: const TextStyle(fontSize: 12)),
                if (fromTime != null && toTime != null)
                  Text(
                    '🕐 Giờ đá: ${fromTime.hour}:00 - ${toTime.hour}:00 ngày ${fromTime.day}/${fromTime.month}/${fromTime.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Số cọc: ', style: TextStyle(fontSize: 12)),
                    Text(_formatMoney(totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status == 'APPROVED' ? 'Đã duyệt' : 'Đã hủy',
                        style: TextStyle(color: status == 'APPROVED' ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.green,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          // Total platform held card
          Card(
            color: Colors.green.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.green.shade200, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.green, size: 40),
                  const SizedBox(height: 10),
                  const Text(
                    'TỔNG TIỀN CỌC ĐANG GIỮ HỘ',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatMoney(_totalPlatformHeld),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Sub-tab toggler
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _revenueSubTab = 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _revenueSubTab == 0 ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Đối soát chủ sân",
                        style: TextStyle(
                          color: _revenueSubTab == 0 ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _revenueSubTab = 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _revenueSubTab == 1 ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Lịch sử cọc",
                        style: TextStyle(
                          color: _revenueSubTab == 1 ? Colors.white : Colors.black87,
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
          _revenueSubTab == 0 ? _buildOwnersRevenueList() : _buildBookingsHistoryList(_allBookings),
        ],
      ),
    );
  }
}
