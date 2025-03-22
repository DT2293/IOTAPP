import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
//   @override
//   _SettingsPageState createState() => _SettingsPageState();
// }

// class _SettingsPageState extends State<SettingsPage> {
//   bool _darkMode = false;
//   String _selectedLanguage = "Tiếng Việt"; // Ngôn ngữ mặc định

//   final List<String> _languages = ["Tiếng Việt", "English", "Español", "Français"];

final Function(bool) onToggleDarkMode;

  SettingsPage({required this.onToggleDarkMode});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
   String _selectedLanguage = "Tiếng Việt"; // Ngôn ngữ mặc định

  final List<String> _languages = ["Tiếng Việt", "English", "Español", "Français"];
  @override
  void initState() {
    super.initState();
    _loadDarkMode();
  }

  void _loadDarkMode() async {
    setState(() {
      _darkMode = Theme.of(context).brightness == Brightness.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cài đặt"),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionTitle("Tài khoản"),
          _buildListTile(
            icon: Icons.person,
            title: "Chỉnh sửa hồ sơ",
            onTap: () {
              // Điều hướng đến trang chỉnh sửa hồ sơ
            },
          ),
          _buildListTile(
            icon: Icons.lock,
            title: "Đổi mật khẩu",
            onTap: () {
              // Điều hướng đến trang đổi mật khẩu
            },
          ),

          SizedBox(height: 16),
          _buildSectionTitle("Cài đặt ứng dụng"),
          
          // ✅ Chuyển đổi Dark Mode
         SwitchListTile(
            title: Text("Chế độ tối"),
            secondary: Icon(Icons.dark_mode),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
              widget.onToggleDarkMode(value);
            },
          ),

          // ✅ Chuyển đổi ngôn ngữ
          ListTile(
            leading: Icon(Icons.language, color: Colors.blue),
            title: Text("Ngôn ngữ"),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              items: _languages.map((String lang) {
                return DropdownMenuItem<String>(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLanguage = newValue;
                  });
                }
              },
            ),
          ),

          SizedBox(height: 16),
          _buildSectionTitle("Thông tin"),
          _buildListTile(
            icon: Icons.info,
            title: "Giới thiệu ứng dụng",
            onTap: () {
              // Điều hướng đến trang thông tin ứng dụng
            },
          ),
          _buildListTile(
            icon: Icons.policy,
            title: "Chính sách bảo mật",
            onTap: () {
              // Điều hướng đến trang chính sách bảo mật
            },
          ),

          SizedBox(height: 16),
          Divider(),
          _buildListTile(
            icon: Icons.logout,
            title: "Đăng xuất",
            color: Colors.red,
            onTap: () {
              // Xử lý đăng xuất
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, Color? color, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.blue),
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
