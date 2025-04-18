import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:iotapp/services/fcm_initializer.dart'; // import FCMInitializer
import 'package:easy_localization/easy_localization.dart';
import 'package:iotapp/services/websocket_service.dart';
import 'package:provider/provider.dart';
import 'package:iotapp/theme/theme_provider.dart';
import 'package:iotapp/theme/light_theme.dart';
import 'package:iotapp/theme/dark_theme.dart';
import 'package:iotapp/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase và các dịch vụ khác
  await _initializeApp();

  // Chạy ứng dụng
  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en', 'US'), Locale('vi', 'VN')],
      path: 'assets/translations',
      fallbackLocale: Locale('en', 'US'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => WebSocketProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

Future<void> _initializeApp() async {
  await Firebase.initializeApp(); // Khởi tạo Firebase
  await EasyLocalization.ensureInitialized(); // Khởi tạo localization
  
  // Khởi tạo FCM
  FCMInitializer fcmInitializer = FCMInitializer();
  await fcmInitializer.init(); // Thay userId bằng số thực tế, ví dụ 123 // Gọi phương thức init() để khởi tạo FCM
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IoT App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const SplashPage(),
    );
  }
}
