import 'package:flutter/material.dart';
import 'package:iotapp/models/device_model.dart';
import 'package:iotapp/pages/add_device_page.dart';
import 'package:iotapp/pages/chart_page.dart';
import 'package:iotapp/pages/devicedetail_page.dart';
import 'package:iotapp/pages/message_page.dart';
import 'package:iotapp/pages/profile_page.dart';
import 'package:iotapp/pages/setting_page.dart';
import 'package:iotapp/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iotapp/theme/list_device_provider.dart';

import 'package:provider/provider.dart';
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
  String? _email; // Thay thế bằng ID thiết bị mặc định hoặc từ dữ liệu người dùng
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserDataAndDevices();
    });
  }

  Future<void> _initializeUserDataAndDevices() async {
    final token = await _authService.getToken();
    final userData = await _authService.getUserInfo();
    final deviceIds = await _authService.getUserDevices();

    // Cập nhật trạng thái người dùng
    if (mounted) {
      setState(() {
        _token = token;
        _username = userData?["username"];
        _email = userData?["email"];
      });
    }

    // Tạo danh sách thiết bị và cập nhật provider
    final devices =
        deviceIds
            .map(
              (id) => Device(
                deviceId: id,
                deviceName: id,
                location: '',
                active: true,
              ),
            )
            .toList();

    Provider.of<DeviceListProvider>(context, listen: false).setDevices(devices);
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách thiết bị từ provider, UI sẽ tự build lại khi danh sách thay đổi
    final devices = Provider.of<DeviceListProvider>(context).devices;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('home')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.red,
            onPressed: _logout,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      // phần khác không đổi
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
              child:
                  devices.isEmpty
                      ? Center(child: Text(tr("no_devices")))
                      : ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final userToken = await _authService.getToken();
                                if (userToken != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => DeviceDetailPage(
                                            deviceId: device.deviceId,
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

                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Icon(
                                  Icons.devices,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                title: Text(
                                  "${tr("device")}: ${device.deviceName}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final added = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddDevicePage()),
                  );
                  // Nếu bạn đã cập nhật provider trong AddDevicePage rồi thì không cần gọi lại
                  // _initializeUserDataAndDevices();
                },
                icon: const Icon(Icons.add),
                label: Text(tr("add_device")),
              ),
            ),
            const SizedBox(height: 16),
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
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildDrawerItem(Icons.home, tr('home'), () {
                  Navigator.pop(context);
                }),
                _buildDrawerItem(Icons.message, tr('message'), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MessagePage()),
                  );
                }),
                _buildDrawerItem(Icons.person, tr('profile'), () async {
                  final token = await _authService.getToken();
                  final userData = await _authService.getUserInfo();

                  if (token != null && userData != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ProfilePage(
                              userId: userData["userId"] ?? "",
                              username: userData["username"] ?? "",
                              phone: List<String>.from(
                                userData["phonenumber"] ?? [],
                              ),
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
                _buildDrawerItem(Icons.bar_chart, tr('statistics'), () {
                  final devices = Provider.of<DeviceListProvider>(context, listen: false).devices;
                  if (devices.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('no_devices'))),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChartPage()),
                  );
                }),

                _buildDrawerItem(Icons.settings, tr('settings'), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SettingPage()),
                  );
                }),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: Text(
                    tr('logout'),
                    style: const TextStyle(color: Colors.red),
                  ),
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
