
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class WebSocketProvider with ChangeNotifier {
//   WebSocketChannel? _channel;
//   Map<String, dynamic> _deviceData = {};
//   bool _isConnected = false;
//   bool _isAuthorized = false;
//   bool _relayState = false;
//   String? _deviceId;
//   String? _token;

//   Map<String, dynamic> get deviceData => _deviceData;
//   bool get isConnected => _isConnected;
//   bool get isAuthorized => _isAuthorized;
//   bool get relayState => _relayState;

//   void initConnection({required String token, required String deviceId}) {
//     if (_isConnected) return;
//     _token = token;
//     _deviceId = deviceId;

//    //_channel = WebSocketChannel.connect(Uri.parse("ws://192.168.0.102:3000"));
//       _channel = WebSocketChannel.connect(Uri.parse("ws://dungtc.iothings.vn:3000"));

   
//     _channel!.sink.add(jsonEncode({
//       "type": "authenticate",
//       "token": _token,
//     }));

//     _channel!.stream.listen((message) {
//       final data = jsonDecode(message);

//       if (data['type'] == "auth_success") {
//         _isConnected = true;
//         _isAuthorized = true;
//        // _requestRelayStatus();
//         notifyListeners();
//       } else if (data['type'] == "auth_error") {
//         _channel!.sink.close();
//       } else if (data['type'] == "sensordatas" && data['data']['deviceId'] == _deviceId) {
//         _deviceData = data['data'];
//         notifyListeners();
//       } else if (data['type'] == "relayStatus" && data['deviceId'] == _deviceId) {
//         _relayState = data['message'].contains("bật");
//         notifyListeners();
//       }
//     }, onError: (e) {
//       print("❌ WebSocket error: $e");
//     });
//   }

//   void _requestRelayStatus() {
//     _channel?.sink.add(jsonEncode({
//       "action": "getRelayStatus",
//       "deviceId": _deviceId,
//     }));
//   }

//   void toggleRelay(bool newState) {
//     if (!_isConnected || !_isAuthorized || _deviceId == null) return;

//     _relayState = newState;
//     notifyListeners();

//     _channel?.sink.add(jsonEncode({
//       "action": "toggleRelay",
//       "deviceId": _deviceId,
//       "state": newState ? "on" : "off"
//     }));
//  }

//   void disconnect() {
//     _channel?.sink.close();
//     _isConnected = false;
//     _isAuthorized = false;
//     notifyListeners();
//   }
// }


import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketProvider with ChangeNotifier {
  WebSocketChannel? _channel;
  Map<String, dynamic> _deviceData = {};
  bool _isConnected = false;
  bool _isAuthorized = false;
  bool _relayState = false;
  bool _alarmOn = false; // 🔔 Trạng thái còi

  String? _deviceId;
  String? _token;

  Map<String, dynamic> get deviceData => _deviceData;
  bool get isConnected => _isConnected;
  bool get isAuthorized => _isAuthorized;
  bool get relayState => _relayState;
  bool get alarmOn => _alarmOn;

  void initConnection({required String token, required String deviceId}) {
    if (_isConnected) return;
    _token = token;
    _deviceId = deviceId;

    _channel = WebSocketChannel.connect(Uri.parse("ws://dungtc.iothings.vn:3000"));

    _channel!.sink.add(jsonEncode({
      "type": "authenticate",
      "token": _token,
    }));

    _channel!.stream.listen((message) {
      final data = jsonDecode(message);

      if (data['type'] == "auth_success") {
        _isConnected = true;
        _isAuthorized = true;
        notifyListeners();
      } else if (data['type'] == "auth_error") {
        _channel!.sink.close();
      } else if (data['type'] == "sensordatas" && data['data']['deviceId'] == _deviceId) {
        _deviceData = data['data'];
        notifyListeners();
      } else if (data['type'] == "relayStatus" && data['deviceId'] == _deviceId) {
        _relayState = data['message'].contains("bật");
        notifyListeners();
      } else if (data['type'] == "alarm_command") {
        _alarmOn = data['command'] == "alarm_on";
        notifyListeners();
      }
    }, onError: (e) {
      print("❌ WebSocket error: $e");
    });
  }

  void toggleRelay(bool newState) {
    if (!_isConnected || !_isAuthorized || _deviceId == null) return;

    _relayState = newState;
    notifyListeners();

    _channel?.sink.add(jsonEncode({
      "action": "toggleRelay",
      "deviceId": _deviceId,
      "state": newState ? "on" : "off"
    }));
  }

 void sendAlarmCommand(bool turnOn) {
  if (!_isConnected || !_isAuthorized || _deviceId == null) return;

  final command = {
    "type": "alarm_command",
    "command": turnOn ? "alarm_on" : "alarm_off",
    "deviceId": _deviceId, // 👉 thêm dòng này!
  };

  print("📤 Gửi alarm command: $command"); // ✅ Log kiểm tra

  _channel?.sink.add(jsonEncode(command));

  _alarmOn = turnOn;
  notifyListeners();
}

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _isAuthorized = false;
    notifyListeners();
  }
}



