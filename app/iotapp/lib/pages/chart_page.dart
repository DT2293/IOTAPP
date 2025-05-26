import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iotapp/models/device_model.dart';
import 'package:iotapp/models/sensor_data.dart';
import 'package:iotapp/services/device_service.dart';
import 'package:iotapp/services/sensor_data_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({Key? key}) : super(key: key);

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final DeviceService _deviceService = DeviceService();
  final SensorService _sensorService = SensorService();

  List<Device> deviceList = [];
  Device? selectedDevice;

  List<SensorData> sensorDataList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
     print('📲 ChartPage khởi tạo...');
    loadDevices();
  }

  List<SensorData> getRecentSensorData(int days) {
  final now = DateTime.now();
  final recent = sensorDataList.where((data) {
    return data.date.isAfter(now.subtract(Duration(days: days)));
  }).toList();
  print('📅 Dữ liệu cảm biến trong $days ngày gần đây: ${recent.length} bản ghi');
  return recent;
}

Future<void> loadDevices() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user');
    print('📦 userData raw: $userDataString');
    if (userDataString == null) throw Exception('User data không tồn tại');
    final userData = jsonDecode(userDataString);
    final userId = userData['userId'] as int;
    print('👤 Đang tải thiết bị cho userId: $userId');

    final devices = await _deviceService.getDevicesByUserId(userId);
    print('📡 Thiết bị nhận được: ${devices.length}');

    setState(() {
      deviceList = devices;
      if (devices.isNotEmpty) {
        selectedDevice = devices.first;
        print('✅ Thiết bị đầu tiên được chọn: ${selectedDevice?.deviceName ?? selectedDevice?.deviceId}');
        loadSensorData(devices.first.deviceId);
      }
      isLoading = false;
    });
  } catch (e) {
    print('❌ Lỗi tải thiết bị: $e');
    setState(() => isLoading = false);
  }
}


 Future<void> loadSensorData(String deviceId) async {
  setState(() => isLoading = true);
  print('📈 Đang tải dữ liệu cảm biến cho thiết bị: $deviceId');
  try {
    final data = await _sensorService.getSensorData(deviceId);
    print('📊 Dữ liệu cảm biến nhận được: ${data.length} bản ghi');
    setState(() {
      sensorDataList = data;
      isLoading = false;
    });
  } catch (e) {
    print('❌ Lỗi tải dữ liệu cảm biến: $e');
    setState(() => isLoading = false);
  }
}


List<FlSpot> generateSpots(List<double?> values) {
  List<FlSpot> spots = [];
  for (int i = 0; i < values.length; i++) {
    final y = values[i] ?? 0;
    spots.add(FlSpot(i.toDouble(), y));
  }
  return spots;
}


  List<String> getDateLabels(List<SensorData> data) {
    final formatter = DateFormat('MM-dd');
    return data.map((e) => formatter.format(e.date)).toList();
  }

  @override
  Widget build(BuildContext context) {
    //final dateLabels = getDateLabels();
    final recentData = getRecentSensorData(7);
    final dateLabels = getDateLabels(recentData);

    print("Nhiệt độ: ${recentData.map((e) => e.averageTemperature).toList()}");
print("Độ ẩm: ${recentData.map((e) => e.averageHumidity).toList()}");
print("Khói: ${recentData.map((e) => e.averageSmokeLevel).toList()}");
print("Labels: $dateLabels");

    return Scaffold(
      appBar: AppBar(title: const Text("Biểu đồ cảm biến")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dropdown chọn thiết bị
            DropdownButton<Device>(
              isExpanded: true,
              value: selectedDevice,
              hint: const Text("Chọn thiết bị"),
              items:
                  deviceList.map((device) {
                    return DropdownMenuItem<Device>(
                      value: device,
                      child: Text(device.deviceName ?? device.deviceId),
                    );
                  }).toList(),
              onChanged: (device) {
                setState(() {
                  selectedDevice = device;
                  sensorDataList = [];
                  if (device != null) {
                    loadSensorData(device.deviceId);
                  }
                });
              },
            ),

            const SizedBox(height: 24),

            // Loading indicator
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (sensorDataList.isEmpty)
              const Expanded(
                child: Center(child: Text("Không có dữ liệu cảm biến")),
              )
            else
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < dateLabels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  dateLabels[index],
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      // Nhiệt độ - đỏ
                      LineChartBarData(
                        spots: generateSpots(
                          recentData.map((e) => e.averageTemperature).toList(),
                        ),
                        isCurved: true,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        gradient: const LinearGradient(
                          colors: [Colors.red, Colors.orange],
                        ),
                      ),

                      // Độ ẩm - xanh dương
                      LineChartBarData(
                        spots: generateSpots(
                          recentData.map((e) => e.averageHumidity).toList(),
                        ),
                        isCurved: true,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        gradient: const LinearGradient(
                          colors: [Colors.blue, Colors.lightBlueAccent],
                        ),
                      ),

                      LineChartBarData(
                        spots: generateSpots(
                          recentData
                              .map((e) => e.averageSmokeLevel.toDouble())
                              .toList(),
                        ),
                        isCurved: true,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        gradient: const LinearGradient(
                          colors: [Colors.green, Colors.lightGreen],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
