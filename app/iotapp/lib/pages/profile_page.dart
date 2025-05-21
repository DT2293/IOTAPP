import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:iotapp/pages/home_page.dart';
import 'package:iotapp/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  final String username;
  final List<String> phone;
  final String email;
  final String token;

  ProfilePage({
    required this.userId,
    required this.username,
    required this.email,
    required this.phone,
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
  List<String> phoneNumbers = [];

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.username;
    _emailController.text = widget.email;
    phoneNumbers = List.from(widget.phone);
  }

void _addPhoneNumber() async {
  String phone = _phoneController.text.trim();
  if (phone.isEmpty) {
    Fluttertoast.showToast(msg: tr("phone_required"));
    return;
  }

  bool success = await _authService.addPhoneNumber(phone, widget.token);
  if (success) {
    setState(() {
      phoneNumbers.add(phone);
      _phoneController.clear();
    });
    Fluttertoast.showToast(msg: tr("add_phone_success"));
  } else {
    Fluttertoast.showToast(msg: tr("add_phone_failed"));
  }
}


  void _updateProfile() async {
    String newUsername = _usernameController.text.trim();
    String newEmail = _emailController.text.trim();
    String newPhone = _phoneController.text.trim();
    if (newUsername.isEmpty || newEmail.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("empty_username_email".tr())));
      return;
    }

    int? userId = await _authService.getUserId();
    String? token = await _authService.getToken();

    if (userId == null || token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("no_userid_token".tr())));
      return;
    }

    bool success = await _authService.updateUser(
      newUsername,
      newEmail,
      newPhone,
      widget.token,
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("update_success".tr())));

      await Future.delayed(Duration(milliseconds: 500));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("update_failed".tr())));
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "username".tr(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: "enter_username".tr(),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "email".tr(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "enter_email".tr(),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),

            // Modified phone input
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: tr('enter_phone'),
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    final newPhone = _phoneController.text.trim();
                    if (newPhone.isNotEmpty) {
                      _addPhoneNumber();
                    }
                  },
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 24),

            // List of phone numbers
            if (phoneNumbers.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: phoneNumbers.map((phone) {
                  return ListTile(
                    title: Text(phone),
                  );
                }).toList(),
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
