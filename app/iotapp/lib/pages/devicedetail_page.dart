import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _relayState = false;
  Timer? _timeoutTimer;

  Future<void> saveRelayStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('relayStatus', status);
  }

  Future<bool> loadRelayStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('relayStatus') ?? false;
  }

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _startTimeout();
    _loadRelayStatus();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(Duration(seconds: 2), () {
      if (_deviceData == null) {
        setState(() {
          _deviceData = {};
        });
      }
    });
  }

  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(Uri.parse("ws://dungtc.iothings.vn:3000"));

    final authMessage = jsonEncode({
      "type": "authenticate",
      "token": widget.userToken,
    });
    print("🚀 Gửi yêu cầu xác thực: $authMessage");
    _channel.sink.add(authMessage);

    _channel.stream.listen((message) {
      print("🔹 Nhận phản hồi từ WebSocket: $message");
      final data = jsonDecode(message);

      if (data['type'] == "auth_success") {
        setState(() {
          _isConnected = true;
          _isAuthorized = true;
        });
        print("✅ Xác thực thành công!");
        _requestRelayStatus();
      } else if (data['type'] == "auth_error") {
        print("❌ Xác thực thất bại! Đóng kết nối.");
        _channel.sink.close();
      } else if (data['type'] == "sensordatas" && data['data']['deviceId'] == widget.deviceId) {
        setState(() {
          _deviceData = data['data'];
        });
        _startTimeout();
        print("📊 Cập nhật dữ liệu cảm biến: $_deviceData");
      } else if (data['type'] == "relayStatus" && data['deviceId'] == widget.deviceId) {
        print("🔌 Cập nhật trạng thái relay từ server: ${data['message']}");
        setState(() {
          _relayState = data['message'].contains("bật");
        });
      }
    }, onError: (error) {
      print("❌ Lỗi WebSocket: $error");
    });
  }

  void _requestRelayStatus() {
    final command = jsonEncode({
      "action": "getRelayStatus",
      "deviceId": widget.deviceId,
    });
    print("📡 Yêu cầu trạng thái relay: $command");
    _channel.sink.add(command);
  }

  void _toggleRelay(bool newState) {
    if (!_isConnected || !_isAuthorized) return;

    setState(() {
      _relayState = newState;
    });

    final command = jsonEncode({
      "action": "toggleRelay",
      "deviceId": widget.deviceId,
      "state": newState ? "on" : "off"
    });

    print("🚀 Gửi lệnh relay: $command");
    _channel.sink.add(command);

    saveRelayStatus(newState);
  }

  void _loadRelayStatus() async {
    bool status = await loadRelayStatus();
    setState(() {
      _relayState = status;
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("device_info"))),
      body: !_isAuthorized
          ? Center(
              child: Text(
                tr("user_info_error"),
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            )
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
                            _buildSensorCard(
                              tr("temperature"),
                              _deviceData!['temperature'] != null ? "${_deviceData!['temperature']}°C" : "--",
                              Colors.orange,
                            ),
                            _buildSensorCard(
                              tr("humidity"),
                              _deviceData!['humidity'] != null ? "${_deviceData!['humidity']}%" : "--",
                              Colors.blue,
                            ),
                            _buildSensorCard(
                              tr("smoke_level"),
                              _deviceData!['smokeLevel'] != null ? "${_deviceData!['smokeLevel']}" : "--",
                              Colors.red,
                              isDanger: true,
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        title: Text("🔌 ${tr("control_relay")}"),
                        value: _relayState,
                        onChanged: _toggleRelay,
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSensorCard(String title, String value, Color color, {bool isDanger = false}) {
    return Card(
      color: isDanger ? Colors.red.shade100 : color.withOpacity(0.2),
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
