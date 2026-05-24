import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'booking_history_screen.dart';
import 'user_messages_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import '../services/api_service.dart';
import '../main.dart'; // Import để sử dụng routeObserver

class MainTabScaffold extends StatefulWidget {
  final int initialIndex;
  const MainTabScaffold({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> with WidgetsBindingObserver, RouteAware {
  late int _currentIndex;
  int _newNotificationCount = 0;
  int _unreadMessageCount = 0;
  List<int> _seenNotificationIds = [];
  Timer? _pollingTimer;
  
  final List<Widget> _screens = [
    HomeScreen(),
    BookingHistoryScreen(),
    UserMessagesScreen(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
    _loadSeenNotifications();
    _fetchUnreadMessageCount();
    _startPolling();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Đăng ký với RouteObserver
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Polling để cập nhật tin nhắn tự động (mỗi 2 giây)
  void _startPolling() {
    _pollingTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted) {
        _fetchUnreadMessageCount();
        _fetchNewNotificationCount();
      }
    });
  }

  // Được gọi khi một route được pop và màn hình này trở nên visible lại
  @override
  void didPopNext() {
    super.didPopNext();
    // Refresh counts khi back từ màn hình khác
    _fetchNewNotificationCount();
    _fetchUnreadMessageCount();
  }

  // Khi app quay lại foreground, refresh counts
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchNewNotificationCount();
      _fetchUnreadMessageCount();
    }
  }

  // Load danh sách ID thông báo đã xem từ SharedPreferences
  Future<void> _loadSeenNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final seenIds = prefs.getStringList('seen_notification_ids') ?? [];
    _seenNotificationIds = seenIds.map((id) => int.parse(id)).toList();
    await _fetchNewNotificationCount();
  }

  // Lưu danh sách ID thông báo đã xem vào SharedPreferences
  Future<void> _saveSeenNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'seen_notification_ids',
      _seenNotificationIds.map((id) => id.toString()).toList(),
    );
  }

  // Đếm số thông báo MỚI (chưa có trong danh sách đã xem)
  Future<void> _fetchNewNotificationCount() async {
    try {
      final notis = await ApiService.getNotifications();
      final newCount = notis.where((n) {
        final id = n['id'];
        return id != null && !_seenNotificationIds.contains(id);
      }).length;
      
      if (mounted) {
        setState(() {
          _newNotificationCount = newCount;
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  // Đếm số tin nhắn chưa đọc
  Future<void> _fetchUnreadMessageCount() async {
    try {
      final profile = await ApiService.getProfile();
      if (profile != null && profile.id != null) {
        final conversations = await ApiService.getConversationsForUser(profile.id!);
        int totalUnread = 0;
        for (var conv in conversations) {
          totalUnread += (conv['unreadCount'] ?? 0) as int;
        }
        if (mounted) {
          setState(() {
            _unreadMessageCount = totalUnread;
          });
        }
      }
    } catch (e) {
      print('Error fetching unread messages: $e');
    }
  }

  // Đánh dấu tất cả thông báo hiện tại là "đã xem"
  Future<void> _markAllAsSeen() async {
    final notis = await ApiService.getNotifications();
    for (var n in notis) {
      final id = n['id'];
      if (id != null && !_seenNotificationIds.contains(id)) {
        _seenNotificationIds.add(id);
      }
    }
    await _saveSeenNotifications();
    if (mounted) {
      setState(() {
        _newNotificationCount = 0;
      });
    }
  }

  void _onTabTapped(int index) async {
    if (index == _currentIndex) {
      // Nếu đang ở tab hiện tại, refresh counts
      await _fetchNewNotificationCount();
      await _fetchUnreadMessageCount();
      return;
    }
    setState(() => _currentIndex = index);
    // Xử lý theo tab
    if (index == 2) {
      // Tab tin nhắn - refresh message count
      await _fetchUnreadMessageCount();
    } else if (index == 3) {
      // Tab thông báo - đánh dấu đã xem
      await _markAllAsSeen();
    } else {
      // Refresh counts khi chuyển tab khác
      await _fetchNewNotificationCount();
      await _fetchUnreadMessageCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyedSubtree(
        key: ValueKey(_currentIndex),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        onTap: _onTabTapped,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Lịch sử đặt'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.chat_bubble),
                if (_unreadMessageCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _unreadMessageCount > 99 ? '99+' : '$_unreadMessageCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Tin nhắn',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_newNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _newNotificationCount > 99 ? '99+' : '$_newNotificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Thông báo',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}
