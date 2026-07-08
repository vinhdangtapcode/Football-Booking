import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../../../services/theme_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/field.dart';
import '../../field/repositories/field_repository.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const List<Map<String, dynamic>> _filters = [
    {'key': 'ALL', 'label': 'Tất cả'},
    {'key': 'BOOKING_CONFIRMED', 'label': 'Đặt sân'},
    {'key': 'BOOKING_CANCELLED', 'label': 'Hủy sân'},
    {'key': 'BOOKING_REMINDER', 'label': 'Nhắc nhở'},
    {'key': 'REVIEW_REQUEST', 'label': 'Đánh giá'},
    {'key': 'SETTLEMENT_DONE', 'label': 'Đối soát'},
    {'key': 'SYSTEM', 'label': 'Hệ thống'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  String _formatDateTime(String isoString) {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Returns [icon, lightBg, lightIcon, darkBg, darkIcon] for a notification type
  Map<String, dynamic> _typeConfig(String type) {
    switch (type) {
      case 'BOOKING_CONFIRMED':
        return {
          'icon': Icons.check_circle_rounded,
          'lightBg': const Color(0xFFE8F5E9),
          'lightIcon': const Color(0xFF2E7D32),
          'darkBg': const Color(0xFF1B3A2D),
          'darkIcon': const Color(0xFF66BB6A),
          'accentLight': const Color(0xFF4CAF50),
          'accentDark': const Color(0xFF66BB6A),
        };
      case 'BOOKING_CANCELLED_BY_USER':
        return {
          'icon': Icons.cancel_rounded,
          'lightBg': const Color(0xFFFFEBEE),
          'lightIcon': const Color(0xFFC62828),
          'darkBg': const Color(0xFF3A1B1B),
          'darkIcon': const Color(0xFFEF9A9A),
          'accentLight': const Color(0xFFF44336),
          'accentDark': const Color(0xFFEF9A9A),
        };
      case 'BOOKING_CANCELLED_BY_ADMIN':
        return {
          'icon': Icons.block_rounded,
          'lightBg': const Color(0xFFFCE4EC),
          'lightIcon': const Color(0xFFAD1457),
          'darkBg': const Color(0xFF3A1B2A),
          'darkIcon': const Color(0xFFF48FB1),
          'accentLight': const Color(0xFFE91E63),
          'accentDark': const Color(0xFFF48FB1),
        };
      case 'BOOKING_REMINDER':
        return {
          'icon': Icons.alarm_rounded,
          'lightBg': const Color(0xFFE3F2FD),
          'lightIcon': const Color(0xFF1565C0),
          'darkBg': const Color(0xFF1B2F3A),
          'darkIcon': const Color(0xFF90CAF9),
          'accentLight': const Color(0xFF2196F3),
          'accentDark': const Color(0xFF90CAF9),
        };
      case 'REVIEW_REQUEST':
        return {
          'icon': Icons.star_rounded,
          'lightBg': const Color(0xFFFFFDE7),
          'lightIcon': const Color(0xFFF57F17),
          'darkBg': const Color(0xFF3A3010),
          'darkIcon': const Color(0xFFFFD54F),
          'accentLight': const Color(0xFFFFC107),
          'accentDark': const Color(0xFFFFD54F),
        };
      case 'SETTLEMENT_DONE':
        return {
          'icon': Icons.payments_rounded,
          'lightBg': const Color(0xFFE0F2F1),
          'lightIcon': const Color(0xFF00695C),
          'darkBg': const Color(0xFF1B3A38),
          'darkIcon': const Color(0xFF80CBC4),
          'accentLight': const Color(0xFF009688),
          'accentDark': const Color(0xFF80CBC4),
        };
      case 'SYSTEM_BROADCAST':
        return {
          'icon': Icons.campaign_rounded,
          'lightBg': const Color(0xFFEDE7F6),
          'lightIcon': const Color(0xFF4527A0),
          'darkBg': const Color(0xFF2A1B3A),
          'darkIcon': const Color(0xFFCE93D8),
          'accentLight': const Color(0xFF7E57C2),
          'accentDark': const Color(0xFFCE93D8),
        };
      case 'SYSTEM_MAINTENANCE':
        return {
          'icon': Icons.build_rounded,
          'lightBg': const Color(0xFFFFF3E0),
          'lightIcon': const Color(0xFFE65100),
          'darkBg': const Color(0xFF3A2A10),
          'darkIcon': const Color(0xFFFFCC80),
          'accentLight': const Color(0xFFFF9800),
          'accentDark': const Color(0xFFFFCC80),
        };
      default:
        return {
          'icon': Icons.notifications_rounded,
          'lightBg': const Color(0xFFF5F5F5),
          'lightIcon': const Color(0xFF616161),
          'darkBg': const Color(0xFF1F1F1F),
          'darkIcon': const Color(0xFFBDBDBD),
          'accentLight': const Color(0xFF9E9E9E),
          'accentDark': const Color(0xFFBDBDBD),
        };
    }
  }

  Widget _buildActionButton(Map<String, dynamic> noti, bool isModern) {
    final type = (noti['type'] ?? 'GENERAL').toString();
    if (type == 'REVIEW_REQUEST') {
      return Padding(
        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
        child: SizedBox(
          width: double.infinity,
          height: 36,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.star_rounded, size: 16),
            label: const Text('Đánh giá ngay', style: TextStyle(fontSize: 12, fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: isModern ? Colors.white : Colors.amber[800],
              side: BorderSide(color: isModern ? Colors.white24 : Colors.amber),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: EdgeInsets.zero,
            ),
            onPressed: () async {
              final fieldId = noti['fieldId'];
              if (fieldId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Không tìm thấy thông tin sân để đánh giá.')),
                );
                return;
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                final field = await FieldRepository.getFieldById(fieldId);
                if (mounted) {
                  Navigator.pop(context); // Đóng loading dialog
                  if (field != null) {
                    Navigator.pushNamed(
                      context,
                      AppConstants.addRating,
                      arguments: field,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không thể tải thông tin sân bóng.')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Đóng loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi tải sân bóng: $e')),
                  );
                }
              }
            },
          ),
        ),
      );
    }
    if (type == 'BOOKING_REMINDER' ||
        type == 'BOOKING_CONFIRMED' ||
        type == 'BOOKING_CANCELLED_BY_USER' ||
        type == 'BOOKING_CANCELLED_BY_ADMIN') {
      return Padding(
        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
        child: SizedBox(
          width: double.infinity,
          height: 36,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_rounded, size: 16),
            label: const Text('Xem lịch đặt', style: TextStyle(fontSize: 12, fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: isModern ? Colors.white : Colors.amber[800],
              side: BorderSide(color: isModern ? Colors.white24 : Colors.amber),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: EdgeInsets.zero,
            ),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppConstants.bookingHistory,
                (route) => false,
              );
            },
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildQuickFilterChip(String key, String label, bool isModern, NotificationProvider provider) {
    final isSelected = provider.selectedFilter == key;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: isSelected
                ? (isModern ? Colors.black : Colors.white)
                : (isModern ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          provider.setFilter(key);
        },
        selectedColor: isModern ? Colors.white : Colors.amber,
        backgroundColor: isModern ? const Color(0xFF16181D) : Colors.grey[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? (isModern ? Colors.white : Colors.amber)
                : (isModern ? Colors.white10 : Colors.transparent),
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = themeProvider.isModernMode;
    final provider = context.watch<NotificationProvider>();
    final filtered = provider.filteredNotifications;
    final unreadCount = provider.notifications.where((n) => n['read'] != true).length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Thông báo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      backgroundColor: isModern ? const Color(0xFF0A0B0E) : Colors.grey[100],
      body: provider.isLoading
          ? Center(child: CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber))
          : Column(
              children: [
                // ---- Filter chips ----
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) => _buildQuickFilterChip(f['key'] as String, f['label'] as String, isModern, provider)).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // ---- Notification list ----
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_rounded, size: 64, color: isModern ? Colors.white24 : Colors.amber.withOpacity(0.3)),
                              const SizedBox(height: 14),
                              Text(
                                provider.selectedFilter == 'ALL' ? 'Chưa có thông báo nào.' : 'Không có thông báo trong danh mục này.',
                                style: TextStyle(fontSize: 15, color: isModern ? Colors.white54 : Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: provider.loadNotifications,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final noti = filtered[index];
                              final isRead = noti['read'] == true;
                              final type = (noti['type'] ?? 'GENERAL').toString();
                              final cfg = _typeConfig(type);
                              final iconColor = isModern ? cfg['darkIcon'] as Color : cfg['lightIcon'] as Color;
                              final iconBg   = isModern ? cfg['darkBg']   as Color : cfg['lightBg']   as Color;
                              final accent   = isModern ? cfg['accentDark'] as Color : cfg['accentLight'] as Color;

                              return Card(
                                color: isModern ? const Color(0xFF16181D) : Colors.white,
                                elevation: isModern ? 1 : 4,
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: isModern
                                      ? BorderSide(
                                          color: isRead ? Colors.white10 : accent,
                                          width: isRead ? 1 : 2,
                                        )
                                      : BorderSide(
                                          color: isRead ? Colors.transparent : accent,
                                          width: isRead ? 0 : 2,
                                        ),
                                ),
                                child: InkWell(
                                  onTap: () => provider.markAsRead(noti['id']),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Icon container
                                            Container(
                                              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.all(8),
                                              child: Icon(cfg['icon'] as IconData, color: iconColor, size: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            // Message & Date
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    noti['message'] ?? '',
                                                    style: TextStyle(
                                                      fontFamily: 'Roboto',
                                                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                                      fontSize: 14,
                                                      color: isModern
                                                          ? (isRead ? Colors.white60 : Colors.white)
                                                          : (isRead ? Colors.black54 : Colors.black87),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    _formatDateTime(noti['createdAt'] ?? ''),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontFamily: 'Roboto',
                                                      color: isModern ? Colors.white38 : Colors.grey[500],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Delete icon
                                            IconButton(
                                              icon: Icon(Icons.delete_outline_rounded, size: 18, color: isModern ? Colors.white30 : Colors.red[300]),
                                              onPressed: () => provider.deleteNotification(noti['id']),
                                              visualDensity: VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildActionButton(noti, isModern),
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
    );
  }
}
