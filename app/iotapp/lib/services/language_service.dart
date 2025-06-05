import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// class LanguageService {
//   static void changeLanguage(BuildContext context, Locale locale) {
//     EasyLocalization.of(context)?.setLocale(locale);
//   }
// }
class LanguageService {
  static Future<void> changeLanguage(BuildContext context, Locale newLocale) async {
    context.setLocale(newLocale);
    final languageCode = newLocale.languageCode;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final dio = Dio();
      await dio.post(
        'https://dungtc.iothings.vn/api/auth/update-language',
        data: {'language': languageCode},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );
      print("✅ Ngôn ngữ đã cập nhật lên server: $languageCode");
    } catch (e) {
      print("❌ Lỗi cập nhật ngôn ngữ: $e");
    }
  }
}

