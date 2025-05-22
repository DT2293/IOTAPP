import 'package:flutter/material.dart';
import 'package:iotapp/models/device_model.dart';

class DeviceListProvider extends ChangeNotifier {
  List<Device> _devices = [];

  List<Device> get devices => _devices;

  void setDevices(List<Device> devices) {
    _devices = devices;
    notifyListeners();
  }
}
