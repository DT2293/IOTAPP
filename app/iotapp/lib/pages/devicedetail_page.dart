import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:iotapp/services/websocket_service.dart';
import 'package:provider/provider.dart';

class DeviceDetailPage extends StatefulWidget {
  final String deviceId;
  final String userToken;

  DeviceDetailPage({required this.deviceId, required this.userToken});

  @override
  _DeviceDetailPageState createState() => _DeviceDetailPageState();
}

bool isAlarmOn = true;

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<WebSocketProvider>(context, listen: false);
    provider.initConnection(token: widget.userToken, deviceId: widget.deviceId);
  }

  @override
  void dispose() {
    super.dispose();
    // Không disconnect WebSocket tại đây nếu muốn giữ kết nối toàn cục
  }

  @override
  Widget build(BuildContext context) {
    final wsProvider = Provider.of<WebSocketProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(tr("device_info"))),
      body:
          !wsProvider.isAuthorized
              ? Center(
                child: Text(
                  tr("user_info_error"),
                  style: TextStyle(color: Colors.red),
                ),
              )
              : wsProvider.deviceData.isEmpty
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                   _buildSensorCard(
                      tr("temperature"),
                     // "${wsProvider.deviceData['temperature']}°C ",
                     "${wsProvider.deviceData['temperature'] ?? 0}°C",
                      Colors.orange,
                    ),
                    SizedBox(height: 16),
                    _buildSensorCard(
                      tr("humidity"),
                     // "${wsProvider.deviceData['humidity']}%",
                      "${wsProvider.deviceData['humidity'] ?? 0}°C",
                      Colors.blue,
                    ),
                    SizedBox(height: 16),
                    _buildSensorCard(
                      tr("smoke_level"),
                      "${wsProvider.deviceData['smokeLevel']}",
                      Colors.red,
                      isDanger: true,
                    ),
//                      SizedBox(height: 16),
//                     _buildSensorCard(
//   tr("fire_detected"),
//   wsProvider.deviceData['flameDetected'] == true ? tr("yes") : tr("no"),
//   Colors.deepOrange,
//   isDanger: wsProvider.deviceData['flameDetected'] == true,
// ),
                    Spacer(),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tr("alarm"),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: isAlarmOn,
                          onChanged: (value) {
                            setState(() {
                              isAlarmOn = value;
                            });
                            wsProvider.sendAlarmCommand(
                              value,
                            ); // gửi lệnh bật/tắt
                          },
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                          inactiveTrackColor: Colors.red.shade200,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSensorCard(
    String title,
    String value,
    Color baseColor, {
    bool isDanger = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor =
        isDanger
            ? (isDark
                ? Colors.red.shade900.withOpacity(0.3)
                : Colors.red.shade100)
            : (isDark
                ? baseColor.withOpacity(0.25)
                : baseColor.withOpacity(0.2));
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Icon(
              isDanger ? Icons.warning : Icons.thermostat,
              size: 40,
              color: baseColor,
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(value, style: TextStyle(fontSize: 18, color: textColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
