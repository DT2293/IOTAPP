import 'package:dio/dio.dart';
import 'package:iotapp/models/sensor_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
class SensorService {
  final Dio _dio ;
 // final String baseUrl = 'http://dungtc.iothings.vn/api/data';
 SensorService()
    : _dio = Dio(
        BaseOptions(baseUrl: 'http://dungtc.iothings.vn/api/data'),
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

  Future<List<SensorData>> getSensorData(String deviceId) async {
    try {
      final response = await _dio.get('baseUrl/sensordata/$deviceId');
      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((e) => SensorData.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load sensor data');
      }
    } catch (e) {
      print('❌ SensorService error: $e');
      rethrow;
    }
  }
}