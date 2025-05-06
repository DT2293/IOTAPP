import 'package:flutter/material.dart';
import 'package:iotapp/pages/devicedetail_page.dart';
import 'package:iotapp/pages/message_page.dart';
import 'package:iotapp/pages/profile_page.dart';
import 'package:iotapp/pages/setting_page.dart';
import 'package:iotapp/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  String? _token;
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
    List<String> devices = await _authService.getUserDevices();
    setState(() {
      _token = token;
      _username = userData?["username"];
      _email = userData?["email"];
      _devices = devices;
    });
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('home')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),color: Colors.red,
            onPressed: _logout,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr("device_list"),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _devices.isEmpty
                  ? Center(child: Text(tr("no_devices")))
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(Icons.devices, color: Theme.of(context).colorScheme.primary),
                            title: Text(
                              "${tr("device")}: ${_devices[index]}",
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () async {
                              String? userToken = await _authService.getToken();
                              if (userToken != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DeviceDetailPage(
                                      deviceId: _devices[index],
                                      userToken: userToken,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(tr("token_error"))),
                                );
                              }
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
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
              _username ?? tr('no_data'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(_email ?? tr('no_data')),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _username != null ? _username![0].toUpperCase() : "U",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildDrawerItem(Icons.home, tr('home'), () => Navigator.pop(context)),
                _buildDrawerItem(Icons.message, tr('message'), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagePage()));
                }),
                _buildDrawerItem(Icons.person, tr('profile'), () async {
                  String? token = await _authService.getToken();
                  Map<String, dynamic>? userData = await _authService.getUserInfo();

                  if (userData != null && token != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(
                          userId: userData["userId"] ?? "",
                          username: userData["username"] ?? "",
                          email: userData["email"] ?? "",
                          token: token,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('user_info_error'))),
                    );
                  }
                }),
                _buildDrawerItem(Icons.settings, tr('settings'), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SettingPage()));
                }),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: Text(tr('logout'), style: const TextStyle(color: Colors.red)),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      onTap: onTap,
    );
  }
}
