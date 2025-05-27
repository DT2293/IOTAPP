import 'package:flutter/material.dart';
import 'package:iotapp/models/device_model.dart';
import 'package:iotapp/services/device_service.dart';
import 'package:easy_localization/easy_localization.dart';

class EditDevicePage extends StatefulWidget {
  final Device device;
  final String userToken;

  const EditDevicePage({super.key, required this.device, required this.userToken});

  @override
  _EditDevicePageState createState() => _EditDevicePageState();
}

class _EditDevicePageState extends State<EditDevicePage> {
  late TextEditingController _deviceNameController;
  late TextEditingController _locationController;
  bool _isActive = false;

  final DeviceService deviceService = DeviceService();

  @override
  void initState() {
    super.initState();
    _deviceNameController = TextEditingController(text: widget.device.deviceName);
    _locationController = TextEditingController(text: widget.device.location);
    _isActive = widget.device.active;
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _updateDevice() async {
  try {
    await deviceService.updateDevice(
      widget.device.deviceId,
      Device(
        deviceId: widget.device.deviceId,
        deviceName: _deviceNameController.text.trim(),
        location: _locationController.text.trim(),
        active: _isActive,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('update_success'.tr())),
    );
    Navigator.pop(context, true);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('update_failed'.tr() + ': ${e.toString()}')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('edit_device'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _deviceNameController,
              decoration: InputDecoration(
                labelText: 'device_name'.tr(),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'location'.tr(),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text('active'.tr()),
                Switch(
                  value: _isActive,
                  onChanged: (val) {
                    setState(() {
                      _isActive = val;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _updateDevice,
              child: Text('update_info'.tr()),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
