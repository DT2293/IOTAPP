import 'package:dio/dio.dart';
import 'package:iotapp/models/device_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
class DeviceService {
  final Dio _dio;

  DeviceService()
      : _dio = Dio(
          BaseOptions(baseUrl: 'https://dungtc.iothings.vn/api'),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

Future<List<Device>> getDevicesByUserId(int userId) async {
  try {
    final response = await _dio.get('/devices/devices/$userId');

    // response.data là Map<String, dynamic>
    final data = response.data['devices'] as List;

    return data.map((e) => Device.fromJson(e)).toList();
  } catch (e) {
    print('Lỗi khi lấy danh sách thiết bị: $e');
    rethrow;
  }
}
Future<Device?> getDeviceById(String deviceId) async {
    try {
      final encodedId = Uri.encodeComponent(deviceId.trim());
      final response = await _dio.get('/devices/$encodedId');
      return Device.fromJson(response.data);
    } catch (e) {
      print("Lỗi khi lấy thông tin thiết bị: $e");
      return null;
    }
  }

  Future<Device> addDevice(Device device) async {
    try {
      final response = await _dio.post('/devices', data: device.toJson());
      final json = response.data['device'] ?? response.data;
      return Device.fromJson(json);
    } on DioException catch (e) {
      final msg = e.response?.data['error'] ?? 'Lỗi không xác định';
      throw Exception('Thêm thiết bị thất bại: $msg');
    }
  }

    Future<void> updateDevice(String deviceId, Device device) async {
    try {
      final encodedId = Uri.encodeComponent(deviceId.trim());
      await _dio.put(
        '/devices/$encodedId',
        data: {
          "deviceName": device.deviceName,
          "location": device.location,
          "active": device.active,
        },
      );
    } on DioException catch (e) {
      final msg = e.response?.data['error'] ?? 'Lỗi không xác định';
      throw Exception('Cập nhật thiết bị thất bại: $msg');
    }
  }

   Future<void> deleteDevice(String deviceId) async {
    try {
      final encodedId = Uri.encodeComponent(deviceId.trim());
      await _dio.delete('/devices/$encodedId');
    } on DioException catch (e) {
      final msg = e.response?.data['error'] ?? 'Lỗi không xác định';
      throw Exception('Xóa thiết bị thất bại: $msg');
    }
  }
}
