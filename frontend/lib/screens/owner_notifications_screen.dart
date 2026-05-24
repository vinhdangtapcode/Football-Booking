import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OwnerNotificationsScreen extends StatefulWidget {
  @override
  _OwnerNotificationsScreenState createState() => _OwnerNotificationsScreenState();
}

class _OwnerNotificationsScreenState extends State<OwnerNotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });
    final notis = await ApiService.getNotifications();
    notis.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
    setState(() {
      notifications = notis;
      isLoading = false;
    });
  }

  Future<void> _markAsRead(int id, int index) async {
    if (notifications[index]['read'] == true) return;
    final success = await ApiService.markNotificationAsRead(id);
    if (success) {
      setState(() {
        notifications[index]['read'] = true;
      });
    }
  }

  Future<void> _deleteNotification(int id) async {
    final success = await ApiService.deleteNotification(id);
    if (success) {
      setState(() {
        notifications.removeWhere((n) => n['id'] == id);
      });
    }
  }

  String _formatDateTime(String isoString) {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.amber),
      ),
      backgroundColor: const Color(0xFFF8F8F8),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có thông báo nào.',
                        style: TextStyle(fontSize: 18, color: Colors.grey[700], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final noti = notifications[index];
                      final isRead = noti['read'] == true;
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: isRead ? Colors.white : Colors.amber[50],
                        child: ListTile(
                          onTap: () => _markAsRead(noti['id'], index),
                          leading: Container(
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isRead ? Icons.notifications : Icons.notifications_active,
                              color: Colors.amber,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            noti['message'] ?? '',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 15,
                              color: isRead ? Colors.black87 : Colors.black,
                            ),
                          ),
                          subtitle: Text(_formatDateTime(noti['createdAt'] ?? '')),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteNotification(noti['id']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

