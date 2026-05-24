import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

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
    User? loadedUser = await ApiService.getProfile();
    setState(() {
      user = loadedUser;
      if (user != null) {
        nameController.text = user!.name;
        emailController.text = user!.email;
        phoneController.text = user!.phone ?? '';
      }
      isLoading = false;
    });
  }

  void logout() {
    ApiService.logout();
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
    final success = await ApiService.updateProfile(updatedUser);
    if (success != null) {
      setState(() {
        user = success;
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Hồ sơ cá nhân", style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red),
            onPressed: logout,
          )
        ],
        iconTheme: IconThemeData(color: Colors.amber[800]),
      ),
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade200, Colors.amber.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.amber))
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
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 54,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.person, size: 70, color: Colors.amber[800]),
                              ),
                            ),
                            SizedBox(height: 18),
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                                              decoration: InputDecoration(
                                                labelText: "Tên",
                                                prefixIcon: Icon(Icons.person, color: Colors.amber),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                              ),
                                              validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                                            ),
                                            SizedBox(height: 16),
                                            TextFormField(
                                              controller: emailController,
                                              decoration: InputDecoration(
                                                labelText: "Email",
                                                prefixIcon: Icon(Icons.email, color: Colors.amber),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                              ),
                                              validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                                            ),
                                            SizedBox(height: 16),
                                            TextFormField(
                                              controller: phoneController,
                                              decoration: InputDecoration(
                                                labelText: "Số điện thoại",
                                                prefixIcon: Icon(Icons.phone, color: Colors.amber),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                              ),
                                            ),
                                            SizedBox(height: 24),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: saveProfile,
                                                    icon: Icon(Icons.save, color: Colors.white),
                                                    label: Text("Lưu", style: TextStyle(fontWeight: FontWeight.bold)),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.amber[800],
                                                      foregroundColor: Colors.white,
                                                      padding: EdgeInsets.symmetric(vertical: 16),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () => setState(() => isEditing = false),
                                                    icon: Icon(Icons.cancel, color: Colors.amber),
                                                    label: Text("Hủy"),
                                                    style: OutlinedButton.styleFrom(
                                                      side: BorderSide(color: Colors.amber, width: 2),
                                                      foregroundColor: Colors.amber,
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
                                              Icon(Icons.person, color: Colors.amber),
                                              SizedBox(width: 8),
                                              Text(user!.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(Icons.email, color: Colors.amber),
                                              SizedBox(width: 8),
                                              Text(user!.email, style: TextStyle(fontSize: 16)),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(Icons.phone, color: Colors.amber),
                                              SizedBox(width: 8),
                                              Text(user!.phone ?? '-', style: TextStyle(fontSize: 16)),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(Icons.verified_user, color: Colors.amber),
                                              SizedBox(width: 8),
                                              Text(user!.role, style: TextStyle(fontSize: 16)),
                                            ],
                                          ),
                                          SizedBox(height: 24),
                                          ElevatedButton.icon(
                                            onPressed: () => setState(() => isEditing = true),
                                            icon: Icon(Icons.edit, color: Colors.white),
                                            label: Text("Chỉnh sửa thông tin", style: TextStyle(fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.amber[800],
                                              foregroundColor: Colors.white,
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
