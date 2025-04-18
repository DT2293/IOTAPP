
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebSocketProvider with ChangeNotifier {
  WebSocketChannel? _channel;
  Map<String, dynamic> _deviceData = {};
  bool _isConnected = false;
  bool _isAuthorized = false;
  bool _relayState = false;
  String? _deviceId;
  String? _token;

  Map<String, dynamic> get deviceData => _deviceData;
  bool get isConnected => _isConnected;
  bool get isAuthorized => _isAuthorized;
  bool get relayState => _relayState;

  void initConnection({required String token, required String deviceId}) {
    if (_isConnected) return;
    _token = token;
    _deviceId = deviceId;

    _channel = WebSocketChannel.connect(Uri.parse("ws://192.168.1.14:3000"));
    _channel!.sink.add(jsonEncode({
      "type": "authenticate",
      "token": _token,
    }));

    _channel!.stream.listen((message) {
      final data = jsonDecode(message);

      if (data['type'] == "auth_success") {
        _isConnected = true;
        _isAuthorized = true;
        _requestRelayStatus();
        notifyListeners();
      } else if (data['type'] == "auth_error") {
        _channel!.sink.close();
      } else if (data['type'] == "sensordatas" && data['data']['deviceId'] == _deviceId) {
        _deviceData = data['data'];
        notifyListeners();
      } else if (data['type'] == "relayStatus" && data['deviceId'] == _deviceId) {
        _relayState = data['message'].contains("bật");
        notifyListeners();
      }
    }, onError: (e) {
      print("❌ WebSocket error: $e");
    });
  }

  void _requestRelayStatus() {
    _channel?.sink.add(jsonEncode({
      "action": "getRelayStatus",
      "deviceId": _deviceId,
    }));
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

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _isAuthorized = false;
    notifyListeners();
  }
}
