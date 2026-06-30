import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../models/user.dart';
import '../repositories/admin_repository.dart';

class AdminUsersTab extends StatefulWidget {
  final String searchQuery;

  const AdminUsersTab({Key? key, required this.searchQuery}) : super(key: key);

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  List<User> _users = [];
  List<dynamic> _owners = [];
  List<dynamic> _allBookings = [];
  bool _isLoading = true;
  int _subTab = 0; // 0: Customers, 1: Owners

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final bookingsData = await AdminRepository.getAdminBookings();
      final ownersData = await AdminRepository.getAdminOwners();
      
      final usersResponse = await ApiClient.get('/api/users');
      List<User> usersList = [];
      if (usersResponse.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(usersResponse.bodyBytes));
        usersList = list.map((item) => User.fromJson(item)).toList();
      }

      if (mounted) {
        setState(() {
          _allBookings = bookingsData;
          _owners = ownersData;
          _users = usersList.reversed.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading users tab data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<User> get _filteredUsers {
    if (widget.searchQuery.isEmpty) return _users;
    final q = widget.searchQuery.toLowerCase();
    return _users.where((u) {
      final name = u.name.toLowerCase();
      final email = u.email.toLowerCase();
      final phone = u.phone?.toLowerCase() ?? '';
      return name.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
  }

  List<dynamic> get _filteredOwners {
    if (widget.searchQuery.isEmpty) return _owners;
    final q = widget.searchQuery.toLowerCase();
    return _owners.where((o) {
      final name = (o['ownerName'] ?? '').toString().toLowerCase();
      final email = (o['email'] ?? '').toString().toLowerCase();
      final phone = (o['contactNumber'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
  }

  String _formatMoney(double amount) {
    final int rounded = amount.round();
    final format = NumberFormat('#,###', 'vi_VN');
    String result = format.format(rounded);
    result = result.replaceAll(',', '.');
    return '$result đ';
  }

  Future<void> _toggleUserLock(User user) async {
    if (user.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản'),
        content: Text('Bạn có chắc chắn muốn ${user.isLocked ? "mở khóa" : "khóa"} tài khoản "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await AdminRepository.toggleLock(user.id!);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.isLocked ? "Mở khóa" : "Khóa"} tài khoản thành công!'), backgroundColor: Colors.green),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thao tác thất bại! Bạn không thể tự khóa chính mình hoặc các tài khoản Admin khác.'), backgroundColor: Colors.red),
        );
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteUser(User user) async {
    if (user.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa người dùng "${user.name}"?'),
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

    if (confirm == true) {
      setState(() => _isLoading = true);
      // Delete user request via ApiClient
      final res = await ApiClient.delete('/api/users/${user.id}');
      if (res.statusCode == 200 || res.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa người dùng thành công'), backgroundColor: Colors.green),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa người dùng'), backgroundColor: Colors.red),
        );
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToUserForm(User user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quản lý người dùng: ${user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            Text('Số điện thoại: ${user.phone ?? "Không có"}'),
            Text('Vai trò: ${user.role ?? "USER"}'),
            const SizedBox(height: 16),
            const Text('Tùy chọn:', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () async {
              await _showEditUserDialog(user);
              Navigator.pop(context, true);
            },
            child: const Text('Chỉnh sửa'),
          ),
          TextButton(
            onPressed: () async {
              final newPassword = await _showPasswordResetDialog(user);
              if (newPassword != null) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Đặt lại mật khẩu'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _showEditUserDialog(User user) async {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');
    String selectedRole = user.role ?? 'USER';
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa thông tin người dùng'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'USER', child: Text('Người dùng')),
                  DropdownMenuItem(value: 'OWNER', child: Text('Chủ sân')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên')),
                ],
                onChanged: (val) {
                  if (val != null) selectedRole = val;
                },
                decoration: const InputDecoration(labelText: 'Vai trò'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                final res = await ApiClient.put(
                  '/api/users/${user.id}',
                  body: jsonEncode({
                    "name": nameController.text.trim(),
                    "phone": phoneController.text.trim(),
                    "role": selectedRole,
                  }),
                );
                if (res.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cập nhật thông tin người dùng thành công'), backgroundColor: Colors.green),
                  );
                  await _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cập nhật thất bại'), backgroundColor: Colors.red),
                  );
                  if (mounted) setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showPasswordResetDialog(User user) async {
    final TextEditingController passwordController = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đặt lại mật khẩu cho ${user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (passwordController.text.isNotEmpty) {
                Navigator.pop(context, passwordController.text);
                setState(() => _isLoading = true);
                final success = await AdminRepository.adminResetPassword(user.id!, passwordController.text);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đặt lại mật khẩu thành công'), backgroundColor: Colors.green),
                  );
                  await _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể đặt lại mật khẩu'), backgroundColor: Colors.red),
                  );
                  if (mounted) setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditOwnerDialog([Map<String, dynamic>? owner]) async {
    final isEdit = owner != null;
    final nameController = TextEditingController(text: isEdit ? owner['ownerName'] : '');
    final emailController = TextEditingController(text: isEdit ? owner['email'] : '');
    final phoneController = TextEditingController(text: isEdit ? owner['contactNumber'] : '');
    final bankController = TextEditingController(text: isEdit ? (owner['bankName'] ?? '') : '');
    final accNoController = TextEditingController(text: isEdit ? (owner['bankAccountNo'] ?? '') : '');
    final accNameController = TextEditingController(text: isEdit ? (owner['bankAccountName'] ?? '') : '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Chỉnh sửa chủ sân' : 'Thêm chủ sân mới'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên chủ sân'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  enabled: !isEdit,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập email' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                ),
                TextFormField(
                  controller: bankController,
                  decoration: const InputDecoration(labelText: 'Tên Ngân hàng'),
                ),
                TextFormField(
                  controller: accNoController,
                  decoration: const InputDecoration(labelText: 'Số tài khoản'),
                ),
                TextFormField(
                  controller: accNameController,
                  decoration: const InputDecoration(labelText: 'Chủ tài khoản ngân hàng'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                setState(() => _isLoading = true);

                final payload = {
                  "ownerName": nameController.text.trim(),
                  "email": emailController.text.trim(),
                  "contactNumber": phoneController.text.trim(),
                  "bankName": bankController.text.trim(),
                  "bankAccountNo": accNoController.text.trim(),
                  "bankAccountName": accNameController.text.trim(),
                };

                final bool success = isEdit
                    ? await AdminRepository.adminUpdateOwner(owner['id'], payload)
                    : await AdminRepository.adminCreateOwner(payload);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEdit ? 'Cập nhật thành công!' : 'Tạo mới chủ sân thành công!'), backgroundColor: Colors.green),
                  );
                  await _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thao tác thất bại!'), backgroundColor: Colors.red),
                  );
                  if (mounted) setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOwner(int ownerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa chủ sân này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await AdminRepository.adminDeleteOwner(ownerId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa chủ sân thành công!'), backgroundColor: Colors.green),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa chủ sân!'), backgroundColor: Colors.red),
        );
        if (mounted) setState(() => _isLoading = false);
      }
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

  Widget _buildUsersSubTab() {
    final filtered = _filteredUsers;
    if (filtered.isEmpty) {
      return const Center(child: Text('Không tìm thấy người dùng nào'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final user = filtered[index];
        final isLocked = user.isLocked;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: user.role == 'ADMIN' ? Colors.red : (user.role == 'OWNER' ? Colors.blue : Colors.green),
              child: Icon(
                user.role == 'ADMIN' ? Icons.admin_panel_settings : (user.role == 'OWNER' ? Icons.store : Icons.person),
                color: Colors.white,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isLocked)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'BỊ KHÓA 🔒',
                      style: TextStyle(color: Colors.red.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('📧 ${user.email}'),
                Text('📱 ${user.phone ?? "Không có"}'),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.role == 'ADMIN' ? Colors.red.shade100 : (user.role == 'OWNER' ? Colors.blue.shade100 : Colors.green.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role == 'ADMIN' ? 'Quản trị viên' : (user.role == 'OWNER' ? 'Chủ sân' : 'Người dùng'),
                    style: TextStyle(
                      color: user.role == 'ADMIN' ? Colors.red.shade700 : (user.role == 'OWNER' ? Colors.blue.shade700 : Colors.green.shade700),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _navigateToUserForm(user);
                    break;
                  case 'delete':
                    _deleteUser(user);
                    break;
                  case 'lock':
                    _toggleUserLock(user);
                    break;
                  case 'history':
                    final userBookings = _allBookings.where((b) => b['customer']?['email'] == user.email || b['customerId'] == user.id).toList();
                    _showBookingHistoryDialog(
                      title: 'Lịch sử đặt: ${user.name}',
                      bookings: userBookings,
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
                      Text('Quản lý & Đặt lại mật khẩu'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'lock',
                  child: Row(
                    children: [
                      Icon(isLocked ? Icons.lock_open : Icons.lock, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản'),
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
    );
  }

  Widget _buildOwnersSubTab() {
    final filtered = _filteredOwners;
    if (filtered.isEmpty) {
      return const Center(child: Text('Không tìm thấy chủ sân nào'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final owner = filtered[index];
        final id = owner['id'];
        final String name = owner['ownerName'] ?? '';
        final String email = owner['email'] ?? '';
        final String contact = owner['contactNumber'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.store, color: Colors.white),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('📧 $email'),
                Text('📱 $contact'),
                if (owner['bankName'] != null && owner['bankName'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('🏦 ${owner['bankName']} - ${owner['bankAccountNo']}'),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showAddEditOwnerDialog(owner);
                    break;
                  case 'delete':
                    _deleteOwner(id);
                    break;
                  case 'history':
                    final userBookings = _allBookings.where((b) => b['field']?['owner']?['email'] == email).toList();
                    _showBookingHistoryDialog(
                      title: 'Lịch sử đặt các sân của: $name',
                      bookings: userBookings,
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
                      Text('Chỉnh sửa thông tin'),
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
                      Text('Xóa chủ sân'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Sub tabs toggler
          Container(
            height: 44,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _subTab = 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _subTab == 0 ? Colors.purple : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Khách hàng",
                        style: TextStyle(
                          color: _subTab == 0 ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
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
                        color: _subTab == 1 ? Colors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Chủ sân",
                        style: TextStyle(
                          color: _subTab == 1 ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // User stats card
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
            child: Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Tổng người dùng: ${_users.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Chủ sân: ${_owners.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          // User / Owner List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: Colors.green,
                    child: _subTab == 0 ? _buildUsersSubTab() : _buildOwnersSubTab(),
                  ),
          ),
        ],
      ),
      floatingActionButton: _subTab == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditOwnerDialog(),
              backgroundColor: Colors.blue,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Thêm chủ sân', style: TextStyle(color: Colors.white)),
            )
          : FloatingActionButton.extended(
              onPressed: () async {
                // Add user dialog
                await _showAddUserDialog();
              },
              backgroundColor: Colors.purple,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Thêm người dùng', style: TextStyle(color: Colors.white)),
            ),
    );
  }

  Future<void> _showAddUserDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'USER';
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm người dùng mới'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập email' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  validator: (val) => val == null || val.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'USER', child: Text('Người dùng')),
                    DropdownMenuItem(value: 'OWNER', child: Text('Chủ sân')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedRole = val;
                  },
                  decoration: const InputDecoration(labelText: 'Vai trò'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                setState(() => _isLoading = true);

                final res = await ApiClient.post(
                  '/api/users/register',
                  body: jsonEncode({
                    "name": nameController.text.trim(),
                    "email": emailController.text.trim(),
                    "phone": phoneController.text.trim(),
                    "password": passwordController.text,
                    "role": selectedRole,
                  }),
                );

                if (res.statusCode == 200 || res.statusCode == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tạo người dùng mới thành công'), backgroundColor: Colors.green),
                  );
                  await _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể tạo người dùng mới. Email có thể đã tồn tại.'), backgroundColor: Colors.red),
                  );
                  if (mounted) setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}
