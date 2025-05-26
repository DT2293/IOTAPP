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
    loadDevices();
  }

  List<SensorData> getRecentSensorData(int days) {
    final now = DateTime.now();
    return sensorDataList.where((data) {
      return data.date.isAfter(now.subtract(Duration(days: days)));
    }).toList();
  }

  //   Future<void> loadDevices() async {
  //     try {
  //       SharedPreferences prefs = await SharedPreferences.getInstance();
  //       final userDataString = prefs.getString('user');
  //       if (userDataString == null) throw Exception('User data không tồn tại');
  //       final userData = jsonDecode(userDataString);
  //       final userId = userData['userId'] as int;

  //       final devices = await _deviceService.getDevicesByUserId(userId);

  //       setState(() {
  //         deviceList = devices;
  //         if (devices.isNotEmpty) {
  //           selectedDevice = devices.first;
  //           loadSensorData(devices.first.deviceId);
  //         }
  //         isLoading = false;
  //       });
  //     } catch (e) {
  //       setState(() => isLoading = false);
  //     }
  //   }

  Future<void> loadDevices() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user');
      if (userDataString == null) throw Exception('User data không tồn tại');
      final userData = jsonDecode(userDataString);
      final userId = userData['userId'] as int;

      final devices = await _deviceService.getDevicesByUserId(userId);

      Device? deviceWithData;
      List<SensorData> dataForDevice = [];

      for (var device in devices) {
        final data = await _sensorService.getSensorData(device.deviceId);
        if (data.isNotEmpty) {
          deviceWithData = device;
          dataForDevice = data;
          break; // Dừng khi tìm được device có data
        }
      }

      setState(() {
        deviceList = devices;
        selectedDevice = deviceWithData;
        sensorDataList = dataForDevice;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadSensorData(String deviceId) async {
    setState(() => isLoading = true);
    try {
      final data = await _sensorService.getSensorData(deviceId);
      setState(() {
        sensorDataList = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List<FlSpot> generateSpots(List<double?> values) {
    List<FlSpot> spots = [];
    for (int i = 0; i < values.length; i++) {
      final y = values[i];
      if (y != null) {
        spots.add(FlSpot(i.toDouble(), y));
      }
    }
    return spots;
  }

  List<String> getDateLabels(List<SensorData> data) {
    final formatter = DateFormat('MM-dd');
    return data.map((e) => formatter.format(e.date)).toList();
  }
@override
Widget build(BuildContext context) {
  final recentData = getRecentSensorData(7);
  final dateLabels = getDateLabels(recentData);

  final maxValue = recentData
      .map((e) => [
            e.averageTemperature,
            e.averageHumidity,
            e.averageSmokeLevel.toDouble(),
          ].reduce((a, b) => a > b ? a : b))
      .fold<double>(0, (prev, element) => element > prev ? element : prev);

  final adjustedMaxY = (maxValue * 1.1).ceilToDouble();
  final interval = (adjustedMaxY / 8).ceilToDouble();

  return Scaffold(
    appBar: AppBar(
      title: const Text('Biểu đồ cảm biến'),
      elevation: 2,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Trục Y
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(9, (index) {
                        final value = (interval * (8 - index)).toInt();
                        return Text(
                          '$value',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        );
                      }),
                    ),
                    const SizedBox(width: 12),
                    // Biểu đồ
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: dateLabels.length * 80,
                          height: 400,
                          child: LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: adjustedMaxY,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                getDrawingVerticalLine: (value) => FlLine(
                                  color: Colors.grey.withOpacity(0.1),
                                  strokeWidth: 1,
                                ),
                                drawHorizontalLine: true,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.withOpacity(0.15),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 && index < dateLabels.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            dateLabels[index],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: generateSpots(recentData
                                      .map((e) => e.averageTemperature)
                                      .toList()),
                                  isCurved: true,
                                  barWidth: 3,
                                  color: Colors.redAccent,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(show: false),
                                ),
                                LineChartBarData(
                                  spots: generateSpots(
                                      recentData.map((e) => e.averageHumidity).toList()),
                                  isCurved: true,
                                  barWidth: 3,
                                  color: Colors.blueAccent,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(show: false),
                                ),
                                LineChartBarData(
                                  spots: generateSpots(recentData
                                      .map((e) => e.averageSmokeLevel.toDouble())
                                      .toList()),
                                  isCurved: true,
                                  barWidth: 3,
                                  color: Colors.green,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                handleBuiltInTouches: true,
                                touchTooltipData: LineTouchTooltipData(
                               //   tooltipBackground: Colors.black87,
                                  getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                                    final yValue = spot.y.toStringAsFixed(1);
                                    String label;
                                    if (spot.barIndex == 0) {
                                      label = 'Nhiệt độ: $yValue°C';
                                    } else if (spot.barIndex == 1) {
                                      label = 'Độ ẩm: $yValue%';
                                    } else {
                                      label = 'Khói: $yValue';
                                    }
                                    return LineTooltipItem(
                                      label,
                                      const TextStyle(color: Colors.white),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              legendItem(Colors.redAccent, 'Nhiệt độ'),
              legendItem(Colors.blueAccent, 'Độ ẩm'),
              legendItem(Colors.green, 'Khói'),
            ],
          ),
        ],
      ),
    ),
  );
}
}
// Widget nhỏ cho legend
Widget legendItem(Color color, String label) {
  return Row(
    children: [
      Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ],
  );
}
