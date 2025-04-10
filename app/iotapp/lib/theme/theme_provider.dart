// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// class ThemeProvider extends ChangeNotifier {
//   ThemeMode _themeMode = ThemeMode.light;

//   ThemeMode get themeMode => _themeMode;
//   bool get isDarkMode => _themeMode == ThemeMode.dark;

//   void toggleTheme(bool isOn) {
//     _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
//     notifyListeners();
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = ChangeNotifierProvider<ThemeProvider>((ref) => ThemeProvider());

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

