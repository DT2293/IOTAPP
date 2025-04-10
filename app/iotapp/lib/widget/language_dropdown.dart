import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageDropdown extends StatefulWidget {
  const LanguageDropdown({Key? key}) : super(key: key);

  @override
  State<LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  @override
  Widget build(BuildContext context) {
    Locale currentLocale = context.locale;

    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language),
      tooltip: tr("change_language"), // Nếu bạn có key "change_language" trong JSON
      onSelected: (locale) {
        context.setLocale(locale);
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: const Locale('en', 'US'),
          child: Text("English"),
        ),
        PopupMenuItem(
          value: const Locale('vi', 'VN'),
          child: Text("Tiếng Việt"),
        ),
      ],
    );
  }
}
