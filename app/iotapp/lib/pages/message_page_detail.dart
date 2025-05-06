import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class MessagePageDetail extends StatelessWidget {
  final String message;

  const MessagePageDetail({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    String temperatureStr = "0";
    String smokeLevelStr = "0";

    final contentParts = message.split(',');

    if (contentParts.isNotEmpty && contentParts[0].contains('Nhiệt độ')) {
      final tempParts = contentParts[0].split(':');
      temperatureStr = tempParts.length > 1
          ? tempParts[1].replaceAll(RegExp(r'[^0-9.]'), '')
          : "0";
    }

    if (contentParts.length > 1 && contentParts[1].contains('Khói')) {
      final smokeParts = contentParts[1].split(':');
      smokeLevelStr = smokeParts.length > 1
          ? smokeParts[1].replaceAll(RegExp(r'[^0-9]'), '')
          : "0";
    }

    final double temperature = double.tryParse(temperatureStr) ?? 0;
    final int smokeLevel = int.tryParse(smokeLevelStr) ?? 0;
    final bool isDanger = temperature >= 50.0 || smokeLevel >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr("message_detail")),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${tr('temperature')}: $temperatureStr°C, ${tr('smoke_level')}: $smokeLevelStr',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (isDanger)
              Text(
                tr("danger_alert"),
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}


 // Dùng regex để parse số
    // final RegExp tempRegex = RegExp(r'Nhiệt độ\s*:\s*(\d+(\.\d+)?)');
    // final RegExp smokeRegex = RegExp(r'Khói\s*:\s*(\d+)');

    // final tempMatch = tempRegex.firstMatch(message);
    // final smokeMatch = smokeRegex.firstMatch(message);

    // double temperature = tempMatch != null ? double.parse(tempMatch.group(1)!) : 0;
    // int smokeLevel = smokeMatch != null ? int.parse(smokeMatch.group(1)!) : 0;
