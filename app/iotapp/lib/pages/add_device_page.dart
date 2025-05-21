import 'package:flutter/material.dart';

class AddDevicePage extends StatefulWidget {

  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  late TextEditingController _deviceIdController;

  @override
  void initState() {
    super.initState();
    _deviceIdController = TextEditingController(text: "sss");
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm thiết bị")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _deviceIdController,
              decoration: const InputDecoration(
                labelText: "Device ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: gửi request thêm thiết bị nếu cần
              },
              child: const Text("Lưu thiết bị"),
            )
          ],
        ),
      ),
    );
  }
}
