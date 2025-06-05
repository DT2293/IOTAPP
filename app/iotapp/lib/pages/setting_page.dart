import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iotapp/pages/login_page.dart';
import 'package:iotapp/pages/updatepassword_page.dart';
import 'package:iotapp/services/auth_service.dart';
import 'package:iotapp/services/language_service.dart';
import 'package:iotapp/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final AuthService _authService = AuthService();
  bool isDarkMode = false;
  String appVersion = '';

  @override
  void initState() {
    super.initState();
  }

  void _logout() async {
    await _authService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Locale currentLocale = context.locale;

    return Scaffold(
      appBar: AppBar(title: Text(tr('settings')), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSectionTitle(tr('general')),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.language,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(tr('language')),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<Locale>(
                      value: currentLocale,
                      // onChanged: (Locale? locale) {
                      //   if (locale != null) {
                      //     LanguageService.changeLanguage(context, locale);
                      //   }
                      // },
                      onChanged: (Locale? locale) {
  if (locale != null) {
    LanguageService.changeLanguage(context, locale);
  }
},                   
                      items: [
                        DropdownMenuItem(
                          value: Locale('en', 'US'),
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: Locale('vi', 'VN'),
                          child: Text('Tiếng Việt'),
                        ),
                      ],
                    ),
                  ),
                ),
                SwitchListTile(
                  secondary: Icon(
                    Icons.brightness_6_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(tr('dark_mode')),
                  value: context.watch<ThemeProvider>().isDarkMode,
                  onChanged: (bool value) {
                    context.read<ThemeProvider>().toggleTheme(value);
                  },
                ),
              ],
            ),
          ),

          _buildSectionTitle(tr('account')),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.lock_outline, color: Colors.orange),
                  title: Text(tr('change_password')),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdatePasswordPage(),
                        ),
                      ),
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.redAccent),
                  title: Text(tr('logout')),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _logout,
                ),
              ],
            ),
          ),

          _buildSectionTitle(tr('about')),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(Icons.info_outline, color: Colors.blue),
              title: Text(tr('app_version')),
              subtitle: Text(appVersion),
            ),
          ),
        ],
      ),
    );
  }
}
