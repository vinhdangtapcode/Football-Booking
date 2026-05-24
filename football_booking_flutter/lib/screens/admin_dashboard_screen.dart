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

  @override
  void initState() {
    super.initState();
    _loadStadiums();
    _loadUsers();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Quản lý sân bóng' : 'Quản lý người dùng'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadStadiums();
              _loadUsers();
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
                hintText: _currentIndex == 0 ? 'Tìm kiếm sân bóng...' : 'Tìm kiếm người dùng...',
                prefixIcon: Icon(_currentIndex == 0 ? Icons.sports_soccer : Icons.people),
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
            child: _currentIndex == 0 ? _buildStadiumsTab() : _buildUsersTab(),
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
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm sân', style: TextStyle(color: Colors.white)),
      ) : FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm người dùng', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
