import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iotapp/models/device_model.dart';
import 'package:iotapp/services/device_service.dart';
import 'package:iotapp/theme/list_device_provider.dart';
class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();
  final _deviceNameController = TextEditingController();
  final _locationController = TextEditingController();

  final DeviceService _deviceService = DeviceService();

  bool _active = true;
  bool _isLoading = false;

  Future<void> _addDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final newDevice = Device(
      deviceId: _deviceIdController.text.trim(),
      deviceName: _deviceNameController.text.trim(),
      location: _locationController.text.trim(),
      active: _active,
    );

    try {
      await _deviceService.addDevice(newDevice);

      // Cập nhật danh sách trong Provider
      final deviceListProvider = Provider.of<DeviceListProvider>(context, listen: false);
      deviceListProvider.setDevices([
        ...deviceListProvider.devices,
        newDevice,
      ]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Thiết bị được thêm thành công!')),
      );

      Navigator.pop(context, true); // quay lại HomePage và báo thành công
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _deviceNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm Thiết Bị')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _deviceIdController,
                decoration: const InputDecoration(labelText: 'Device ID'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Vui lòng nhập device ID'
                    : null,
              ),
              TextFormField(
                controller: _deviceNameController,
                decoration: const InputDecoration(labelText: 'Tên thiết bị'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Vui lòng nhập tên'
                    : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Vị trí'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Vui lòng nhập vị trí'
                    : null,
              ),
              SwitchListTile(
                value: _active,
                onChanged: (val) => setState(() => _active = val),
                title: const Text('Kích hoạt'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _addDevice,
                icon: const Icon(Icons.add),
                label: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Thêm Thiết Bị'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
