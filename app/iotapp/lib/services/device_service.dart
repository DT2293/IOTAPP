import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
 //final Dio _dio = Dio(BaseOptions(baseUrl: 'http://192.168.0.102:3000/api'));
final Dio _dio = Dio(BaseOptions(baseUrl: 'http://dungtc.iothings.vn/api'));
  Future<Map<String, dynamic>?> getDeviceById(String deviceId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        print("❌ Không tìm thấy token!");
        return null;
      }

      // ✅ Encode deviceId để tránh lỗi URL
      String encodedDeviceId = Uri.encodeComponent(deviceId.trim());

      Response response = await _dio.get(
        '/devices/$encodedDeviceId',
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      print("📡 Thiết bị nhận được: ${response.data}");

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print("❌ Lỗi khi lấy thông tin thiết bị: $e");
    }
    return null;
  }
}
