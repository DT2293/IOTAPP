import 'package:flutter/material.dart';
import 'package:iotapp/pages/home_page.dart';
import 'package:iotapp/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  final String userId;     // Thêm userId để gọi API
  final String username;
  final String email;
  final String token;      // Thêm token để xác thực

  ProfilePage({
    required this.userId,
    required this.username,
    required this.email,
    required this.token,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.username;
    _emailController.text = widget.email;
  }

void _updateProfile() async {
  String newUsername = _usernameController.text.trim();
  String newEmail = _emailController.text.trim();

  if (newUsername.isEmpty || newEmail.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Tên đăng nhập và email không được bỏ trống!")),
    );
    return;
  }

  // 👉 Lấy userId và token từ SharedPreferences
  String? userId = await _authService.getUserId();
  String? token = await _authService.getToken();

  print("📌 Debug userId: $userId");
  print("📌 Debug token: $token");

  if (userId == null || token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Lỗi: Không tìm thấy userId hoặc token!")),
    );
    return;
  }

bool success = await _authService.updateUser(
  newUsername, 
  newEmail, 
  widget.token
);

if (success) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Cập nhật thành công!")),
  );

  // ⏳ Đợi SnackBar hiển thị một chút trước khi chuyển trang
  await Future.delayed(Duration(milliseconds: 500));

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => HomePage()),
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Lỗi khi cập nhật thông tin!")),
  );
}

}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thông tin tài khoản"),
        leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()),);  // Quay về màn hình trước đó
    },
  ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tên người dùng:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: "Nhập tên đăng nhập",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Text("Email:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "Nhập email",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _updateProfile,
                child: Text("Cập nhật thông tin"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
