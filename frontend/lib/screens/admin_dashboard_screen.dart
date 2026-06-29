import 'package:flutter/material.dart';
import '../models/field.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'admin_add_edit_field_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Field> stadiums = [];
  List<User> users = [];
  bool isLoading = true;
  String searchQuery = '';
  int _currentIndex = 0; // Thêm biến để theo dõi tab hiện tại

  double totalPlatformHeld = 0.0;
  List<dynamic> allBookings = [];
  bool isRevenueLoading = false;

  int _revenueSubTab = 0; // 0: Đối soát chủ sân, 1: Lịch sử cọc
  List<dynamic> ownersRevenue = [];
  bool isOwnersLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStadiums();
    _loadUsers();
    _loadRevenue();
    _loadOwnersRevenue();
  }

  Future<void> _loadStadiums() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getAllStadiums();
      setState(() {
        stadiums = data.reversed.toList(); // Đảo ngược danh sách
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Lỗi khi tải danh sách sân: $e');
    }
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getAllUsers();
      setState(() {
        users = data.reversed.toList(); // Đảo ngược danh sách
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Lỗi khi tải danh sách người dùng: $e');
    }
  }

  Future<void> _loadRevenue() async {
    setState(() => isRevenueLoading = true);
    try {
      final data = await ApiService.getAdminRevenue();
      setState(() {
        totalPlatformHeld = (data['totalPlatformHeld'] as num?)?.toDouble() ?? 0.0;
        allBookings = data['bookings'] ?? [];
        allBookings.sort((a, b) {
          final aOwner = a['field']?['owner']?['ownerName']?.toString() ?? 'Chủ sân';
          final bOwner = b['field']?['owner']?['ownerName']?.toString() ?? 'Chủ sân';
          final ownerCompare = aOwner.compareTo(bOwner);
          if (ownerCompare != 0) return ownerCompare;

          final aTime = a['createdAt'] != null ? DateTime.parse(a['createdAt']) : DateTime.now();
          final bTime = b['createdAt'] != null ? DateTime.parse(b['createdAt']) : DateTime.now();
          return bTime.compareTo(aTime);
        });
        isRevenueLoading = false;
      });
    } catch (e) {
      setState(() => isRevenueLoading = false);
      _showErrorSnackBar('Lỗi khi tải doanh thu cọc: $e');
    }
  }

  Future<void> _loadOwnersRevenue() async {
    setState(() => isOwnersLoading = true);
    try {
      final data = await ApiService.getAdminOwnersRevenue();
      setState(() {
        ownersRevenue = data;
        isOwnersLoading = false;
      });
    } catch (e) {
      setState(() => isOwnersLoading = false);
      _showErrorSnackBar('Lỗi khi tải doanh thu chủ sân: $e');
    }
  }

  Future<void> _settleOwner(int ownerId, String ownerName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Text('Bạn có chắc chắn muốn đánh dấu đã đối soát & thanh toán cho chủ sân "$ownerName"? Việc này sẽ thiết lập số tiền giữ hộ hiện tại về 0đ và lưu vào lịch sử sao kê.'),
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
      setState(() => isLoading = true);
      try {
        final success = await ApiService.settleOwner(ownerId);
        if (success) {
          _showSuccessSnackBar('Thanh toán đối soát thành công cho chủ sân $ownerName!');
          await _loadRevenue();
          await _loadOwnersRevenue();
        } else {
          _showErrorSnackBar('Thanh toán đối soát thất bại!');
        }
      } catch (e) {
        _showErrorSnackBar('Lỗi khi đối soát: $e');
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  List<Field> get filteredStadiums {
    if (searchQuery.isEmpty) return stadiums;
    return stadiums.where((stadium) =>
        stadium.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        stadium.address.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  List<User> get filteredUsers {
    if (searchQuery.isEmpty) return users;
    return users.where((user) =>
        user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        user.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
        (user.phone?.contains(searchQuery) ?? false)
    ).toList();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
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
      try {
        final success = await ApiService.adminDeleteField(stadium.id!);
        if (success) {
          _showSuccessSnackBar('Xóa sân thành công');
          _loadStadiums();
        } else {
          _showErrorSnackBar('Không thể xóa sân');
        }
      } catch (e) {
        _showErrorSnackBar('Lỗi khi xóa sân: $e');
      }
    }
  }

  Future<void> _deleteUser(User user) async {
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

    if (confirm == true && user.id != null) {
      try {
        final success = await ApiService.adminDeleteUser(user.id!);
        if (success) {
          _showSuccessSnackBar('Xóa người dùng thành công');
          _loadUsers();
        } else {
          _showErrorSnackBar('Không thể xóa người dùng');
        }
      } catch (e) {
        _showErrorSnackBar('Lỗi khi xóa người dùng: $e');
      }
    }
  }

  Future<void> _navigateToForm([Field? stadium]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminAddEditFieldScreen(),
        settings: RouteSettings(arguments: stadium),
      ),
    );
    if (result == true) {
      _loadStadiums();
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
      _loadUsers();
    }
  }

  Future<void> _showEditUserDialog(User user) async {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone ?? '');
    String selectedRole = user.role ?? 'USER';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chỉnh sửa người dùng: ${user.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Vai trò',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'USER', child: Text('Người dùng')),
                  DropdownMenuItem(value: 'OWNER', child: Text('Chủ sân')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên')),
                ],
                onChanged: (value) {
                  selectedRole = value ?? 'USER';
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final success = await ApiService.adminUpdateUser(user.id!, {
                  'name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text.isEmpty ? null : phoneController.text,
                  'role': selectedRole,
                });
                if (success) {
                  _showSuccessSnackBar('Cập nhật thông tin người dùng thành công');
                  Navigator.pop(context);
                } else {
                  _showErrorSnackBar('Không thể cập nhật thông tin người dùng');
                }
              } catch (e) {
                _showErrorSnackBar('Lỗi: $e');
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
                try {
                  final success = await ApiService.adminResetUserPassword(
                    user.id!,
                    passwordController.text,
                  );
                  if (success) {
                    _showSuccessSnackBar('Đặt lại mật khẩu thành công');
                    Navigator.pop(context, passwordController.text);
                  } else {
                    _showErrorSnackBar('Không thể đặt lại mật khẩu');
                  }
                } catch (e) {
                  _showErrorSnackBar('Lỗi: $e');
                }
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  // Thêm hàm để hiển thị dialog tạo người dùng mới
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
                  decoration: const InputDecoration(
                    labelText: 'Tên *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu *',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Vai trò',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'USER', child: Text('Người dùng')),
                    DropdownMenuItem(value: 'OWNER', child: Text('Chủ sân')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên')),
                  ],
                  onChanged: (value) {
                    selectedRole = value ?? 'USER';
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final userData = {
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'password': passwordController.text,
                    'role': selectedRole,
                  };

                  if (phoneController.text.trim().isNotEmpty) {
                    userData['phone'] = phoneController.text.trim();
                  }

                  final success = await ApiService.register(userData);
                  if (success) {
                    _showSuccessSnackBar('Tạo người dùng mới thành công');
                    Navigator.pop(context);
                    _loadUsers(); // Tải lại danh sách người dùng
                  } else {
                    _showErrorSnackBar('Không thể tạo người dùng mới');
                  }
                } catch (e) {
                  _showErrorSnackBar('Lỗi: $e');
                }
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  // Hàm để xây dựng nội dung cho từng tab
  Widget _buildStadiumsTab() {
    return Column(
      children: [
        // Statistics cards
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.blue.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.sports_soccer, color: Colors.blue, size: 30),
                        const SizedBox(height: 8),
                        Text(
                          '${stadiums.length}',
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
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 30),
                        const SizedBox(height: 8),
                        Text(
                          '${stadiums.where((s) => s.available == true).length}',
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
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredStadiums.isEmpty
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
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredStadiums.length,
                      itemBuilder: (context, index) {
                        final stadium = filteredStadiums[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: stadium.available == true
                                  ? Colors.green
                                  : Colors.red,
                              child: Icon(
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
                                // Thêm thông tin chủ sân
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
                                    Icon(Icons.attach_money, size: 16, color: Colors.green),
                                    Text(
                                      '${stadium.pricePerHour.toStringAsFixed(0)}K VNĐ/giờ',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    if (stadium.rating != null) ...[
                                      Icon(Icons.star, size: 16, color: Colors.amber),
                                      Text('${stadium.rating!.toStringAsFixed(1)}'),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: stadium.available == true
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    stadium.available == true ? 'Hoạt động' : 'Ngừng hoạt động',
                                    style: TextStyle(
                                      color: stadium.available == true
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      fontSize: 12,
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
                                    _navigateToForm(stadium);
                                    break;
                                  case 'delete':
                                    _deleteStadium(stadium);
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
      ],
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // User statistics card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Colors.purple.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.people, color: Colors.purple, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        '${users.length}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text('Tổng người dùng'),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.admin_panel_settings, color: Colors.orange, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        '${users.where((u) => u.role == 'ADMIN').length}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text('Quản trị viên'),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.store, color: Colors.blue, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        '${users.where((u) => u.role == 'OWNER').length}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text('Chủ sân'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // User list
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredUsers.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Không có người dùng nào',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: user.role == 'ADMIN'
                                  ? Colors.red
                                  : user.role == 'OWNER'
                                      ? Colors.blue
                                      : Colors.green,
                              child: Icon(
                                user.role == 'ADMIN'
                                    ? Icons.admin_panel_settings
                                    : user.role == 'OWNER'
                                        ? Icons.store
                                        : Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('📧 ${user.email}'),
                                Text('📱 ${user.phone ?? "Không có"}'),
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: user.role == 'ADMIN'
                                        ? Colors.red.shade100
                                        : user.role == 'OWNER'
                                            ? Colors.blue.shade100
                                            : Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user.role == 'ADMIN'
                                        ? 'Quản trị viên'
                                        : user.role == 'OWNER'
                                            ? 'Chủ sân'
                                            : 'Người dùng',
                                    style: TextStyle(
                                      color: user.role == 'ADMIN'
                                          ? Colors.red.shade700
                                          : user.role == 'OWNER'
                                              ? Colors.blue.shade700
                                              : Colors.green.shade700,
                                      fontSize: 12,
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
      ],
    );
  }

  List<dynamic> get filteredBookings {
    if (searchQuery.isEmpty) return allBookings;
    return allBookings.where((booking) {
      final fieldName = booking['field']?['name']?.toString()?.toLowerCase() ?? '';
      final ownerName = booking['field']?['owner']?['ownerName']?.toString()?.toLowerCase() ?? '';
      final customerName = (booking['customerName'] ?? booking['customer']?['name'])?.toString()?.toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();
      return fieldName.contains(query) || ownerName.contains(query) || customerName.contains(query);
    }).toList();
  }

  Widget _buildRevenueTab() {
    if (isRevenueLoading || isOwnersLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    final bookingsList = filteredBookings;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadRevenue();
        await _loadOwnersRevenue();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.teal.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TỔNG TIỀN CỌC GIỮ HỘ',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                    const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _formatMoney(totalPlatformHeld),
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Đây là tổng số tiền cọc thanh toán qua cổng VietQR trung gian đang được hệ thống giữ bảo đảm và CHƯA đối soát chuyển cho chủ sân.',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
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
          _revenueSubTab == 0 ? _buildOwnersRevenueList() : _buildBookingsHistoryList(bookingsList),
        ],
      ),
    );
  }

  Widget _buildOwnersRevenueList() {
    if (ownersRevenue.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('Không có chủ sân nào')),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ownersRevenue.length,
      itemBuilder: (context, index) {
        final item = ownersRevenue[index];
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Email: $email', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                if (phone.isNotEmpty)
                  Text('SĐT: $phone', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cọc chưa đối soát:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    Text(
                      _formatMoney(unsettledAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: unsettledAmount > 0 ? Colors.orange.shade800 : Colors.green,
                        fontSize: 15,
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
                  tooltip: bankAccountNo.isEmpty
                      ? "Chưa cấu hình tài khoản ngân hàng"
                      : "Xem tài khoản ngân hàng",
                  onPressed: () {
                    if (bankAccountNo.isEmpty) {
                      _showErrorSnackBar("Chủ sân chưa cấu hình tài khoản nhận tiền!");
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
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tài khoản ngân hàng nhận tiền:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                    ),
                    const SizedBox(height: 6),
                    bankAccountNo.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              '⚠️ Chủ sân chưa cấu hình tài khoản nhận tiền.',
                              style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500),
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                _buildBankDetailRow("Ngân hàng:", bankName),
                                _buildBankDetailRow("Số tài khoản:", bankAccountNo),
                                _buildBankDetailRow("Chủ tài khoản:", bankAccountName),
                              ],
                            ),
                          ),
                    const Divider(height: 16),
                    const Text(
                      'Lịch sử sao kê & chuyển tiền:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    settlements.isEmpty
                        ? const Text('Chưa có lịch sử đối soát nào.', style: TextStyle(fontSize: 12, color: Colors.grey))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: settlements.length,
                            itemBuilder: (context, sIndex) {
                              final settlement = settlements[sIndex];
                              final double amount = (settlement['amount'] as num?)?.toDouble() ?? 0.0;
                              final settledAtStr = settlement['settledAt'] != null 
                                  ? DateTime.parse(settlement['settledAt']).toLocal().toString().substring(0, 19)
                                  : '';
                              final bookingIds = settlement['bookingIds'] ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Chuyển khoản: ${_formatMoney(amount)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                        ),
                                        Text(
                                          settledAtStr,
                                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Mã đơn đối soát: $bookingIds',
                                      style: const TextStyle(fontSize: 11, color: Colors.black38),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingsHistoryList(List<dynamic> bookingsList) {
    if (ownersRevenue.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('Không có chủ sân nào')),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ownersRevenue.length,
      itemBuilder: (context, index) {
        final ownerItem = ownersRevenue[index];
        final int ownerId = ownerItem['ownerId'];
        final String ownerName = ownerItem['ownerName'] ?? 'Chủ sân';
        
        final ownerBookings = bookingsList.where((b) {
          final bOwnerId = b['field']?['owner']?['id'];
          return bOwnerId == ownerId;
        }).toList();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: const Icon(Icons.sports_soccer, color: Colors.green),
            title: Text(
              ownerName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'Tổng số lượt đặt sân: ${ownerBookings.length} lượt',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            children: [
              const Divider(height: 1),
              ownerBookings.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Chủ sân này chưa có lượt đặt nào.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ownerBookings.length,
                      itemBuilder: (context, bIndex) {
                        final booking = ownerBookings[bIndex];
                        final fieldName = booking['field']?['name'] ?? 'Sân bóng';
                        final customerName = booking['customerName'] ?? booking['customer']?['name'] ?? 'Khách ẩn';
                        final double deposit = (booking['totalPrice'] as num?)?.toDouble() ?? 0.0;
                        final status = booking['status'] ?? 'PENDING_PAYMENT';
                        final bool settled = booking['settled'] ?? false;
                        
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

                        Color statusColor = Colors.orange;
                        String statusText = "Chờ cọc";
                        if (status == 'APPROVED') {
                          statusColor = Colors.green;
                          statusText = settled ? "Đã đối soát" : "Thành công";
                        } else if (status == 'CANCELLED') {
                          statusColor = Colors.red;
                          statusText = settled ? "Đã đối soát (Hủy cọc)" : "Đã hủy";
                        } else if (status == 'EXPIRED') {
                          statusColor = Colors.grey;
                          statusText = "Hết hạn";
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      fieldName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (settled ? Colors.blue : statusColor).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(color: settled ? Colors.blue : statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 12),
                              _buildInfoRow('Khách đặt:', customerName),
                              if (fromTime != null && toTime != null)
                                _buildInfoRow(
                                  'Khung giờ:',
                                  '${fromTime.hour}:00 - ${toTime.hour}:00 ngày ${fromTime.day}/${fromTime.month}',
                                ),
                              if (createdAt != null)
                                _buildInfoRow(
                                  'Thời gian đặt:',
                                  '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')} ngày ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tiền cọc giữ hộ:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                  Text(
                                    _formatMoney(deposit),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: status == 'APPROVED' ? Colors.green.shade700 : Colors.black87,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Thu offline tại sân:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                  Text(
                                    _formatMoney(remaining > 0 ? remaining : 0.0),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBankDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }

  String _formatMoney(double amount) {
    return amount.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    ) + 'đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Quản lý sân bóng' : _currentIndex == 1 ? 'Quản lý người dùng' : 'Ví trung gian & Tổng cọc'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadStadiums();
              _loadUsers();
              _loadRevenue();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ApiService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: _currentIndex == 0 
                    ? 'Tìm kiếm sân bóng...' 
                    : _currentIndex == 1 
                        ? 'Tìm kiếm người dùng...' 
                        : 'Tìm kiếm giao dịch cọc...',
                prefixIcon: Icon(_currentIndex == 0 
                    ? Icons.sports_soccer 
                    : _currentIndex == 1 
                        ? Icons.people 
                        : Icons.account_balance_wallet),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
          ),
          // Content based on selected tab
          Expanded(
            child: _currentIndex == 0 
                ? _buildStadiumsTab() 
                : _currentIndex == 1 
                    ? _buildUsersTab() 
                    : _buildRevenueTab(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            searchQuery = ''; // Reset search khi chuyển tab
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        iconSize: 28,
        elevation: 8,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            activeIcon: Icon(Icons.sports_soccer, size: 32),
            label: 'Quản lý sân',
            tooltip: 'Quản lý sân bóng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            activeIcon: Icon(Icons.people, size: 32),
            label: 'Người dùng',
            tooltip: 'Quản lý người dùng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            activeIcon: Icon(Icons.account_balance_wallet, size: 32),
            label: 'Ví trung gian',
            tooltip: 'Quản lý tiền cọc giữ hộ',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm sân', style: TextStyle(color: Colors.white)),
      ) : _currentIndex == 1 ? FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm người dùng', style: TextStyle(color: Colors.white)),
      ) : null,
    );
  }
}
