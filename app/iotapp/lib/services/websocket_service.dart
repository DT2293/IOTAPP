import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class WebSocketProvider with ChangeNotifier {
  WebSocketChannel? _channel;

  WebSocketChannel? get channel => _channel;

  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    notifyListeners();
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    notifyListeners();
  }
}
// Future<void> saveRelayStatus(bool status) async {
//   final prefs = await SharedPreferences.getInstance();
//   prefs.setBool('relayStatus', status);
// }

// Future<bool> loadRelayStatus() async {
//   final prefs = await SharedPreferences.getInstance();
//   return prefs.getBool('relayStatus') ?? false;  // Mặc định là `false` (off)
// }

