import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:iotapp/pages/home_page.dart';
import 'package:iotapp/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  final String username;
  final String email;
  final String token;

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
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.username;
    _emailController.text = widget.email;
  }

  void _updateProfile() async {
    String newUsername = _usernameController.text.trim();
    String newEmail = _emailController.text.trim();
    String newPhone = _phoneController.text.trim();
    if (newUsername.isEmpty || newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("empty_username_email".tr())),
      );
      return;
    }

    int? userId = await _authService.getUserId();
    String? token = await _authService.getToken();

    if (userId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("no_userid_token".tr())),
      );
      return;
    }

    bool success = await _authService.updateUser(
      newUsername,
      newEmail,
      newPhone,
      widget.token,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("update_success".tr())),
      );

      await Future.delayed(Duration(milliseconds: 500));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("update_failed".tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("account_info".tr()),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("username".tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: "enter_username".tr(),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Text("email".tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "enter_email".tr(),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
             Text("phone".tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: "enter_phone".tr(),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _updateProfile,
                child: Text("update_info".tr()),
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
