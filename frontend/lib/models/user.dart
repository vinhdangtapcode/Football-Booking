class User {
  int? id;
  String name;
  String email;
  String? phone;
  String role;
  bool isLocked;

  User({this.id, required this.name, required this.email, this.phone, required this.role, this.isLocked = false});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? "",
      email: json['email'] ?? "",
      phone: json['phone'],
      role: json['role'] ?? "USER",
      isLocked: json['isLocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'isLocked': isLocked,
    };
  }
}
