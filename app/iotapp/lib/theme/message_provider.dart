import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iotapp/models/message_model.dart';

class MessageProvider extends ChangeNotifier {
  List<Message> _messages = [];

  List<Message> get messages => _messages;

  MessageProvider() {
    _loadMessages();
  }

  void addMessage(Message message) {
    _messages.add(message);
    _saveMessages();
    notifyListeners();
  }

  void markAsRead(DateTime timestamp) {
    final msg = _messages.firstWhere((m) => m.timestamp == timestamp);
    msg.isRead = true;
    _saveMessages();
    notifyListeners();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('messages') ?? [];
    final now = DateTime.now();

    _messages = data
        .map((e) => Message.fromJson(json.decode(e)))
        .where((msg) => now.difference(msg.timestamp).inHours < 24)
        .toList();

    _saveMessages(); // dọn những tin đã quá hạn
    notifyListeners();
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _messages.map((m) => json.encode(m.toJson())).toList();
    await prefs.setStringList('messages', list);
  }
}
