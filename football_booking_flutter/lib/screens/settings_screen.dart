import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_booking_flutter/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final profile = await ApiService.getProfile();
    setState(() {
      user = profile;
      isLoading = false;
    });
  }

  void _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label đã được sao chép!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text("Cài đặt"),
        backgroundColor: Colors.amberAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.amber))
          : user == null
              ? Center(child: Text("Không thể tải thông tin người dùng."))
              : ListView(
                  children: [
                    // Header
                    Container(
                      color: Colors.amberAccent,
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Text(
                              user!.name.isNotEmpty ? user!.name[0] : "",
                              style: TextStyle(fontSize: 40, color: Colors.black),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            user!.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            user!.email,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sửa thông tin
                    ListTile(
                      leading: Icon(Icons.edit, color: Colors.amberAccent),
                      title: Text("Sửa thông tin"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(editMode: true),
                          ),
                        );
                      },
                    ),
                    // Sân yêu thích
                    ListTile(
                      leading: Icon(Icons.favorite, color: Colors.redAccent),
                      title: Text("Sân yêu thích"),
                      onTap: () {
                        Navigator.pushNamed(context, '/favorites');
                      },
                    ),
                    // Về chúng tôi
                    ListTile(
                      leading: Icon(Icons.info, color: Colors.blueAccent),
                      title: Text("Về chúng tôi"),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Center(child: Text("Về chúng tôi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sports_soccer, color: Colors.amber, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  "Ứng dụng đặt sân bóng đá tiện lợi, nhanh chóng và hiện đại.\n\nLiên hệ: dovinhhp102@gmail.com\nSĐT: 0984981822",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            actions: [
                              Center(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                            actionsAlignment: MainAxisAlignment.center,
                          ),
                        );
                      },
                    ),
                    // Email chủ app
                    ListTile(
                      leading: Icon(Icons.email, color: Colors.amberAccent),
                      title: Text("dovinhhp102@gmail.com"),
                      onTap: () => _copyToClipboard("dovinhhp102@gmail.com", "Email"),
                    ),
                    // Số điện thoại chủ app
                    ListTile(
                      leading: Icon(Icons.phone, color: Colors.amberAccent),
                      title: Text("0984981822"),
                      onTap: () => _copyToClipboard("0984981822", "Số điện thoại"),
                    ),
                    // Đổi mật khẩu
                    ListTile(
                      leading: Icon(Icons.lock, color: Colors.deepPurple),
                      title: Text("Đổi mật khẩu"),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            final oldPassController = TextEditingController();
                            final newPassController = TextEditingController();
                            final confirmPassController = TextEditingController();
                            final formKey = GlobalKey<FormState>();
                            bool isLoading = false;
                            String? errorMsg;
                            return StatefulBuilder(
                              builder: (context, setState) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Center(child: Text("Đổi mật khẩu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
                                content: Form(
                                  key: formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextFormField(
                                        controller: oldPassController,
                                        obscureText: true,
                                        decoration: InputDecoration(
                                          labelText: "Mật khẩu cũ",
                                          prefixIcon: Icon(Icons.lock_outline),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Nhập mật khẩu cũ' : null,
                                      ),
                                      SizedBox(height: 12),
                                      TextFormField(
                                        controller: newPassController,
                                        obscureText: true,
                                        decoration: InputDecoration(
                                          labelText: "Mật khẩu mới",
                                          prefixIcon: Icon(Icons.lock),
                                        ),
                                        validator: (v) => v == null || v.length < 4 ? 'Tối thiểu 4 ký tự' : null,
                                      ),
                                      SizedBox(height: 12),
                                      TextFormField(
                                        controller: confirmPassController,
                                        obscureText: true,
                                        decoration: InputDecoration(
                                          labelText: "Nhập lại mật khẩu mới",
                                          prefixIcon: Icon(Icons.lock),
                                        ),
                                        validator: (v) => v != newPassController.text ? 'Mật khẩu không khớp' : null,
                                      ),
                                      if (errorMsg != null) ...[
                                        SizedBox(height: 10),
                                        Text(errorMsg!, style: TextStyle(color: Colors.red)),
                                      ],
                                    ],
                                  ),
                                ),
                                actions: [
                                  isLoading
                                      ? Center(child: CircularProgressIndicator(color: Colors.amber))
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  if (!formKey.currentState!.validate()) return;
                                                  setState(() { isLoading = true; errorMsg = null; });
                                                  try {
                                                    final response = await ApiService.changePassword(
                                                      oldPassController.text.trim(),
                                                      newPassController.text.trim(),
                                                    );
                                                    setState(() { isLoading = false; });
                                                    if (response == true) {
                                                      // Thêm thông báo vào SharedPreferences
                                                      final prefs = await SharedPreferences.getInstance();
                                                      final now = DateTime.now();
                                                      final noti = "[${now.day}/${now.month} ${now.hour}:${now.minute.toString().padLeft(2, '0')}] Đổi mật khẩu thành công!";
                                                      final List<String> notifications = prefs.getStringList('notifications') ?? [];
                                                      notifications.insert(0, noti);
                                                      await prefs.setStringList('notifications', notifications);
                                                      Navigator.of(context).pop();
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: Colors.green),
                                                      );
                                                    } else {
                                                      setState(() { errorMsg = response ?? 'Đổi mật khẩu thất bại!'; });
                                                    }
                                                  } catch (e) {
                                                    setState(() { isLoading = false; errorMsg = e.toString(); });
                                                  }
                                                },
                                                child: Text("Xác nhận", style: TextStyle(fontWeight: FontWeight.bold)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.amber,
                                                  foregroundColor: Colors.white,
                                                  minimumSize: Size(double.infinity, 48),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: Text("Hủy"),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.amber,
                                                  side: BorderSide(color: Colors.amber),
                                                  minimumSize: Size(double.infinity, 48),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    // Đăng xuất
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.redAccent),
                      title: Text("Đăng xuất"),
                      onTap: () {
                        ApiService.logout();
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                      },
                    ),
                  ],
                ),
    );
  }
}
