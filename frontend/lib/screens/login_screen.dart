import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../services/push_notification_service.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 32),
                Icon(Icons.sports_soccer, color: Colors.amber, size: 64),
                SizedBox(height: 16),
                Text(
                  "Đăng nhập",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Colors.amber[800],
                  ),
                ),
                SizedBox(height: 32),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.amber[700]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.amber[50],
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Mật khẩu",
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.amber[700]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.amber[50],
                  ),
                ),
                SizedBox(height: 32),
                isLoading
                    ? CircularProgressIndicator(color: Colors.amber)
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                    style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(height: 32),
                // Google style divider
                Row(
                  children: [
                    Expanded(child: Divider(thickness: 1, color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("hoặc", style: TextStyle(color: Colors.grey[600])),
                    ),
                    Expanded(child: Divider(thickness: 1, color: Colors.grey[300])),
                  ],
                ),
                SizedBox(height: 24),
                // Google Sign-In button with loading state
                isGoogleLoading
                    ? CircularProgressIndicator(color: Colors.blue)
                    : SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: loginWithGoogle,
                          icon: Image.asset('lib/assets/images/google_logo.webp', height: 24),
                          label: Text(
                            "Đăng nhập với Google",
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
