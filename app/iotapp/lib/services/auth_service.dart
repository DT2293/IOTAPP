import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.17:3000/api/auth'));

  Future<bool> login(String email, String password) async {
    try {
      Response response = await _dio.post('/login/', data: {
        "email": email,
        "password": password,
      });

      print("Response data: ${response.data}"); // ✅ Debug API response

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        // ✅ Lấy dữ liệu user
        Map<String, dynamic> userData = response.data['user'];
        String token = response.data['token'];

        print("Saving user data: $userData"); // ✅ Debug

        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(userData));

        return true;
      }
    } catch (e) {
      print("Login error: $e");
    }
    return false;
  }

  
 Future<String?> register(String username, String email, String password) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          "username": username,
          "email": email,
          "password": password,
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 201) {
        return null; // Thành công, không có lỗi
      } else {
        return response.data["message"] ?? "Đăng ký thất bại!";
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response?.data["message"] ?? "Đăng ký thất bại!";
      }
      return "Lỗi kết nối: ${e.message}";
    } catch (e) {
      return "Lỗi không xác định: $e";
    }
  }
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');

    print("Stored user data: $userData"); // ✅ Debug xem dữ liệu có lưu đúng không

    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  Future<List<String>> getUserDevices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');

    if (userData != null) {
      Map<String, dynamic> userMap = jsonDecode(userData);
      List<String> devices = List<String>.from(userMap['devices'] ?? []);
      print("User devices: $devices"); // ✅ Debug danh sách thiết bị
      return devices;
    }
    return [];
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }
}
