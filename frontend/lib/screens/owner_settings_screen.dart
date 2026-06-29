import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../services/theme_service.dart';

class OwnerSettingsScreen extends StatefulWidget {
  @override
  _OwnerSettingsScreenState createState() => _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends State<OwnerSettingsScreen> {
  User? user;
  bool isLoading = true;
  bool? _localIsModern;

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = _localIsModern ?? themeProvider.isModernMode;

    return Scaffold(
      backgroundColor: isModern ? Colors.black : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text("Cài đặt"),
        backgroundColor: isModern ? Colors.black : Colors.amberAccent,
        foregroundColor: isModern ? Colors.white : Colors.black,
        elevation: 0, // Đảm bảo giao diện phẳng nếu muốn
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber))
          : user == null
              ? Center(child: Text("Không thể tải thông tin người dùng."))
              : ListView(
                  children: [
                    // Header
                    Container(
                      color: isModern ? Colors.black : Colors.amberAccent,
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
                            user!.name + " [Chủ sân]",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isModern ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(user!.email, style: TextStyle(fontSize: 16, color: isModern ? Colors.white70 : null)),
                          SizedBox(height: 4),
                          Text(user!.phone ?? '-', style: TextStyle(fontSize: 16, color: isModern ? Colors.white70 : null)),
                        ],
                      ),
                    ),
                    // Chuyển đổi giao diện (MỚI cho Owner)
                    ListTile(
                      leading: Icon(
                        isModern ? Icons.dark_mode : Icons.palette,
                        color: isModern ? Colors.white : Colors.amber,
                      ),
                      title: Text(
                        "Giao diện",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isModern ? Colors.white : null,
                        ),
                      ),
                      subtitle: Text(
                        isModern ? "Chế độ Đen & Trắng" : "Chế độ cổ điển",
                        style: TextStyle(color: isModern ? Colors.white54 : null),
                      ),
                      trailing: IgnorePointer(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 60,
                          height: 32,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isModern ? Colors.grey[900] : Colors.amber[100],
                            border: Border.all(
                              color: isModern ? Colors.white24 : Colors.amber,
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                left: isModern ? 30 : 2,
                                top: 2,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isModern ? Colors.white : Colors.amber[800],
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isModern ? Icons.dark_mode : Icons.wb_sunny,
                                    size: 14,
                                    color: isModern ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _localIsModern = !isModern;
                        });
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            themeProvider.toggleTheme();
                            setState(() {
                              _localIsModern = null;
                            });
                          }
                        });
                      },
                    ),
                    Divider(color: isModern ? Colors.white12 : null),
                    // Sửa thông tin
                    ListTile(
                      leading: Icon(Icons.edit, color: isModern ? Colors.white : Colors.amber[800]),
                      title: Text('Sửa thông tin', style: TextStyle(color: isModern ? Colors.white : null)),
                      onTap: () async {
                        final updatedUser = await Navigator.pushNamed(
                          context,
                          '/ownerEditProfile',
                          arguments: user,
                        );
                        if (updatedUser is User) {
                          setState(() {
                            user = updatedUser;
                          });
                        }
                      },
                    ),
                    Divider(color: isModern ? Colors.white12 : null),
                    ListTile(
                      leading: Icon(Icons.account_balance_wallet, color: isModern ? Colors.white : Colors.green),
                      title: Text('Ví tiền & Doanh thu cọc', style: TextStyle(color: isModern ? Colors.white : null)),
                      onTap: () {
                        Navigator.pushNamed(context, '/ownerRevenue');
                      },
                    ),
                    // Về chúng tôi
                    ListTile(
                      leading: Icon(Icons.info, color: isModern ? Colors.white : Colors.blueAccent),
                      title: Text("Về chúng tôi", style: TextStyle(color: isModern ? Colors.white : null)),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: isModern ? Color(0xFF121212) : null,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Center(child: Text("Về chúng tôi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: isModern ? Colors.white : null))),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sports_soccer, color: isModern ? Colors.white : Colors.amber, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  "Ứng dụng đặt sân bóng đá tiện lợi, nhanh chóng và hiện đại.\n\nLiên hệ: dovinhhp102@gmail.com\nSĐT: 0984981822",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16, color: isModern ? Colors.white70 : null),
                                ),
                              ],
                            ),
                            actions: [
                              Center(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isModern ? Colors.white : Colors.amber,
                                    foregroundColor: isModern ? Colors.black : Colors.white,
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
                      leading: Icon(Icons.email, color: isModern ? Colors.white : Colors.amberAccent),
                      title: Text("dovinhhp102@gmail.com", style: TextStyle(color: isModern ? Colors.white : null)),
                      onTap: () => _copyToClipboard("dovinhhp102@gmail.com", "Email"),
                    ),
                    // Số điện thoại chủ app
                    ListTile(
                      leading: Icon(Icons.phone, color: isModern ? Colors.white : Colors.amberAccent),
                      title: Text("0984981822", style: TextStyle(color: isModern ? Colors.white : null)),
                      onTap: () => _copyToClipboard("0984981822", "Số điện thoại"),
                    ),
                    // Đổi mật khẩu
                    ListTile(
                      leading: Icon(Icons.lock, color: isModern ? Colors.white : Colors.deepPurple),
                      title: Text("Đổi mật khẩu", style: TextStyle(color: isModern ? Colors.white : null)),
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
                                backgroundColor: isModern ? Color(0xFF121212) : null,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Center(child: Text("Đổi mật khẩu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: isModern ? Colors.white : null))),
                                content: Form(
                                  key: formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextFormField(
                                        controller: oldPassController,
                                        obscureText: true,
                                        style: TextStyle(color: isModern ? Colors.white : null),
                                        decoration: InputDecoration(
                                          labelText: "Mật khẩu cũ",
                                          labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                                          prefixIcon: Icon(Icons.lock_outline, color: isModern ? Colors.white70 : null),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Nhập mật khẩu cũ' : null,
                                      ),
                                      SizedBox(height: 12),
                                      TextFormField(
                                        controller: newPassController,
                                        obscureText: true,
                                        style: TextStyle(color: isModern ? Colors.white : null),
                                        decoration: InputDecoration(
                                          labelText: "Mật khẩu mới",
                                          labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                                          prefixIcon: Icon(Icons.lock, color: isModern ? Colors.white70 : null),
                                        ),
                                        validator: (v) => v == null || v.length < 4 ? 'Tối thiểu 4 ký tự' : null,
                                      ),
                                      SizedBox(height: 12),
                                      TextFormField(
                                        controller: confirmPassController,
                                        obscureText: true,
                                        style: TextStyle(color: isModern ? Colors.white : null),
                                        decoration: InputDecoration(
                                          labelText: "Nhập lại mật khẩu mới",
                                          labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                                          prefixIcon: Icon(Icons.lock, color: isModern ? Colors.white70 : null),
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
                                      ? Center(child: CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber))
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
                                                  backgroundColor: isModern ? Colors.white : Colors.amber,
                                                  foregroundColor: isModern ? Colors.black : Colors.white,
                                                  minimumSize: Size(double.infinity, 48),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: Text("Hủy", style: TextStyle(color: isModern ? Colors.white : null)),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: isModern ? Colors.white : Colors.amber,
                                                  side: BorderSide(color: isModern ? Colors.white : Colors.amber),
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
