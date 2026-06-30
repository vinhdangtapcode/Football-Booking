import 'package:flutter/material.dart';
import '../repositories/admin_repository.dart';

class AdminSystemTab extends StatefulWidget {
  const AdminSystemTab({Key? key}) : super(key: key);

  @override
  State<AdminSystemTab> createState() => _AdminSystemTabState();
}

class _AdminSystemTabState extends State<AdminSystemTab> {
  bool _isLoading = true;
  List<dynamic> _configs = [];
  List<dynamic> _auditLogs = [];
  int _systemSubTab = 0; // 0: Cấu hình, 1: Gửi thông báo đẩy, 2: Nhật ký hoạt động

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _broadcastFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AdminRepository.getAdminConfigs(),
        AdminRepository.getAdminAuditLogs(),
      ]);

      if (mounted) {
        setState(() {
          _configs = results[0] as List<dynamic>;
          _auditLogs = results[1] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading system tab data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editConfig(String key, String currentVal, String desc) async {
    final controller = TextEditingController(text: currentVal);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sửa cấu hình: $desc'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Giá trị mới'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final success = await AdminRepository.updateAdminConfig(key, controller.text.trim());
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật cấu hình thành công!'), backgroundColor: Colors.green),
          );
          await _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật cấu hình thất bại!'), backgroundColor: Colors.red),
          );
          if (mounted) setState(() => _isLoading = false);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSystemConfigsView() {
    if (_configs.isEmpty) {
      return const Center(child: Text('Không tải được cấu hình hệ thống.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _configs.length,
      itemBuilder: (context, index) {
        final cfg = _configs[index];
        final key = cfg['configKey'];
        final val = cfg['configValue'];
        final desc = cfg['description'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            title: Text(desc.isNotEmpty ? desc : key, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Giá trị: $val'),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editConfig(key, val, desc),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPushNotificationView() {
    return Form(
      key: _broadcastFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gửi thông báo đẩy hệ thống', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Tiêu đề thông báo *', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tiêu đề' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bodyController,
            decoration: const InputDecoration(labelText: 'Nội dung thông báo *', border: OutlineInputBorder()),
            maxLines: 4,
            validator: (v) => v == null || v.trim().isEmpty ? 'Nhập nội dung' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_broadcastFormKey.currentState!.validate()) {
                  setState(() => _isLoading = true);
                  try {
                    final success = await AdminRepository.adminBroadcastNotification(
                      _titleController.text.trim(),
                      _bodyController.text.trim(),
                    );
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã gửi thông báo đẩy tới toàn bộ thiết bị khách hàng & chủ sân!'), backgroundColor: Colors.green),
                      );
                      _titleController.clear();
                      _bodyController.clear();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gửi thông báo thất bại!'), backgroundColor: Colors.red),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                }
              },
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text('Gửi thông báo ngay', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogView() {
    if (_auditLogs.isEmpty) {
      return const Center(child: Text('Chưa có hoạt động quản trị nào.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _auditLogs.length,
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        final email = log['adminEmail'] ?? 'Hệ thống';
        final action = log['action'] ?? '';
        final desc = log['description'] ?? '';
        final timeStr = log['createdAt'] != null
            ? DateTime.parse(log['createdAt']).toLocal().toString().substring(0, 19)
            : '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(action, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Admin: $email', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 13)),
              ],
            ),
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
          // Sub tabs toggler
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
                    onTap: () => setState(() => _systemSubTab = 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _systemSubTab == 0 ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Cấu hình",
                        style: TextStyle(
                          color: _systemSubTab == 0 ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _systemSubTab = 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _systemSubTab == 1 ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Gửi thông báo đẩy",
                        style: TextStyle(
                          color: _systemSubTab == 1 ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _systemSubTab = 2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _systemSubTab == 2 ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Nhật ký hoạt động",
                        style: TextStyle(
                          color: _systemSubTab == 2 ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _systemSubTab == 0
              ? _buildSystemConfigsView()
              : _systemSubTab == 1
                  ? _buildPushNotificationView()
                  : _buildAuditLogView(),
        ],
      ),
    );
  }
}
