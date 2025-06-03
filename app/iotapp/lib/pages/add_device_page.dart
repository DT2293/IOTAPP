import 'package:flutter/material.dart';
import 'package:iotapp/pages/qrscan_page.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart'; // thêm dòng này
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

      final deviceListProvider = Provider.of<DeviceListProvider>(
        context,
        listen: false,
      );
      deviceListProvider.setDevices([...deviceListProvider.devices, newDevice]);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('add_device_success'))));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ ${tr('add_device_fail')}')));
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(tr('add_device'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextFormField(
                    controller: _deviceIdController,
                    decoration: InputDecoration(
                      labelText: tr('device_id'),
                      prefixIcon: GestureDetector(
                        onTap: () async {
                          final scannedId = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => QRScanPage(
                                    onScanned: (code) {
                                      Navigator.pop(context, code);
                                    },
                                  ),
                            ),
                          );
                          if (scannedId != null && scannedId is String) {
                            _deviceIdController.text = scannedId;
                          }
                        },
                        child: const Icon(Icons.qr_code),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? tr('please_enter_device_id')
                                : null,
                  ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deviceNameController,
                    decoration: InputDecoration(
                      labelText: tr('device_name'),
                      prefixIcon: const Icon(Icons.devices),
                      border: const OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? tr('please_enter_device_name')
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: tr('location'),
                      prefixIcon: const Icon(Icons.location_on),
                      border: const OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? tr('please_enter_location')
                                : null,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: _active,
                    onChanged: (val) => setState(() => _active = val),
                    title: Text(tr('active')),
                    secondary: const Icon(Icons.toggle_on),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      onPressed: _isLoading ? null : _addDevice,
                      icon: const Icon(Icons.add),
                      label:
                          _isLoading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                tr('add_device_button'),
                                style: const TextStyle(fontSize: 16),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
