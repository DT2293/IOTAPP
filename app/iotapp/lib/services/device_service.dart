import 'package:dio/dio.dart';
import 'package:iotapp/models/device_model.dart';
import 'package:shared_preferences/shared_preferences.dart';



class DeviceService {
  final Dio _dio;

  DeviceService()
      : _dio = Dio(BaseOptions(baseUrl: 'http://dungtc.iothings.vn/api/devices')) {
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

  /// Thêm thiết bị mới, trả về Device nếu thành công
  Future<Device> addDevice(Device device) async {
    try {
      final response = await _dio.post(
        '/',
        data: device.toJson(),
      );

      // Giả sử backend trả về device dưới key 'device'
      final data = response.data;
      if (data['device'] != null) {
        return Device.fromJson(data['device']);
      } else {
        throw Exception('Dữ liệu thiết bị trả về không hợp lệ');
      }
    } on DioException catch (e) {
      final msg = e.response?.data['error'] ?? 'Lỗi không xác định';
      throw Exception('Thêm thiết bị thất bại: $msg');
    }
  }



  /// 🟢 Lấy thông tin thiết bị theo ID
  Future<Map<String, dynamic>?> getDeviceById(String deviceId) async {
    try {
      final encodedDeviceId = Uri.encodeComponent(deviceId.trim());

      final response = await _dio.get('/devices/$encodedDeviceId');

      print("📡 Thiết bị nhận được: ${response.data}");

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print("❌ Lỗi khi lấy thông tin thiết bị: $e");
    }
    return null;
  }

  /// 🟢 Thêm thiết bị
 

  /// 🟢 Cập nhật thiết bị
  Future<void> updateDevice(String deviceId, Device device) async {
    try {
      final encodedId = Uri.encodeComponent(deviceId.trim());
      await _dio.put('/devices/$encodedId', data: {
        "deviceName": device.deviceName,
        "location": device.location,
        "active": device.active,
      });
    } on DioException catch (e) {
      final msg = e.response?.data['error'] ?? 'Lỗi không xác định';
      throw Exception('Cập nhật thiết bị thất bại: $msg');
    }
  }

  /// 🟢 Xóa thiết bị
  Future<void> deleteDevice(String deviceId) async {
    try {
      final encodedId = Uri.encodeComponent(deviceId.trim());
      await _dio.delete('/devices/$encodedId');
    } on DioException catch (e) {
      final msg = e.response?.data['error'] ?? 'Lỗi không xác định';
      throw Exception('Xóa thiết bị thất bại: $msg');
    }
  }

  /// 🟢 Lấy danh sách tất cả thiết bị của user
  Future<List<Map<String, dynamic>>> getAllDevices() async {
    try {
      final response = await _dio.get('/devices');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['devices']);
      }
    } catch (e) {
      print("❌ Lỗi khi lấy danh sách thiết bị: $e");
    }
    return [];
  }
}
