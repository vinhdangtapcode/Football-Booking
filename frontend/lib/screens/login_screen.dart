import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../services/push_notification_service.dart';
import '../services/theme_service.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isGoogleLoading = false;

  void login() async {
    setState(() {
      isLoading = true;
    });
    final token = await ApiService.login(emailController.text, passwordController.text);
    if (token != null) {
      // Gửi FCM token lên backend sau khi đăng nhập
      await PushNotificationService.sendTokenToBackend();
      
      final user = await ApiService.getProfile();
      setState(() {
        isLoading = false;
      });
      if (user != null && user.role == 'ADMIN') {
        Navigator.pushNamedAndRemoveUntil(context, '/adminDashboard', (route) => false);
      } else if (user != null && user.role == 'OWNER') {
        Navigator.pushNamedAndRemoveUntil(context, '/ownerMain', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập thất bại! Vui lòng kiểm tra lại email và mật khẩu.')),
      );
    }
  }

  /// Handle Google Sign-In
  void loginWithGoogle() async {
    setState(() {
      isGoogleLoading = true;
    });

    try {
      final token = await GoogleAuthService.signInWithGoogle();
      
      if (token != null) {
        // Set token in ApiService
        ApiService.setToken(token);
        
        // Get user profile first to get role
        final user = await ApiService.getProfile();
        
        if (user != null) {
          // Lưu token vào SharedPreferences để tự động đăng nhập
          await ApiService.saveToken(token, user.role);
          
          // Gửi FCM token lên backend sau khi đăng nhập
          await PushNotificationService.sendTokenToBackend();
          
          setState(() {
            isGoogleLoading = false;
          });

          if (user.role == 'ADMIN') {
            Navigator.pushNamedAndRemoveUntil(context, '/adminDashboard', (route) => false);
          } else if (user.role == 'OWNER') {
            Navigator.pushNamedAndRemoveUntil(context, '/ownerMain', (route) => false);
          } else {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          }
        } else {
          setState(() {
            isGoogleLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể lấy thông tin người dùng.')),
          );
        }
      } else {
        setState(() {
          isGoogleLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng nhập Google thất bại hoặc đã bị hủy.')),
        );
      }
    } catch (e) {
      setState(() {
        isGoogleLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng nhập Google: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = themeProvider.isModernMode;

    return Scaffold(
      backgroundColor: isModern ? Colors.black : Colors.amber,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: isModern ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isModern ? null : [
                  BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
                ],
                border: isModern ? Border.all(color: Colors.white24) : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isModern)
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.amber[100],
                      child: Icon(Icons.sports_soccer, size: 50, color: Colors.amber[800]),
                    ),
                  if (isModern)
                    Icon(Icons.sports_soccer, size: 60, color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    "ĐĂNG NHẬP",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isModern ? Colors.white : Colors.amber[800],
                      letterSpacing: isModern ? 2 : null,
                    ),
                  ),
                  SizedBox(height: 32),
                  TextField(
                    controller: emailController,
                    style: TextStyle(color: isModern ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                      prefixIcon: Icon(Icons.email_outlined, color: isModern ? Colors.white : Colors.amber[700]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: isModern ? Color(0xFF1A1A1A) : Colors.amber[50],
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: isModern ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                      prefixIcon: Icon(Icons.lock_outline, color: isModern ? Colors.white : Colors.amber[700]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: isModern ? Color(0xFF1A1A1A) : Colors.amber[50],
                    ),
                  ),
                  SizedBox(height: 32),
                  isLoading
                      ? CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber)
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isModern ? Colors.white : Colors.amber,
                              foregroundColor: isModern ? Colors.black : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            child: Text("Đăng nhập"),
                          ),
                        ),
                  SizedBox(height: 18),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: Text(
                      "Chưa có tài khoản? Đăng ký",
                      style: TextStyle(color: isModern ? Colors.white70 : Colors.amber[800], fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(height: 32),
                  // Google style divider
                  Row(
                    children: [
                      Expanded(child: Divider(thickness: 1, color: isModern ? Colors.white12 : Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text("hoặc", style: TextStyle(color: isModern ? Colors.white54 : Colors.grey[600])),
                      ),
                      Expanded(child: Divider(thickness: 1, color: isModern ? Colors.white12 : Colors.grey[300])),
                    ],
                  ),
                  SizedBox(height: 24),
                  // Google Sign-In button with loading state
                  isGoogleLoading
                      ? CircularProgressIndicator(color: isModern ? Colors.white : Colors.blue)
                      : SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: loginWithGoogle,
                            icon: Image.asset('lib/assets/images/google_logo.webp', height: 24),
                            label: Text(
                              "Đăng nhập với Google",
                              style: TextStyle(color: isModern ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: isModern ? Colors.white24 : Colors.grey[300]!),
                              backgroundColor: isModern ? Colors.black : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
