import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/push_notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 1. Khởi tạo hiệu ứng Fade-in cho Logo
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // 2. Chạy logic kiểm tra login (đảm bảo ít nhất 3 giây)
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Tạo future đợi 2 giây để đảm bảo thời gian hiển thị splash screen tối thiểu
    final waitFuture = Future.delayed(const Duration(seconds: 2));

    print('SplashScreen: Checking login status...');
    
    // Mặc định route là login
    String route = '/login';
    
    // Biến tạm để xử lý logic notification
    bool openedFromNotification = PushNotificationService.openedFromNotification;
    
    // Load token từ SharedPreferences
    final hasToken = await ApiService.loadSavedToken();
    print('SplashScreen: Has saved token = $hasToken');
    
    if (hasToken) {
      try {
        print('SplashScreen: Verifying token with getProfile...');
        final user = await ApiService.getProfile();
        print('SplashScreen: getProfile result = $user');
        
        if (user != null) {
           print('SplashScreen: User authenticated, role = ${user.role}');
           // Token hợp lệ, gửi FCM token
           await PushNotificationService.sendTokenToBackend();
           
           // Quyết định route dựa trên notification flag và role
           if (openedFromNotification) {
             PushNotificationService.openedFromNotification = false; // Reset flag
             route = user.role == 'OWNER' ? '/ownerNotifications' : '/notifications';
             print('SplashScreen: Opened from notification, navigating to $route');
           } else {
             // Bình thường, đi đến màn hình chính
             if (user.role == 'ADMIN') {
               route = '/adminDashboard';
             } else if (user.role == 'OWNER') {
               route = '/ownerMain';
             } else {
               route = '/home';
             }
           }
        } else {
          print('SplashScreen: User is null, clearing token');
          await ApiService.clearToken();
          PushNotificationService.openedFromNotification = false;
        }
      } catch (e) {
        print('SplashScreen: Token validation failed: $e');
        await ApiService.clearToken();
        PushNotificationService.openedFromNotification = false;
      }
    } else {
      // Không có token
      PushNotificationService.openedFromNotification = false;
    }

    // Đợi cho đủ 2 giây (nếu logic xử lý nhanh hơn 2s)
    await waitFuture;

    if (!mounted) return;

    print('SplashScreen: Navigating to $route');
    // Navigate và xóa stack splash screen
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo với hiệu ứng Fade-in
              FadeTransition(
                opacity: _animation,
                child: Image.asset(
                  'lib/assets/images/logo.png', // Đường dẫn ảnh logo
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon nếu không tìm thấy ảnh
                    return const Icon(Icons.sports_soccer, size: 100, color: Color(0xFF1B5E20));
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Tên ứng dụng
              const Text(
                "ĐẶT SÂN NHANH",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20), // Màu xanh lá đậm
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                "Dễ dàng - Nhanh chóng - Tiện lợi",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          // Thanh Loading ở phía dưới
          Positioned(
            bottom: 50,
            left: 50,
            right: 50,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
                    backgroundColor: Colors.white24,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
