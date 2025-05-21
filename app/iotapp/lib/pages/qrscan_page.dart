// qr_scan_page.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanPage extends StatelessWidget {
  final Function(String) onScanned;

  const QRScanPage({super.key, required this.onScanned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét QR thiết bị')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          if (barcode.rawValue != null) {
            final String code = barcode.rawValue!;
            onScanned(code);
            Navigator.pop(context); // đóng trang quét
          }
        },
      ),
    );
  }
}
