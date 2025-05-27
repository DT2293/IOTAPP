import 'package:flutter/material.dart';
import 'package:iotapp/models/device_model.dart';

class EditDevicePage extends StatelessWidget {
  final Device device;

  const EditDevicePage({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    // UI chỉnh sửa device ở đây
    return Scaffold(
      appBar: AppBar(title: Text('Edit Device')),
      body: Center(
        child: Text('Edit device: ${device.deviceName}'),
      ),
    );
  }
}
