// import 'package:flutter/material.dart';
// import 'package:iotapp/services/device_service.dart';

// class DeviceDetailPage extends StatefulWidget {
//   final String deviceId;
//   DeviceDetailPage({required this.deviceId});

//   @override
//   _DeviceDetailPageState createState() => _DeviceDetailPageState();
// }

// class _DeviceDetailPageState extends State<DeviceDetailPage> {
//   final DeviceService _deviceService = DeviceService();
//   Map<String, dynamic>? _deviceData;

//   @override
//   void initState() {
//     super.initState();
//     _loadDeviceData();
//   }

//   void _loadDeviceData() async {
//     Map<String, dynamic>? device =
//         await _deviceService.getDeviceById(widget.deviceId);
//     setState(() {
//       _deviceData = device;
//     });
//   }

//   // void _toggleDevicePower(bool value) async {
//   //   if (_deviceData == null) return;

//   //   bool newState = !_deviceData!['active'];
//   //   setState(() {
//   //     _deviceData!['active'] = newState;
//   //   });

//   //   bool success =
//   //       await _deviceService.toggleDevicePower(widget.deviceId, newState);
//   //   if (!success) {
//   //     setState(() {
//   //       _deviceData!['active'] =
//   //           !newState; // Nếu thất bại, hoàn tác lại trạng thái
//   //     });
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: Text("Thông tin thiết bị"),
//         centerTitle: true,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: _deviceData == null
//           ? Center(child: CircularProgressIndicator()) // ✅ Loading khi dữ liệu chưa có
//           : Container(
//               decoration: BoxDecoration(
//                 // gradient: LinearGradient(
//                 //   colors: [const Color.fromARGB(255, 235, 238, 244), const Color.fromARGB(255, 235, 238, 244)],
//                 //   begin: Alignment.topCenter,
//                 //   end: Alignment.bottomCenter,
//                 // ),
//               ),
//               child: SafeArea(
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // ✅ Thông tin thiết bị
//                       Card(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 4,
//                         child: Padding(
//                           padding: EdgeInsets.all(16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(Icons.devices, color: Colors.blue, size: 30),
//                                   SizedBox(width: 10),
//                                   Text(
//                                     "Tên: ${_deviceData!['deviceName']}",
//                                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                                   ),
//                                 ],
//                               ),
//                               SizedBox(height: 8),
//                               Row(
//                                 children: [
//                                   Icon(Icons.location_on, color: Colors.red, size: 24),
//                                   SizedBox(width: 10),
//                                   Text("Vị trí: ${_deviceData!['location']}",
//                                       style: TextStyle(fontSize: 18)),
//                                 ],
//                               ),
//                               SizedBox(height: 8),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       Icon(Icons.power_settings_new,
//                                           color: _deviceData!['active']
//                                               ? Colors.green
//                                               : Colors.red,
//                                           size: 24),
//                                       SizedBox(width: 10),
//                                       Text(
//                                         "Trạng thái: ${_deviceData!['active'] ? "Bật" : "Tắt"}",
//                                         style: TextStyle(
//                                             fontSize: 18,
//                                             color: _deviceData!['active']
//                                                 ? Colors.green
//                                                 : Colors.red),
//                                       ),
//                                     ],
//                                   ),
//                                   // Switch(
//                                   //   value: _deviceData!['active'],
//                                   //   onChanged: _toggleDevicePower,
//                                   // ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       SizedBox(height: 16),

//                       // ✅ Card chứa thông số cảm biến
//                       Card(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 4,
//                         child: Padding(
//                           padding: EdgeInsets.all(16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text("Thông số cảm biến",
//                                   style: TextStyle(
//                                       fontSize: 18, fontWeight: FontWeight.bold)),
//                               SizedBox(height: 8),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   _sensorItem("🌡️ Nhiệt độ", "${_deviceData!['temperature']}°C"),
//                                   _sensorItem("💧 Độ ẩm", "${_deviceData!['humidity']}%"),
//                                   _sensorItem("🔥 Mức khói", "${_deviceData!['smokeLevel']}"),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//     );
//   }

//   Widget _sensorItem(String label, String value) {
//     return Column(
//       children: [
//         Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
//         SizedBox(height: 4),
//         Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class DeviceDetailPage extends StatefulWidget {
  final String deviceId;
  final String userToken;

  DeviceDetailPage({required this.deviceId, required this.userToken});

  @override
  _DeviceDetailPageState createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  late WebSocketChannel _channel;
  Map<String, dynamic>? _deviceData;
  bool _isConnected = false;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    print("🟢 Token gửi lên WebSocket: ${widget.userToken}");
    _channel = WebSocketChannel.connect(Uri.parse("ws://192.168.1.7:3000"));

    _channel.sink.add(jsonEncode({
      "type": "authenticate",
      "token": widget.userToken,
      "deviceId": widget.deviceId
    }));

    _channel.stream.listen((message) {
      print("🔹 Nhận phản hồi từ WebSocket: $message");
      final data = jsonDecode(message);

      if (data['type'] == "auth_success") {
        print("✅ Xác thực WebSocket thành công!");
        setState(() {
          _isConnected = true;
          _isAuthorized = true;
        });
      } else if (data['type'] == "auth_error") {
        print("❌ Lỗi xác thực: ${data['message']}");
        _channel.sink.close();
      } else if (data['type'] == "device_data") {
        setState(() {
          _deviceData = data;
        });
      }
    }, onError: (error) {
      print("❌ Lỗi WebSocket: $error");
    });
  }

  void _toggleRelay(bool newState) {
    if (!_isConnected || !_isAuthorized) {
      debugPrint("⚠️ WebSocket chưa kết nối hoặc không có quyền!");
      return;
    }

    final command = jsonEncode({
      "type": "toggleRelay",
      "deviceId": widget.deviceId,
      "state": newState ? "on" : "off"
    });

    debugPrint("🚀 Gửi lệnh relay: $command");
    _channel.sink.add(command);

    setState(() {
      _deviceData?['relay'] = newState ? "on" : "off";
    });
  }

  @override
  void dispose() {
    if (_channel.closeCode == null) {
      _channel.sink.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Thông tin thiết bị")),
      body: !_isAuthorized
          ? Center(
              child: Text("🚫 Không có quyền truy cập thiết bị này!",
                  style: TextStyle(color: Colors.red, fontSize: 16)))
          : _deviceData == null
              ? Center(child: CircularProgressIndicator())
              : Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: [
                            _buildSensorCard("🌡️ Nhiệt độ",
                                "${_deviceData!['temperature']}°C", Colors.orange),
                            _buildSensorCard("💧 Độ ẩm",
                                "${_deviceData!['humidity']}%", Colors.blue),
                            _buildSensorCard("🔥 Mức khói",
                                "${_deviceData!['smokeLevel']}", Colors.red, isDanger: true),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        title: Text("🔌 Điều khiển relay"),
                        value: _deviceData?['relay'] == "on",
                        onChanged: _toggleRelay,
                        activeColor: Colors.green,
                        secondary: Icon(Icons.power_settings_new),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSensorCard(String title, String value, Color color,
    {bool isDanger = false}) {
  return Card(
    color: isDanger ? Colors.red.shade100 : (color is MaterialColor ? color.shade100 : color.withOpacity(0.2)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 3,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(isDanger ? Icons.warning : Icons.thermostat, size: 40, color: color),
        SizedBox(height: 10),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 18)),
      ],
    ),
  );
}

}
