import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AuthService {
 // final Dio _dio = Dio(BaseOptions(baseUrl: 'http://dungtc.iothings.vn/api/auth'));
 final Dio _dio =
     Dio(BaseOptions(baseUrl: 'http://192.168.1.3:3000/api/auth'));

  Future<String?> login(String usernameOrEmail, String password) async {
    try {
      Response response = await _dio.post('/login', data: {
        "username": usernameOrEmail,
        "email": usernameOrEmail,
        "password": password,
      });

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String token = response.data['token'];
        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(response.data['user']));
        return null;
      } else {
        return response.data['error'] ?? tr('login_failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response?.data['error'] ?? tr('server_error');
      }
      return tr('network_error');
    } catch (e) {
      return tr('unknown_error');
    }
  }

  Future<String?> sendOtp(String email) async {
    try {
      Response response = await _dio.post('/forgot-password', data: {
        "email": email,
      });

      if (response.statusCode == 200) {
        return null;
      } else {
        return response.data['error'] ?? tr('otp_send_failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response?.data['error'] ?? tr('server_error');
      }
      return tr('network_error');
    } catch (e) {
      return tr('unknown_error');
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(String email, String otp) async {
    try {
      Response response = await _dio.post('/verify-otp', data: {
        "email": email,
        "otp": otp,
      });

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? tr('otp_invalid'));
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? tr('otp_invalid'));
    } catch (e) {
      throw Exception(tr('unknown_error'));
    }
  }


  Future<String?> resetPassword(String email, String newPassword) async {
    try {
      final response = await _dio.post('/reset-password', data: {
        'email': email,
        'newPassword': newPassword,
      });
      return null;
    } catch (e) {
      return _handleError(e);
    }
  }

  String _handleError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      return data['message'] ?? error.message ?? "Đã xảy ra lỗi không xác định";
    } else if (data is String) {
      return data;
    }

    return error.message ?? "Đã xảy ra lỗi không xác định";
  }

  return "Đã xảy ra lỗi không xác định";
}


  Future<String?> updatePassword(
      String oldPassword, String newPassword, int userId, String token) async {
    try {
      final response = await _dio.put(
        '/updatepassword/$userId',
        data: {
          "oldPassword": oldPassword,
          "newPassword": newPassword,
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      if (response.statusCode == 200) {
        print("✅ Đổi mật khẩu thành công: ${response.data['message']}");
        return null; // null nghĩa là thành công
      } else {
        return response.data['error'] ?? "Lỗi khi đổi mật khẩu!";
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response?.data["error"] ?? "Lỗi từ server!";
      }
      return "Lỗi kết nối mạng!";
    } catch (e) {
      return "Lỗi không xác định: $e";
    }
  }

  Future<String?> register(
      String username, String email, String password) async {
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
        // Trả về thông báo lỗi nếu có
        return response.data["error"] ?? "Đăng ký thất bại!";
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // Trả về thông báo lỗi chi tiết từ server nếu có
        return e.response?.data["error"] ?? "Đăng ký thất bại!";
      }
      // Trả về lỗi khi kết nối hoặc lỗi không xác định
      return "Lỗi kết nối: ${e.message}";
    } catch (e) {
      // Trả về lỗi không xác định
      return "Lỗi không xác định: $e";
    }
  }

  Future<bool> updateUser(String username, String email, String token) async {
    int? userId = await getUserId(); // 🔍 Lấy userId từ SharedPreferences

    if (userId == null) {
      print("🚨 Không tìm thấy userId!");
      return false;
    }

    try {
      print("🔑 Token: $token");
      print("📌 userId: ${userId.toString()}");

      final response = await _dio.put(
        '/update/$userId',
        data: {
          "username": username,
          "email": email,
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        ),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Data: ${response.data}");

      return response.statusCode == 200;
    } on DioException catch (e) {
      print("🚨 Lỗi update user: ${e.response?.data ?? e.message}");
      return false;
    }
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('token'); // Lấy token từ SharedPreferences
    if (token == null) {
      print("🚨 Không tìm thấy token!");
      return null;
    }

    try {
      final jwt = JWT.decode(token);
      int? userId = jwt.payload['userId'] as int?; // Lấy userId kiểu int
      print("📌 userId từ token: $userId");
      return userId;
    } catch (e) {
      print("🚨 Lỗi decode JWT: $e");
      return null;
    }
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');

    print(
        "Stored user data: $userData"); // ✅ Debug xem dữ liệu có lưu đúng không

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


//  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://dungtc.iothings.vn/api/auth'));
 //  String? userId = await getUserId();
// Future<String?> login(String usernameOrEmail, String password) async {
//     try {
//       // Gửi request đến API với cả username hoặc email
//       Response response = await _dio.post('/login', data: {
//         "username": usernameOrEmail,
//         "email": usernameOrEmail,
//         "password": password,
//       });

//       if (response.statusCode == 200) {
//         // Lưu thông tin người dùng và token vào SharedPreferences
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//         String token = response.data['token'];
//         await prefs.setString('token', token);
//         await prefs.setString('user', jsonEncode(response.data['user']));

//         return null;  // Trả về null nếu đăng nhập thành công
//       } else {
//         return response.data['error'] ?? 'Đăng nhập thất bại!';
//       }
//     } on DioException catch (e) {
//       // Nếu có lỗi từ server hoặc API
//       if (e.response != null) {
//         return e.response?.data["error"] ?? "Lỗi khi kết nối tới server!";
//       }
//       return "Lỗi kết nối mạng!";
//     } catch (e) {
//       return "Lỗi không xác định: $e";
//     }
//   }