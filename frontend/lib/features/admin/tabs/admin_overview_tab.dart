import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/admin_repository.dart';

class AdminOverviewTab extends StatefulWidget {
  const AdminOverviewTab({Key? key}) : super(key: key);

  @override
  State<AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<AdminOverviewTab> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final data = await AdminRepository.getDashboardStats();
    if (mounted) {
      setState(() {
        _stats = data;
        _isLoading = false;
      });
    }
  }

  String _formatMoney(double amount) {
    final int rounded = amount.round();
    final format = NumberFormat('#,###', 'vi_VN');
    String result = format.format(rounded);
    result = result.replaceAll(',', '.');
    return '$result đ';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    final activeFields = _stats['activeFields'] ?? 0;
    final totalUsers = _stats['totalUsers'] ?? 0;
    final totalOwners = _stats['totalOwners'] ?? 0;
    final double totalUnsettled = (_stats['totalUnsettledAmount'] as num?)?.toDouble() ?? 0.0;
    final pendingBookings = _stats['pendingBookings'] ?? 0;
    final todayBookings = _stats['todayBookings'] ?? 0;
    final double revenueMonth = (_stats['revenueThisMonth'] as num?)?.toDouble() ?? 0.0;
    final List<dynamic> chartDays = _stats['bookingsByDay'] ?? [];
    final List<dynamic> alerts = _stats['alerts'] ?? [];

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: Colors.green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hệ thống tổng quan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green.shade900),
            ),
            const SizedBox(height: 12),
            // KPI cards grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.3,
              children: [
                _buildKPICard('Sân hoạt động 🏟️', '$activeFields', Colors.blue),
                _buildKPICard('Khách hàng 👥', '$totalUsers', Colors.purple),
                _buildKPICard('Chủ sân 🏢', '$totalOwners', Colors.teal),
                _buildKPICard('Đơn hôm nay 📅', '$todayBookings', Colors.orange),
                _buildKPICard('Chờ cọc ⏳', '$pendingBookings', Colors.red),
                _buildKPICard('Doanh thu tháng 💰', _formatMoney(revenueMonth), Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            // Holds card
            Card(
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.amber.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.amber, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng tiền cọc giữ hộ:',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatMoney(totalUnsettled),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Bar Chart
            if (chartDays.isNotEmpty) ...[
              _buildRevenueChart(chartDays),
              const SizedBox(height: 24),
            ],
            // Alerts
            if (alerts.isNotEmpty) ...[
              const Text(
                '⚠️ Cảnh báo hệ thống',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange),
              ),
              const SizedBox(height: 8),
              ...alerts.map((alert) {
                return Card(
                  color: Colors.orange.shade50,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: Text(
                      'Chủ sân "${alert['ownerName']}" chưa cấu hình tài khoản ngân hàng nhận tiền.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 5)),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(List<dynamic> days) {
    double maxRevenue = 1000.0;
    for (var day in days) {
      double rev = (day['revenue'] as num?)?.toDouble() ?? 0.0;
      if (rev > maxRevenue) maxRevenue = rev;
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Biểu đồ doanh thu cọc 7 ngày qua',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map<Widget>((day) {
                double rev = (day['revenue'] as num?)?.toDouble() ?? 0.0;
                double pct = rev / maxRevenue;
                final dateStr = day['date']?.toString() ?? '';
                final parts = dateStr.split('-');
                final label = parts.length > 2 ? '${parts[2]}/${parts[1]}' : dateStr;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        rev > 0 ? '${(rev / 1000).round()}k' : '0',
                        style: const TextStyle(fontSize: 9, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: (80 * pct).clamp(4.0, 80.0),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(label, style: const TextStyle(fontSize: 9, color: Colors.black54)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
