import 'package:flutter/material.dart';
import '../../auth/repositories/auth_repository.dart';
import '../tabs/admin_overview_tab.dart';
import '../tabs/admin_stadiums_tab.dart';
import '../tabs/admin_bookings_tab.dart';
import '../tabs/admin_users_tab.dart';
import '../tabs/admin_revenue_tab.dart';
import '../tabs/admin_system_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _titles = [
    'Tổng quan hệ thống',
    'Quản lý sân bóng',
    'Quản lý người dùng',
    'Lịch đặt sân toàn cục',
    'Ví cọc & Đối soát',
    'Cấu hình & Hệ thống',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Quản trị viên?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await AuthRepository.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Conditionally render Search Bar for Stadiums (1) and Users (2)
          if (_currentIndex == 1 || _currentIndex == 2)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 4.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _currentIndex == 1 ? 'Tìm kiếm sân bóng...' : 'Tìm kiếm người dùng...',
                  prefixIcon: Icon(_currentIndex == 1 ? Icons.sports_soccer : Icons.people),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                const AdminOverviewTab(),
                AdminStadiumsTab(searchQuery: _searchQuery),
                AdminUsersTab(searchQuery: _searchQuery),
                AdminBookingsTab(searchQuery: _searchQuery),
                const AdminRevenueTab(),
                const AdminSystemTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Sân bóng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Người dùng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Lịch đặt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet),
            label: 'Ví cọc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Hệ thống',
          ),
        ],
      ),
    );
  }
}
