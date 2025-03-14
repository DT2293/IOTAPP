import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.17:3000/api'));

  Future<Map<String, dynamic>?> getDeviceById(String deviceId) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      print("❌ Không tìm thấy token!");
      return null;
    }

    Response response = await _dio.get(
      '/devices/$deviceId',
      options: Options(
        headers: {"Authorization": token}, // ✅ Gửi token
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
