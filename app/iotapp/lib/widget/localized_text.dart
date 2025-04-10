import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LocalizedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const LocalizedText(
    this.text, { 
    Key? key, 
    this.style, 
    this.textAlign 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.tr(),  // Tự động dịch
      style: style,
      textAlign: textAlign,
    );
  }
}
