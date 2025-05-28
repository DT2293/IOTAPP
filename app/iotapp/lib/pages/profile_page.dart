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

  const ProfilePage({
    required this.userId,
    required this.username,
    required this.email,
    required this.phone,
    required this.token,
    super.key,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("empty_username_email"))),
      );
      return;
    }

    int? userId = await _authService.getUserId();
    String? token = await _authService.getToken();

    if (userId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("no_userid_token"))),
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
        SnackBar(
          content: Text(
            tr("update_success"),
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      await Future.delayed(Duration(milliseconds: 500));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr("update_failed"),
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr("account_info")),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildLabel("username"),
            buildTextField(_usernameController, "enter_username", Icons.person),
            SizedBox(height: 16),
            buildLabel("email"),
            buildTextField(_emailController, "enter_email", Icons.email),
            SizedBox(height: 16),
            buildLabel("phone"),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: tr("enter_phone"),
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addPhoneNumber,
                  icon: Icon(Icons.add),
                  label: Text(tr("add")),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            if (phoneNumbers.isNotEmpty) ...[
              SizedBox(height: 24),
              buildLabel("phone"),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                color: theme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: phoneNumbers.map((phone) {
                      return ListTile(
                        leading: Icon(Icons.phone_android),
                        title: Text(phone),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
            SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: _updateProfile,
                icon: Icon(Icons.save),
                label: Text(tr("update_info")),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLabel(String key) {
    return Text(
      tr(key),
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget buildTextField(
      TextEditingController controller, String hintKey, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: tr(hintKey),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}