import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iotapp/models/device_model.dart';
import 'package:iotapp/models/sensor_data.dart';
import 'package:iotapp/pages/add_device_page.dart';
import 'package:iotapp/pages/devicedetail_page.dart';
import 'package:iotapp/pages/edit_device_page.dart';
import 'package:iotapp/pages/login_page.dart';
import 'package:iotapp/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iotapp/services/device_service.dart';
import 'package:iotapp/services/sensor_data_service.dart';
import 'package:iotapp/theme/list_device_provider.dart';
import 'package:iotapp/widget/chart_widget.dart';
import 'package:iotapp/widget/home_drawer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final SensorService _sensorService = SensorService();
  final DeviceService _deviceService = DeviceService();
  String? _token;
  String? _username;
  String? _email;
  List<SensorData> _dailyData = [];
  Device? _selectedDevice;
  Map<String, List<SensorData>> _sensorDataMap = {};
  String? _expandedDeviceId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Khởi tạo dữ liệu người dùng và thiết bị
      await _initializeUserDataAndDevices();
      await loadDevices();
    });
  }

  Future<void> _initializeUserDataAndDevices() async {
    setState(() {
      _isLoading = true;
    });

    final token = await _authService.getToken();
    final userData = await _authService.getUserInfo();
    final deviceIds = await _authService.getUserDevices();

    if (!mounted) return;

    setState(() {
      _token = token;
      _username = userData?["username"];
      _email = userData?["email"];
      _isLoading = false;
    });

    final devices =
        deviceIds
            .map(
              (id) => Device(
                deviceId: id,
                deviceName: id,
                location: '',
                active: true,
              ),
            )
            .toList();

    Provider.of<DeviceListProvider>(context, listen: false).setDevices(devices);
  }

  void deleteDevice(BuildContext context, Device device) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _deviceService.deleteDevice(device.deviceId);
      setState(() {
        _sensorDataMap.remove(device.deviceId);
        _expandedDeviceId = null;
      });

      await loadDevices();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã xoá thiết bị: ${device.deviceName}"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Xoá thiết bị thất bại"),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void editDevice(BuildContext context, Device device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditDevicePage(device: device, userToken: _token!),
      ),
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  Future<void> loadDevices() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user');
      if (userDataString == null) throw Exception('User data không tồn tại');
      final userData = jsonDecode(userDataString);
      final userId = userData['userId'] as int;

      final devices = await _deviceService.getDevicesByUserId(userId);

      Map<String, List<SensorData>> tempSensorDataMap = {};

      for (var device in devices) {
        final data = await _sensorService.getSensorData(device.deviceId);
        tempSensorDataMap[device.deviceId] = data;
      }

      setState(() {
        _sensorDataMap = tempSensorDataMap;
        _isLoading = false;
      });

      Provider.of<DeviceListProvider>(
        context,
        listen: false,
      ).setDevices(devices);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onDeviceTap(Device device) async {
    if (_token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr("token_error"))));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                DeviceDetailPage(deviceId: device.deviceId, userToken: _token!),
      ),
    );
    setState(() {
      if (_expandedDeviceId == device.deviceId) {
        _expandedDeviceId = null; // Đóng lại
      } else {
        _expandedDeviceId = device.deviceId; // Mở ra
      }
    });
  }

  Future<void> _onAddDevice() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddDevicePage()),
    );
    if (added == true) {
      // Nếu trang AddDevicePage trả về true khi thêm thành công
      await loadDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('home')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.red,
            onPressed: _logout,
          ),
        ],
      ),
      drawer: HomeDrawer(
        username: _username,
        email: _email,
        authService: _authService,
        logoutCallback: _logout,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _initializeUserDataAndDevices,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Consumer<DeviceListProvider>(
                    builder: (context, deviceProvider, _) {
                      final devices = deviceProvider.devices;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Expanded(
                            child:
                                devices.isEmpty
                                    ? Center(child: Text(tr("no_devices")))
                                    : ListView.builder(
                                      itemCount: devices.length,
                                      itemBuilder: (context, index) {
                                        final device = devices[index];
                                        final sensorData =
                                            _sensorDataMap[device.deviceId] ??
                                            [];

                                        return Dismissible(
                                          key: Key(device.deviceId),
                                          direction:
                                              DismissDirection.endToStart,
                                          background: Container(
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            color: Colors.red,
                                          ),
                                          confirmDismiss: (direction) async {
                                            return await showDialog<bool>(
                                              context: context,
                                              builder:
                                                  (ctx) => AlertDialog(
                                                    title: const Text(
                                                      "Xác nhận xoá",
                                                    ),
                                                    content: const Text(
                                                      "Bạn có chắc muốn xoá thiết bị này không?",
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.of(
                                                              ctx,
                                                            ).pop(false),
                                                        child: const Text(
                                                          "Huỷ",
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.of(
                                                              ctx,
                                                            ).pop(true),
                                                        child: const Text(
                                                          "Xoá",
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                          },
                                          onDismissed: (direction) {
                                            deleteDevice(context, device);
                                          },
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 4,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  onTap:
                                                      () =>
                                                          _onDeviceTap(device),
                                                  child: ListTile(
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 8,
                                                        ),
                                                    leading: Icon(
                                                      Icons.devices,
                                                      color:
                                                          Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                    ),
                                                    title: Text(
                                                      "${tr("device")}: ${device.deviceName}",
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    trailing: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(
                                                            _expandedDeviceId ==
                                                                    device
                                                                        .deviceId
                                                                ? Icons
                                                                    .arrow_drop_up
                                                                : Icons
                                                                    .arrow_drop_down,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                          ),
                                                          onPressed: () {
                                                            setState(() {
                                                              if (_expandedDeviceId ==
                                                                  device
                                                                      .deviceId) {
                                                                _expandedDeviceId =
                                                                    null;
                                                              } else {
                                                                _expandedDeviceId =
                                                                    device
                                                                        .deviceId;
                                                              }
                                                            });
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.edit,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                          ),
                                                          onPressed: () {
                                                            editDevice(
                                                              context,
                                                              device,
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          
                                              const SizedBox(height: 20),
                                              if (_expandedDeviceId ==
                                                      device.deviceId &&
                                                  sensorData.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 16,
                                                      ),
                                                  child:
                                                      DailyTemperatureHumidityChart(
                                                        data: sensorData,
                                                      ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                          ),
                          const SizedBox(height: 16),
                          if (_dailyData.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              '${tr("device")} ${_selectedDevice?.deviceName ?? ""}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddDevice,
        tooltip: tr('add_device'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
