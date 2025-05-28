import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iotapp/pages/forgotpassword_page.dart';
import 'package:iotapp/pages/home_page.dart';
import 'package:iotapp/pages/register_page.dart';
import 'package:iotapp/services/auth_service.dart';
import 'package:iotapp/widget/language_dropdown.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;

  void navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
    );
  }

  void navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('fill_all_fields')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? errorMessage = await _authService.login(email, password);

    if (errorMessage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('login_success'))));

      // Chờ SnackBar hiện 1 chút trước khi chuyển trang
      await Future.delayed(Duration(milliseconds: 300));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      final translatedError =
          errorMessage.contains('tài khoản')
              ? tr('invalid_username')
              : errorMessage.contains('mật khẩu')
              ? tr('invalid_password')
              : tr('login_failed');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translatedError, style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('login')),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: LanguageDropdown(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "FIRE SENSE",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color.fromARGB(255, 85, 6, 79),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: tr('enter_email'),
                  hintText: tr('enter_email'),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 15,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: tr('password'),
                  hintText: tr('enter_password'),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 15,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor:  const Color.fromARGB(255, 66, 32, 100),
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(tr('login')),
              ),
              SizedBox(height: 10),
              Center(
                child: InkWell(
                  onTap: navigateToForgotPassword,
                  child: Text(
                    tr('forgot_password'),
                    style: TextStyle(fontSize: 16, color: const Color.fromARGB(255, 85, 6, 79)),
                  ),
                ),
              ),
              SizedBox(height: 50),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tr('no_account'),
                      style: TextStyle(fontSize: 16, color: const Color.fromARGB(255, 85, 6, 79)),
                    ),
                    SizedBox(width: 5),
                    InkWell(
                      onTap: navigateToRegister,
                      child: Text(
                        tr('sign_up'),
                        style: TextStyle(
                          fontSize: 16,
                         color: const Color.fromARGB(255, 85, 6, 79),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
