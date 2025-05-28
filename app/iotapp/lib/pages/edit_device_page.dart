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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('edit_device'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.devices, size: 80, color: primaryColor),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _deviceNameController,
              label: 'device_name'.tr(),
              icon: Icons.device_hub,
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _locationController,
              label: 'location'.tr(),
              icon: Icons.location_on,
              theme: theme,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.toggle_on, color: primaryColor),
                const SizedBox(width: 8),
                Text('active'.tr(), style: TextStyle(fontSize: 16)),
                Spacer(),
                Switch(
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  activeColor: primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _updateDevice,
              icon: Icon(Icons.save),
              label: Text('update_info'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor ?? (theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100]),
      ),
    );
  }
}