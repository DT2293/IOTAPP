// import 'package:flutter/material.dart';
// import 'websocket_service.dart';
// import 'sensor_data.dart';

// class HomePage2 extends StatefulWidget {
//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   late WebSocketService webSocketService;
//   SensorData? sensorData;

//   @override
//   void initState() {
//     super.initState();
//     webSocketService = WebSocketService('ws://192.168.1.22:8080');
//     webSocketService.onDataReceived = (data) {
//       setState(() {
//         sensorData = data;
//       });
//     };
//   }

//   @override
//   void dispose() {
//     webSocketService.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("WebSocket Real-Time Data")),
//       body: Center(
//         child: sensorData == null
//             ? CircularProgressIndicator()
//             : Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text("🌡️ Temperature: ${sensorData!.temperature}°C",
//                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                   Text("💧 Humidity: ${sensorData!.humidity}%",
//                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                   Text("🔥 Smoke Level: ${sensorData!.smoke}",
//                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                 ],
//               ),
//       ),
//     );
//   }
// }
