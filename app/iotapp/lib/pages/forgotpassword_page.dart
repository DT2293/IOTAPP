import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:iotapp/services/auth_service.dart';
import 'package:iotapp/pages/login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool otpSent = false;
  bool otpVerified = false;
  int? endTime;
  final authService = AuthService();

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      showToast(tr("email_required"));
      return;
    }

    _showLoading();
    final result = await (authService.sendOtp(emailController.text.trim()));
    _hideLoading();

    if (result == null) {
      setState(() {
        otpSent = true;
        otpVerified = false;
        endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 60;
      });
      showToast(tr("otp_sent_success"));
    } else {
      showToast(result);
      print("Gửi OTP thất bại: $result");
    }
  }

  Future<void> _verifyOtp() async {
    if (otpController.text.trim().length != 6) {
      showToast(tr("otp_invalid"));
      return;
    }

    _showLoading();
    try {
      await authService.verifyOtp(
        emailController.text.trim(),
        otpController.text.trim(),
      );
      _hideLoading();
      showToast(tr("verify_success"));
      setState(() {
        otpVerified = true;
      });
    } catch (e) {
      _hideLoading();
      showToast(e.toString().replaceAll("Exception:", "").trim());
    }
  }

  Future<void> _resetPassword() async {
    if (newPasswordController.text.length < 6) {
      showToast(tr("password_min_length"));
      return;
    }

    _showLoading();
    try {
      final result = await authService.resetPassword(
        emailController.text.trim(),
        newPasswordController.text.trim(),
      );
      _hideLoading();
      if (result == null) {
        showToast(tr("reset_success"));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      } else {
        showToast(result);
      }
    } catch (e) {
      _hideLoading();
      showToast(e.toString().replaceAll("Exception:", "").trim());
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoading() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("forgot_password"))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Icon(Icons.lock_reset, size: 80, color: Colors.blue.shade400),
              const SizedBox(height: 24),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: tr("email"),
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || value.isEmpty
                    ? tr("email_required")
                    : null,
              ),
              const SizedBox(height: 24),
              if (otpSent) ...[
                TextFormField(
                  controller: otpController,
                  decoration: InputDecoration(
                    labelText: tr("otp"),
                    prefixIcon: const Icon(Icons.password),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (endTime != null)
                      CountdownTimer(
                        endTime: endTime,
                        onEnd: () {
                          setState(() {
                            endTime = null;
                          });
                        },
                        widgetBuilder: (_, time) {
                          if (time == null) {
                            return Text(
                              tr("otp_expired"),
                              style: const TextStyle(color: Colors.red),
                            );
                          } else {
                            return Text(
                              "${tr("otp_time_left")}: ${time.min ?? 0}:${(time.sec ?? 0).toString().padLeft(2, '0')}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            );
                          }
                        },
                      ),
                    TextButton.icon(
                      onPressed: (endTime != null &&
                              DateTime.now().millisecondsSinceEpoch < endTime!)
                          ? null
                          : () {
                              _sendOtp();
                            },
                      label: Text(
                        (endTime != null &&
                                DateTime.now().millisecondsSinceEpoch <
                                    endTime!)
                            ? tr("wait") 
                            : tr("resend_otp"), 
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (!otpVerified)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _verifyOtp,
                      icon: const Icon(Icons.verified),
                      label: Text(tr("verify_otp")),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
              if (otpVerified) ...[
                const SizedBox(height: 24),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: tr("new_password"),
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _resetPassword,
                    icon: const Icon(Icons.save),
                    label: Text(tr("reset_password")),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              if (!otpSent)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendOtp,
                    icon: const Icon(Icons.send),
                    label: Text(tr("send_otp")),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
