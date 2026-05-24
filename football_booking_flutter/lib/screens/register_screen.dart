import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController    = TextEditingController();
  final TextEditingController emailController   = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController    = TextEditingController();
  bool isLoading = false;
  String selectedRole = 'USER';

  void register() async {
    setState(() {
      isLoading = true;
    });
    bool success = await ApiService.register({
      'name': nameController.text,
      'email': emailController.text,
      'password': passwordController.text,
      'phone': phoneController.text,
      'role': selectedRole,
    });
    setState(() {
      isLoading = false;
    });
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng ký thành công!')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng ký thất bại!')),
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
                  "Đăng ký",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Colors.amber[800],
                  ),
                ),
                SizedBox(height: 32),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Họ và tên",
                    prefixIcon: Icon(Icons.person_outline, color: Colors.amber[700]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.amber[50],
                  ),
                ),
                SizedBox(height: 20),
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
                SizedBox(height: 20),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: "Số điện thoại",
                    prefixIcon: Icon(Icons.phone_outlined, color: Colors.amber[700]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.amber[50],
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 20),
                // Role selection
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Vai trò",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.amber[800]),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'USER',
                        groupValue: selectedRole,
                        onChanged: (val) {
                          setState(() => selectedRole = val!);
                        },
                        title: Text('Người dùng', style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.w500, fontSize: 14), overflow: TextOverflow.ellipsis),
                        activeColor: Colors.amber,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'OWNER',
                        groupValue: selectedRole,
                        onChanged: (val) {
                          setState(() => selectedRole = val!);
                        },
                        title: Text('Chủ sân', style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.w500, fontSize: 14), overflow: TextOverflow.ellipsis),
                        activeColor: Colors.amber,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                isLoading
                    ? CircularProgressIndicator(color: Colors.amber)
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          child: Text("Đăng ký"),
                        ),
                      ),
                SizedBox(height: 18),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text(
                    "Đã có tài khoản? Đăng nhập",
                    style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.w500),
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
