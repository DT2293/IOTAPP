import 'package:flutter/material.dart';
import 'package:iotapp/pages/login_page.dart';
import 'package:iotapp/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();
  final AuthService _authService = AuthService(); // ✅ Định nghĩa một lần
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isRepeatPasswordVisible = false;

  void navigateToLoginPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _register() async {
  if (!_formKey.currentState!.validate()) return;

  if (_passwordController.text != _repeatPasswordController.text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Mật khẩu không khớp!")),
    );
    return;
  }

  setState(() => _isLoading = true);

  String? errorMessage = await _authService.register(
    _usernameController.text,
    _emailController.text,
    _passwordController.text,
  );

  setState(() => _isLoading = false);

  if (errorMessage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🎉 Đăng ký thành công!")),
    );
    navigateToLoginPage();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ $errorMessage")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form( // ✅ Thêm Form để dùng validate()
            key: _formKey,
            child: Column(
              children: [
                Text(
                  'IOT App',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Email',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Email không được để trống";
                    if (!RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$').hasMatch(value)) {
                      return "Email không hợp lệ";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Tên người dùng',
                    hintText: 'Nhập ên người dùng',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Tên người dùng không được để trống";
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Mật khẩu không được để trống";
                    if (value.length < 6) return "Mật khẩu ít nhất 6 ký tự";
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _repeatPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Nhập lại mật khẩu',
                    hintText: 'Nhập lại mật khẩu',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    suffixIcon: IconButton(
                      icon: Icon(_isRepeatPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isRepeatPasswordVisible = !_isRepeatPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isRepeatPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Xác nhận mật khẩu không được để trống";
                    if (value != _passwordController.text) return "Mật khẩu không khớp";
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register, // ✅ Vô hiệu hóa khi đang tải
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.blueAccent,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Đang đăng ký...'),
                          ],
                        )
                      : Text('Đăng ký'),
                ),
                SizedBox(height: 10),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đã có tài khoản?',
                        style: TextStyle(fontSize: 16, color: Colors.blue[900]),
                      ),
                      SizedBox(width: 5),
                      InkWell(
                        onTap: navigateToLoginPage,
                        child: Text(
                          'Đăng nhập',
                          style: TextStyle(fontSize: 16, color: Colors.blue[900], fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:iotapp/pages/login_page.dart';
// import 'package:iotapp/services/auth_service.dart';

// class RegisterPage extends StatefulWidget {
//   @override
//   _RegisterPageState createState() => _RegisterPageState();
// }

// class _RegisterPageState extends State<RegisterPage> {
  

//   void navigateToLoginPage() {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => LoginPage()),
//     );
//   }

//   Future<void> _register() async {
//     if (_formKey.currentState!.validate()) {
//       if (_passwordController.text != _repeatPasswordController.text) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("❌ Passwords do not match!")),
//         );
//         return;
//       }

//       setState(() => _isLoading = true);

//       AuthService authService = AuthService();
//       bool success = await authService.register(
//         _usernameController.text,
//         _emailController.text,
//         _passwordController.text,
//       );

//       setState(() => _isLoading = false);

//       if (success) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("🎉 Registration successful!")),
//         );
//         navigateToLoginPage();
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("❌ Registration failed!")),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//                 Text(
//                   'IOT App',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: Colors.blue[900],
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 TextFormField(
//                   controller: _emailController,
//                   decoration: InputDecoration(
//                     labelText: 'Email',
//                     hintText: 'Enter your email',
//                     border: OutlineInputBorder(),
//                     contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
//                   ),
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) return "Email cannot be empty";
//                     if (!RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$').hasMatch(value)) {
//                       return "Invalid email format";
//                     }
//                     return null;
//                   },
//                 ),
//                 SizedBox(height: 20),
//                 TextFormField(
//                   controller: _usernameController,
//                   decoration: InputDecoration(
//                     labelText: 'Username',
//                     hintText: 'Enter your username',
//                     border: OutlineInputBorder(),
//                     contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) return "Username cannot be empty";
//                     return null;
//                   },
//                 ),
//                 SizedBox(height: 20),
//                 TextFormField(
//                   controller: _passwordController,
//                   decoration: InputDecoration(
//                     labelText: 'Password',
//                     hintText: 'Enter your password',
//                     border: OutlineInputBorder(),
//                     contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
//                     suffixIcon: IconButton(
//                       icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
//                       onPressed: () {
//                         setState(() {
//                           _isPasswordVisible = !_isPasswordVisible;
//                         });
//                       },
//                     ),
//                   ),
//                   obscureText: !_isPasswordVisible,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) return "Password cannot be empty";
//                     if (value.length < 6) return "Password must be at least 6 characters";
//                     return null;
//                   },
//                 ),
//                 SizedBox(height: 20),
//                 TextFormField(
//                   controller: _repeatPasswordController,
//                   decoration: InputDecoration(
//                     labelText: 'Repeat Password',
//                     hintText: 'Re-enter your password',
//                     border: OutlineInputBorder(),
//                     contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
//                     suffixIcon: IconButton(
//                       icon: Icon(_isRepeatPasswordVisible ? Icons.visibility : Icons.visibility_off),
//                       onPressed: () {
//                         setState(() {
//                           _isRepeatPasswordVisible = !_isRepeatPasswordVisible;
//                         });
//                       },
//                     ),
//                   ),
//                   obscureText: !_isRepeatPasswordVisible,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) return "Please confirm your password";
//                     if (value != _passwordController.text) return "Passwords do not match";
//                     return null;
//                   },
//                 ),
//                 SizedBox(height: 20),
//                 _isLoading
//                     ? Center(child: CircularProgressIndicator())
//                     : ElevatedButton(
//                         onPressed: _register,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                           foregroundColor: Colors.white,
//                           shadowColor: Colors.blueAccent,
//                           elevation: 5,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//                         ),
//                         child: Text('Register'),
//                       ),
//                 SizedBox(height: 10),
//                 Center(
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Already have an account?',
//                         style: TextStyle(fontSize: 16, color: Colors.blue[900]),
//                       ),
//                       SizedBox(width: 5),
//                       InkWell(
//                         onTap: navigateToLoginPage,
//                         child: Text(
//                           'LOGIN',
//                           style: TextStyle(fontSize: 16, color: Colors.blue[900], fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           ),
//     );
        
//   }
// }

