import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../services/theme_service.dart';
import '../../../models/user.dart';

class OwnerEditProfileScreen extends StatefulWidget {
  final User? user;
  const OwnerEditProfileScreen({Key? key, this.user}) : super(key: key);

  @override
  State<OwnerEditProfileScreen> createState() => _OwnerEditProfileScreenState();
}

class _OwnerEditProfileScreenState extends State<OwnerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      ownerNameController.text = widget.user!.name;
      emailController.text = widget.user!.email;
      contactNumberController.text = widget.user!.phone ?? '';
    }
  }

  Future<void> _saveOwnerProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { isLoading = true; });
    final data = {
      "ownerName": ownerNameController.text.trim(),
      "email": emailController.text.trim(),
      "contactNumber": contactNumberController.text.trim(),
    };
    final result = await ApiService.updateOwnerProfile(data);
    setState(() { isLoading = false; });
    if (result != null) {
      Navigator.pop(context, User(
        id: result['id'],
        name: result['ownerName'] ?? '',
        email: result['email'] ?? '',
        phone: result['contactNumber'] ?? '',
        role: 'OWNER',
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = themeProvider.isModernMode;

    // Nếu user được truyền qua arguments thì lấy lại nếu controller chưa có dữ liệu
    final User? argUser = ModalRoute.of(context)?.settings.arguments as User?;
    if (argUser != null && ownerNameController.text.isEmpty && emailController.text.isEmpty) {
      ownerNameController.text = argUser.name;
      emailController.text = argUser.email;
      contactNumberController.text = argUser.phone ?? '';
    }
    return Scaffold(
      backgroundColor: isModern ? Colors.black : const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Text(
          "Sửa thông tin chủ sân",
          style: TextStyle(
            color: isModern ? Colors.white : Colors.amber[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isModern ? const Color(0xFF0A0B0E) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isModern ? Colors.white : Colors.amber[800]),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  color: isModern ? const Color(0xFF16181D) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: isModern ? const BorderSide(color: Colors.white24) : BorderSide.none,
                  ),
                  elevation: isModern ? 0 : 6,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: ownerNameController,
                            style: TextStyle(color: isModern ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              labelText: "Tên chủ sân",
                              labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                              prefixIcon: Icon(Icons.person, color: isModern ? Colors.white70 : Colors.amber),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: emailController,
                            style: TextStyle(color: isModern ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              labelText: "Email",
                              labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                              prefixIcon: Icon(Icons.email, color: isModern ? Colors.white70 : Colors.amber),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: contactNumberController,
                            style: TextStyle(color: isModern ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              labelText: "Số điện thoại",
                              labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                              prefixIcon: Icon(Icons.phone, color: isModern ? Colors.white70 : Colors.amber),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _saveOwnerProfile,
                                  icon: Icon(Icons.save, color: isModern ? Colors.black : Colors.white),
                                  label: const Text("Lưu", style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isModern ? Colors.white : Colors.amber[800],
                                    foregroundColor: isModern ? Colors.black : Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(Icons.cancel, color: isModern ? Colors.white : Colors.amber),
                                  label: const Text("Hủy"),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: isModern ? Colors.white30 : Colors.amber, width: 2),
                                    foregroundColor: isModern ? Colors.white : Colors.amber,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

