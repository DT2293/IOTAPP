// // // import 'package:flutter/material.dart';
// // // import 'pages/login_page.dart';

// // // void main() {
// // //   runApp(MyApp());
// // // }

// // // class MyApp extends StatelessWidget {
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return MaterialApp(
// // //       debugShowCheckedModeBanner: false,
// // //       home: LoginPage(),
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:flutter_localizations/flutter_localizations.dart';
// // import 'package:iotapp/provider/language_provider.dart';
// // import 'package:iotapp/services/l10n.dart';
// // import 'package:provider/provider.dart';
// // import 'pages/login_page.dart';

// // import 'package:flutter/material.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:iotapp/services/l10n.dart';


// // void main() {
// //   runApp(const ProviderScope(child: MyApp()));
// // }

// // class MyApp extends ConsumerWidget {
// //   const MyApp({super.key});

// //   @override
// //   Widget build(BuildContext context, WidgetRef ref) {
// //     final locale = ref.watch(languageProvider);

// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       home: LoginPage(),
// //     );
// //   }
// // }



// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart'; // 🛠️ Thêm dòng này
// import 'package:iotapp/pages/login_page.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await EasyLocalization.ensureInitialized();

//   runApp(
//     EasyLocalization(
//       supportedLocales: [Locale('en', 'US'), Locale('vi', 'VN')],
//       path: 'assets/translations',
//       fallbackLocale: Locale('en', 'US'),
//       child: const ProviderScope(child: MyApp()),
//     ),
//   );
// }

// class MyApp extends ConsumerWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: LoginPage(),
//       locale: context.locale,
//       supportedLocales: context.supportedLocales,
//       localizationsDelegates: context.localizationDelegates,
//       builder: EasyLoading.init(), // 🔥 BẮT BUỘC phải có dòng này!
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:iotapp/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iotapp/theme/light_theme.dart';
import 'package:iotapp/theme/dark_theme.dart';
import 'package:iotapp/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en', 'US'), Locale('vi', 'VN')],
      path: 'assets/translations',
      fallbackLocale: Locale('en', 'US'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
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
      themeMode:
      themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: LoginPage(),
    );
  }
}
