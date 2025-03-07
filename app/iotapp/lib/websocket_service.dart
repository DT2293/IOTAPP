// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ApiService {
//   final String baseUrl = "http://192.168.1.4:3000"; // Đổi thành IP thật nếu chạy trên điện thoại

//   // Hàm lấy dữ liệu từ API
//   Future<Map<String, dynamic>?> fetchData() async {
//     try {
//       final response = await http.get(Uri.parse("$baseUrl/get-data"));

//       if (response.statusCode == 200) {
//         return jsonDecode(response.body); // Chuyển JSON thành Map
//       } else {
//         print("Lỗi khi gọi API: ${response.statusCode}");
//         return null;
//       }
//     } catch (e) {
//       print("Lỗi kết nối API: $e");
//       return null;
//     }
//   }
// }

import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'sensor_data.dart';

class WebSocketService {
  final WebSocketChannel channel;
  Function(SensorData)? onDataReceived;

  WebSocketService(String url)
      : channel = WebSocketChannel.connect(Uri.parse(url)) {
    channel.stream.listen((message) {
      final jsonData = jsonDecode(message);
      final data = SensorData.fromJson(jsonData);
      if (onDataReceived != null) {
        onDataReceived!(data);
      }
    }, onError: (error) {
      print("Lỗi WebSocket: $error");
    });
  }

  void close() {
    channel.sink.close();
  }
}
