import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/user_repository.dart';
import '../../../models/user.dart';
import '../../../services/theme_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool editMode;
  ProfileScreen({this.editMode = false, Key? key}) : super(key: key);
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  bool isLoading = false;
  bool isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isEditing = widget.editMode;
    loadProfile();
  }

  void loadProfile() async {
    setState(() {
      isLoading = true;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshProfile();
    setState(() {
      user = authProvider.currentUser;
      if (user != null) {
        nameController.text = user!.name;
        emailController.text = user!.email;
        phoneController.text = user!.phone ?? '';
      }
      isLoading = false;
    });
  }

  void logout() {
    Provider.of<ThemeProvider>(context, listen: false).loadThemeForUser(null);
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { isLoading = true; });
    final updatedUser = {
      "name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "phone": phoneController.text.trim(),
    };
    final success = await UserRepository.updateProfile(updatedUser);
    if (success != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshProfile();
      setState(() {
        user = authProvider.currentUser;
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại!'), backgroundColor: Colors.red),
      );
    }
    setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = themeProvider.isModernMode;

    return Scaffold(
      backgroundColor: isModern ? Colors.black : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Hồ sơ cá nhân", style: TextStyle(color: isModern ? Colors.white : Colors.amber[800], fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red),
            onPressed: logout,
          )
        ],
        iconTheme: IconThemeData(color: isModern ? Colors.white : Colors.amber[800]),
      ),
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: isModern ? LinearGradient(
                colors: [Color(0xFF121212), Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ) : LinearGradient(
                colors: [Colors.amber.shade200, Colors.amber.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              border: isModern ? Border(bottom: BorderSide(color: Colors.white24, width: 0.5)) : null,
            ),
          ),
          isLoading
              ? Center(child: CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber))
              : user == null
                  ? Center(child: Text("Không có dữ liệu người dùng", style: TextStyle(fontSize: 18)))
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80, left: 24, right: 24, bottom: 24),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: isModern ? null : [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 54,
                                backgroundColor: isModern ? Color(0xFF1A1A1A) : Colors.white,
                                child: Icon(Icons.person, size: 70, color: isModern ? Colors.white : Colors.amber[800]),
                              ),
                            ),
                            SizedBox(height: 18),
                            Card(
                              color: isModern ? Color(0xFF121212) : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: isModern ? BorderSide(color: Colors.white24) : BorderSide.none,
                              ),
                              elevation: 6,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: isEditing
                                    ? Form(
                                        key: _formKey,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            TextFormField(
                                              controller: nameController,
                                              style: TextStyle(color: isModern ? Colors.white : null),
                                              decoration: InputDecoration(
                                                labelText: "Tên",
                                                labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                                                prefixIcon: Icon(Icons.person, color: isModern ? Colors.white70 : Colors.amber),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                              ),
                                              validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                                            ),
                                            SizedBox(height: 16),
                                            TextFormField(
                                              controller: emailController,
                                              style: TextStyle(color: isModern ? Colors.white : null),
                                              decoration: InputDecoration(
                                                labelText: "Email",
                                                labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                                                prefixIcon: Icon(Icons.email, color: isModern ? Colors.white70 : Colors.amber),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                              ),
                                              validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                                            ),
                                            SizedBox(height: 16),
                                            TextFormField(
                                              controller: phoneController,
                                              style: TextStyle(color: isModern ? Colors.white : null),
                                              decoration: InputDecoration(
                                                labelText: "Số điện thoại",
                                                labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                                                prefixIcon: Icon(Icons.phone, color: isModern ? Colors.white70 : Colors.amber),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                              ),
                                            ),
                                            SizedBox(height: 24),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: saveProfile,
                                                    icon: Icon(Icons.save, color: isModern ? Colors.black : Colors.white),
                                                    label: Text("Lưu", style: TextStyle(fontWeight: FontWeight.bold)),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: isModern ? Colors.white : Colors.amber[800],
                                                      foregroundColor: isModern ? Colors.black : Colors.white,
                                                      padding: EdgeInsets.symmetric(vertical: 16),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () => setState(() => isEditing = false),
                                                    icon: Icon(Icons.cancel, color: isModern ? Colors.white : Colors.amber),
                                                    label: Text("Hủy"),
                                                    style: OutlinedButton.styleFrom(
                                                      side: BorderSide(color: isModern ? Colors.white30 : Colors.amber, width: 2),
                                                      foregroundColor: isModern ? Colors.white : Colors.amber,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                      padding: EdgeInsets.symmetric(vertical: 16),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.person, color: isModern ? Colors.white70 : Colors.amber),
                                              SizedBox(width: 8),
                                              Text(user!.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isModern ? Colors.white : null)),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(Icons.email, color: isModern ? Colors.white70 : Colors.amber),
                                              SizedBox(width: 8),
                                              Text(user!.email, style: TextStyle(fontSize: 16, color: isModern ? Colors.white70 : null)),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(Icons.phone, color: isModern ? Colors.white70 : Colors.amber),
                                              SizedBox(width: 8),
                                              Text(user!.phone ?? '-', style: TextStyle(fontSize: 16, color: isModern ? Colors.white70 : null)),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(Icons.verified_user, color: isModern ? Colors.white70 : Colors.amber),
                                              SizedBox(width: 8),
                                              Text(user!.role, style: TextStyle(fontSize: 16, color: isModern ? Colors.white70 : null)),
                                            ],
                                          ),
                                          SizedBox(height: 24),
                                          ElevatedButton.icon(
                                            onPressed: () => setState(() => isEditing = true),
                                            icon: Icon(Icons.edit, color: isModern ? Colors.black : Colors.white),
                                            label: Text("Chỉnh sửa thông tin", style: TextStyle(fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isModern ? Colors.white : Colors.amber[800],
                                              foregroundColor: isModern ? Colors.black : Colors.white,
                                              padding: EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}
