import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageService {
  static void changeLanguage(BuildContext context, Locale locale) {
    EasyLocalization.of(context)?.setLocale(locale);
  }
}
