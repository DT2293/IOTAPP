import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iotapp/theme/list_device_provider.dart';
import 'package:provider/provider.dart';
import 'package:iotapp/services/fcm_initializer.dart';
import 'package:iotapp/services/websocket_service.dart';
import 'package:iotapp/theme/message_provider.dart';
import 'package:iotapp/theme/theme_provider.dart';
import 'package:iotapp/theme/light_theme.dart';
import 'package:iotapp/theme/dark_theme.dart';
import 'package:iotapp/pages/splash_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase & Localization
  await Firebase.initializeApp();
  await EasyLocalization.ensureInitialized();

  // Khởi chạy ứng dụng
  runApp(
      EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('vi', 'VN')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => WebSocketProvider()),
          ChangeNotifierProvider(create: (_) => MessageProvider()),
          ChangeNotifierProvider(create: (_) => DeviceListProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );

  await Future.delayed(const Duration(milliseconds: 300));
  await FCMInitializer().init();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey, // Để dùng context trong lớp không có BuildContext
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


