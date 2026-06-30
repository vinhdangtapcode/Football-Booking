import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/field.dart';
import '../repositories/admin_repository.dart';

class AdminStadiumsTab extends StatefulWidget {
  final String searchQuery;

  const AdminStadiumsTab({Key? key, required this.searchQuery}) : super(key: key);

  @override
  State<AdminStadiumsTab> createState() => _AdminStadiumsTabState();
}

class _AdminStadiumsTabState extends State<AdminStadiumsTab> {
  List<Field> _stadiums = [];
  List<dynamic> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      AdminRepository.getAllStadiums(),
      AdminRepository.getAdminBookings(),
    ]);

    if (mounted) {
      setState(() {
        _stadiums = (results[0] as List<Field>).reversed.toList();
        _allBookings = results[1] as List<dynamic>;
        _isLoading = false;
      });
    }
  }

  List<Field> get _filteredStadiums {
    if (widget.searchQuery.isEmpty) return _stadiums;
    final q = widget.searchQuery.toLowerCase();
    return _stadiums.where((s) {
      final name = s.name.toLowerCase();
      final address = s.address.toLowerCase();
      final ownerName = s.owner?.ownerName.toLowerCase() ?? '';
      return name.contains(q) || address.contains(q) || ownerName.contains(q);
    }).toList();
  }

  String _formatMoney(double amount) {
    final int rounded = amount.round();
    final format = NumberFormat('#,###', 'vi_VN');
    String result = format.format(rounded);
    result = result.replaceAll(',', '.');
    return '$result đ';
  }

  Future<void> _toggleStadiumAvailability(Field stadium) async {
    if (stadium.id == null) return;
    setState(() => _isLoading = true);
    final success = await AdminRepository.toggleFieldAvailability(stadium.id!);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thay đổi trạng thái hoạt động của sân thành công!'), backgroundColor: Colors.green),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật trạng thái sân thất bại!'), backgroundColor: Colors.red),
      );
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStadium(Field stadium) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa sân "${stadium.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && stadium.id != null) {
      setState(() => _isLoading = true);
      final success = await AdminRepository.adminDeleteOwner(stadium.id!); // Note: API service delegates delete fields
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa sân thành công'), backgroundColor: Colors.green),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa sân'), backgroundColor: Colors.red),
        );
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToForm(Field? stadium) async {
    final result = await Navigator.pushNamed(context, '/adminFieldForm', arguments: stadium);
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _adminCancelBooking(int id) async {
    setState(() => _isLoading = true);
    final success = await AdminRepository.cancelBooking(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã hủy đặt sân #$id!'), backgroundColor: Colors.green),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hủy đặt sân thất bại!'), backgroundColor: Colors.red),
      );
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBookingHistoryDialog({required String title, required List<dynamic> bookings}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: bookings.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có lịch sử đặt sân nào.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final b = bookings[index];
                            final id = b['id'];
                            final status = b['status'] ?? 'PENDING_PAYMENT';
                            final totalPrice = (b['totalPrice'] as num?)?.toDouble() ?? 0.0;
                            final fieldName = b['field']?['name'] ?? 'Không rõ';
                            final custName = b['customer']?['name'] ?? b['customerName'] ?? 'Không rõ';
                            final custPhone = b['customer']?['phone'] ?? 'N/A';
                            
                            DateTime? fromTime;
                            DateTime? toTime;
                            DateTime? createdAt;
                            try {
                              if (b['fromTime'] != null) fromTime = DateTime.parse(b['fromTime']);
                              if (b['toTime'] != null) toTime = DateTime.parse(b['toTime']);
                              if (b['createdAt'] != null) createdAt = DateTime.parse(b['createdAt']);
                            } catch (e) {
                              // ignore
                            }

                            Color statusColor = Colors.grey;
                            String statusLabel = 'Không rõ';
                            if (status == 'APPROVED') {
                              statusColor = Colors.green;
                              statusLabel = 'Đã duyệt';
                            } else if (status == 'PENDING_PAYMENT') {
                              statusColor = Colors.orange;
                              statusLabel = 'Chờ cọc';
                            } else if (status == 'CANCELLED') {
                              statusColor = Colors.red;
                              statusLabel = 'Đã hủy';
                            } else if (status == 'EXPIRED') {
                              statusColor = Colors.grey;
                              statusLabel = 'Hết hạn';
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1,
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
                                        if (status == 'APPROVED' || status == 'PENDING_PAYMENT')
                                          TextButton.icon(
                                            onPressed: () async {
                                              final proceed = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Hủy đặt sân'),
                                                  content: Text('Bạn có chắc chắn muốn hủy lịch đặt sân #$id không?'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(ctx, true),
                                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                      child: const Text('Xác nhận'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (proceed == true) {
                                                Navigator.pop(context); // close bottom sheet
                                                await _adminCancelBooking(id);
                                              }
                                            },
                                            icon: const Icon(Icons.cancel, size: 14, color: Colors.red),
                                            label: const Text('Hủy', style: TextStyle(fontSize: 11, color: Colors.red)),
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
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Statistics cards
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 4.0, top: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.blue.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          const Icon(Icons.sports_soccer, color: Colors.blue, size: 30),
                          const SizedBox(height: 8),
                          Text(
                            '${_stadiums.length}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text('Tổng số sân'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: Colors.green.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 30),
                          const SizedBox(height: 8),
                          Text(
                            '${_stadiums.where((s) => s.available == true).length}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text('Sân hoạt động'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Stadium list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : _filteredStadiums.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Không có sân nào',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: Colors.green,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredStadiums.length,
                          itemBuilder: (context, index) {
                            final stadium = _filteredStadiums[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: stadium.available == true ? Colors.green : Colors.red,
                                  child: const Icon(
                                    Icons.sports_soccer,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  stadium.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(stadium.address),
                                    const SizedBox(height: 4),
                                    if (stadium.owner != null) ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 16, color: Colors.blue),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Chủ sân: ${stadium.owner!.ownerName}',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                    ] else ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.person_off, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Chưa có chủ sân',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    Row(
                                      children: [
                                        const Icon(Icons.attach_money, size: 16, color: Colors.green),
                                        Text(
                                          '${stadium.pricePerHour.toStringAsFixed(0)}K VNĐ/giờ',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        if (stadium.rating != null) ...[
                                          const Icon(Icons.star, size: 16, color: Colors.amber),
                                          Text(' ${stadium.rating!.toStringAsFixed(1)}'),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => _toggleStadiumAvailability(stadium),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: stadium.available == true ? Colors.green.shade100 : Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          stadium.available == true ? 'Hoạt động' : 'Ngừng hoạt động',
                                          style: TextStyle(
                                            color: stadium.available == true ? Colors.green.shade700 : Colors.red.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _navigateToForm(stadium);
                                        break;
                                      case 'delete':
                                        _deleteStadium(stadium);
                                        break;
                                      case 'history':
                                        final stBookings = _allBookings.where((b) => b['field']?['id'] == stadium.id).toList();
                                        _showBookingHistoryDialog(
                                          title: 'Lịch sử đặt: ${stadium.name}',
                                          bookings: stBookings,
                                        );
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Chỉnh sửa'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'history',
                                      child: Row(
                                        children: [
                                          Icon(Icons.history, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Lịch sử đặt sân'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Xóa'),
                                        ],
                                      ),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(null),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm sân', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
