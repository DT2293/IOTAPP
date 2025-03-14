import 'package:flutter/material.dart';
import 'package:iotapp/models/device_model.dart';
import 'package:iotapp/services/device_service.dart';
import '../services/auth_service.dart';

class DeviceDetailPage extends StatefulWidget {
  final String deviceId;
  DeviceDetailPage({required this.deviceId});

  @override
  _DeviceDetailPageState createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  final DeviceService _deviceService = DeviceService();
  Map<String, dynamic>? _deviceData;

  @override
  void initState() {
    super.initState();
    _loadDeviceData();
  }

  void _loadDeviceData() async {
    Map<String, dynamic>? device = await _deviceService.getDeviceById(widget.deviceId);
    setState(() {
      _deviceData = device;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Thông tin thiết bị")),
      body: _deviceData == null
          ? Center(child: CircularProgressIndicator()) // ✅ Loading khi dữ liệu chưa có
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tên thiết bị: ${_deviceData!['deviceName']}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Vị trí: ${_deviceData!['location']}", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text("Trạng thái: ${_deviceData!['active'] ? "Hoạt động" : "Tắt"}", style: TextStyle(fontSize: 18, color: _deviceData!['active'] ? Colors.green : Colors.red)),
                  SizedBox(height: 8),
                  Text("Chủ sở hữu: ${_deviceData!['userId']['username']}", style: TextStyle(fontSize: 18)),
                  Text("Email: ${_deviceData!['userId']['email']}", style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
    );
  }
}
