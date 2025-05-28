
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:iotapp/pages/message_page.dart';
import 'package:iotapp/pages/profile_page.dart';
import 'package:iotapp/pages/setting_page.dart';
import 'package:iotapp/services/auth_service.dart';

class HomeDrawer extends StatelessWidget {
  final String? username;
  final String? email;
  final AuthService authService;
  final VoidCallback logoutCallback;

  const HomeDrawer({
    required this.username,
    required this.email,
    required this.authService,
    required this.logoutCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color.fromARGB(255, 79, 9, 82), const Color.fromARGB(121, 108, 9, 88)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              username ?? tr('no_data'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(email ?? tr('no_data')),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                username != null && username!.isNotEmpty
                    ? username![0].toUpperCase()
                    : "U",
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
                _buildDrawerItem(
                  context,
                  icon: Icons.home,
                  title: tr('home'),
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.message,
                  title: tr('message'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MessagePage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person,
                  title: tr('profile'),
                  onTap: () async {
                    final token = await authService.getToken();
                    final userData = await authService.getUserInfo();

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
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: tr('settings'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SettingPage()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: Text(
                    tr('logout'),
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: logoutCallback,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      onTap: onTap,
    );
  }
}
