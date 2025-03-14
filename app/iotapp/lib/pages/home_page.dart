import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iotapp/pages/devicedetail_page.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  String? _token;
  String? _userId;
  String? _username;
  String? _email;
  List<dynamic> _devices = [];
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    String? token = await _authService.getToken();
    Map<String, dynamic>? userData = await _authService.getUserInfo();
    List<String> devices =
        await _authService.getUserDevices(); // ✅ Lấy danh sách thiết bị

    print("Token: $token"); // ✅ Debug token
    print("User data: $userData"); // ✅ Debug user info
    print("Devices: $devices"); // ✅ Debug danh sách thiết bị

    setState(() {
      _token = token;
      _userId = userData?["_id"] ?? "Không có dữ liệu";
      _username = userData?["username"] ?? "Không có dữ liệu";
      _email = userData?["email"] ?? "Không có dữ liệu";
      _devices = devices; // ✅ Cập nhật danh sách thiết bị
    });
  }

  void _logout() async {
    await _authService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trang Chủ"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(
                _username ?? "Không có dữ liệu",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(_email ?? "Không có dữ liệu"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _username != null ? _username![0].toUpperCase() : "U",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Icon(Icons.home, color: Colors.blue),
                    title: Text("Trang chủ"),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: Icon(Icons.person, color: Colors.blue),
                    title: Text("Hồ sơ cá nhân"),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.settings, color: Colors.blue),
                    title: Text("Cài đặt"),
                    onTap: () {},
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.exit_to_app, color: Colors.red),
                    title:
                        Text("Đăng xuất", style: TextStyle(color: Colors.red)),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Danh sách thiết bị:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: _devices.isEmpty
                  ? Center(
                      child: Text(
                          "Không có thiết bị nào")) // ✅ Hiển thị khi không có thiết bị
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.devices, color: Colors.green),
                            title: Text("Thiết bị: ${_devices[index]}"),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeviceDetailPage(
                                      deviceId:
                                          _devices[index]), // ✅ Truyền deviceId
                                ),
                              );
                              print("Nhấn vào thiết bị: ${_devices[index]}");
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
