import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/admin_repository.dart';

class AdminBookingsTab extends StatefulWidget {
  final String searchQuery;

  const AdminBookingsTab({Key? key, required this.searchQuery}) : super(key: key);

  @override
  State<AdminBookingsTab> createState() => _AdminBookingsTabState();
}

class _AdminBookingsTabState extends State<AdminBookingsTab> {
  List<dynamic> _bookingsList = [];
  bool _isLoading = true;
  String _selectedBookingStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final data = await AdminRepository.getAdminBookings();
    if (mounted) {
      setState(() {
        _bookingsList = data;
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredBookings {
    return _bookingsList.where((b) {
      final status = b['status'] ?? 'PENDING_PAYMENT';
      if (_selectedBookingStatus != 'ALL' && status != _selectedBookingStatus) {
        return false;
      }
      if (widget.searchQuery.isNotEmpty) {
        final custName = b['customerName']?.toString().toLowerCase() ?? '';
        final custPhone = b['customerPhone']?.toString() ?? '';
        final fieldName = b['field']?['name']?.toString().toLowerCase() ?? '';
        final q = widget.searchQuery.toLowerCase();
        return custName.contains(q) || custPhone.contains(q) || fieldName.contains(q);
      }
      return true;
    }).toList();
  }

  String _formatMoney(double amount) {
    final int rounded = amount.round();
    final format = NumberFormat('#,###', 'vi_VN');
    String result = format.format(rounded);
    result = result.replaceAll(',', '.');
    return '$result đ';
  }

  Future<void> _adminCancelBooking(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đặt sân'),
        content: Text('Bạn có chắc chắn muốn hủy lịch đặt sân #$id? Khách hàng sẽ nhận được thông báo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final success = await AdminRepository.cancelBooking(id);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã hủy đặt sân #$id!'), backgroundColor: Colors.green),
          );
          await _loadBookings();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể hủy đặt sân này'), backgroundColor: Colors.red),
          );
          if (mounted) setState(() => _isLoading = false);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi hủy đặt sân: $e'), backgroundColor: Colors.red),
        );
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatusFilterChip(String label, String status) {
    final isSelected = _selectedBookingStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() => _selectedBookingStatus = status);
          }
        },
        selectedColor: Colors.green.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.green.shade800 : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBookings;

    return Column(
      children: [
        // Horizontal status selectors
        Container(
          height: 48,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildStatusFilterChip('Tất cả', 'ALL'),
              _buildStatusFilterChip('Đã duyệt ✅', 'APPROVED'),
              _buildStatusFilterChip('Chờ cọc ⏳', 'PENDING_PAYMENT'),
              _buildStatusFilterChip('Đã hủy ❌', 'CANCELLED'),
              _buildStatusFilterChip('Hết hạn ⏰', 'EXPIRED'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.green))
              : filtered.isEmpty
                  ? const Center(child: Text('Không tìm thấy lịch đặt nào.'))
                  : RefreshIndicator(
                      onRefresh: _loadBookings,
                      color: Colors.green,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final b = filtered[index];
                          final id = b['id'];
                          final fieldName = b['field']?['name'] ?? 'Sân không rõ';
                          final custName = b['customerName'] ?? 'Khách không rõ';
                          final custPhone = b['customerPhone'] ?? '';
                          final fromTime = b['fromTime'] != null ? DateTime.parse(b['fromTime']) : null;
                          final toTime = b['toTime'] != null ? DateTime.parse(b['toTime']) : null;
                          final createdAt = b['createdAt'] != null ? DateTime.parse(b['createdAt']) : null;
                          final status = b['status'] ?? 'PENDING_PAYMENT';
                          final double totalPrice = (b['totalPrice'] as num?)?.toDouble() ?? 0.0;

                          Color statusColor;
                          String statusLabel;
                          switch (status) {
                            case 'APPROVED':
                              statusColor = Colors.green;
                              statusLabel = 'Đã duyệt';
                              break;
                            case 'CANCELLED':
                              statusColor = Colors.red;
                              statusLabel = 'Đã hủy';
                              break;
                            case 'EXPIRED':
                              statusColor = Colors.grey;
                              statusLabel = 'Hết hạn';
                              break;
                            default:
                              statusColor = Colors.orange;
                              statusLabel = 'Chờ cọc';
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Mã đơn: #$id', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 12),
                                  Text('🏟️ Sân: $fieldName', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text('👤 Khách: $custName ($custPhone)', style: const TextStyle(fontSize: 13)),
                                  const SizedBox(height: 4),
                                  if (fromTime != null && toTime != null)
                                    Text('🕐 Giờ đá: ${fromTime.hour}:00 - ${toTime.hour}:00 ngày ${fromTime.day}/${fromTime.month}/${fromTime.year}', style: const TextStyle(fontSize: 12)),
                                  if (createdAt != null)
                                    Text('📅 Ngày đặt: ${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Tổng cọc: ${_formatMoney(totalPrice)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                      Row(
                                        children: [
                                          if (status == 'APPROVED' || status == 'PENDING_PAYMENT') ...[
                                            TextButton.icon(
                                              onPressed: () => _adminCancelBooking(id),
                                              icon: const Icon(Icons.cancel, size: 14, color: Colors.red),
                                              label: const Text('Hủy', style: TextStyle(fontSize: 11, color: Colors.red)),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
