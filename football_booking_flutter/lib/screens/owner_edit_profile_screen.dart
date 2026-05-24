import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

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
    // Nếu user được truyền qua arguments thì lấy lại nếu controller chưa có dữ liệu
    final User? argUser = ModalRoute.of(context)?.settings.arguments as User?;
    if (argUser != null && ownerNameController.text.isEmpty && emailController.text.isEmpty) {
      ownerNameController.text = argUser.name;
      emailController.text = argUser.email;
      contactNumberController.text = argUser.phone ?? '';
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Sửa thông tin chủ sân", style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.amber[800]),
      ),
      backgroundColor: Color(0xFFF8F8F8),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: ownerNameController,
                            decoration: InputDecoration(
                              labelText: "Tên chủ sân",
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
                            controller: contactNumberController,
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
                                  onPressed: _saveOwnerProfile,
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
                                  onPressed: () => Navigator.pop(context),
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
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

