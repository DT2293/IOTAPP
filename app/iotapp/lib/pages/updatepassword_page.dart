import 'package:flutter/material.dart';
import 'package:iotapp/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';

class UpdatePasswordPage extends StatefulWidget {
  @override
  _UpdatePasswordPageState createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    final token = prefs.getString('token');

    if (userJson == null || token == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('not_logged_in'.tr())));
      setState(() => _isLoading = false);
      return;
    }

    final user = jsonDecode(userJson);
    final userId = user['userId'];

    final authService = AuthService();
    final error = await authService.updatePassword(
      _oldPasswordController.text,
      _newPasswordController.text,
      userId,
      token,
    );

    setState(() => _isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('update_success'.tr())));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  InputDecoration _inputDecoration(
      String label, IconData icon, bool obscure, VoidCallback onToggle) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        onPressed: onToggle,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = const SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: Text("update_password".tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: _obscureOld,
                decoration: _inputDecoration(
                    'old_password'.tr(), Icons.lock, _obscureOld, () {
                  setState(() => _obscureOld = !_obscureOld);
                }),
                validator: (value) => value == null || value.isEmpty
                    ? 'enter_old_password'.tr()
                    : null,
              ),
              spacing,
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: _inputDecoration(
                    'new_password'.tr(), Icons.lock_outline, _obscureNew, () {
                  setState(() => _obscureNew = !_obscureNew);
                }),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'enter_new_password'.tr();
                  if (value.length < 6) return 'password_too_short'.tr();
                  return null;
                },
              ),
              spacing,
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: _inputDecoration('confirm_password'.tr(),
                    Icons.verified_user, _obscureConfirm, () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                }),
                validator: (value) {
                  if (value != _newPasswordController.text)
                    return 'passwords_do_not_match'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _handleUpdatePassword,
                        label: Text(
                          'update'.tr(),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
