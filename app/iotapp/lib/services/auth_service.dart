import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:iotapp/services/fcm_initializer.dart';
import 'package:iotapp/services/fcm_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AuthService {
final FirebaseMessaging _fcm = FirebaseMessaging.instance;
 final Dio _dio = Dio(BaseOptions(baseUrl: 'https://dungtc.iothings.vn/api/auth'));
 // final Dio _dio =  Dio(BaseOptions(baseUrl: 'http://192.168.1.14:3000/api/auth'));
  final FCMService fcmService = FCMService();

Future<String?> login(String usernameOrEmail, String password) async {
  final prefs = await SharedPreferences.getInstance();
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  try {
    final response = await _dio.post(
      '/login',
      data: {
        "username": usernameOrEmail,
        "email": usernameOrEmail, // Có thể server chỉ dùng 1 trong 2
        "password": password,
      },
    ).timeout(const Duration(seconds: 5));

    print("[LOGIN] ✅ Status code: ${response.statusCode}");

    if (response.statusCode == 200) {
      final token = response.data['token'];
      final user = response.data['user'] as Map<String, dynamic>;
      final int userId = user['userId'];

      // Lưu thông tin user và token vào SharedPreferences
      await prefs.setString('token', token);
      await prefs.setString('user', jsonEncode(user));
      await prefs.setInt('userId', userId);

      // Lấy FCM token hiện tại và FCM token mới từ Firebase
      final String? currentFcmToken = prefs.getString('fcmToken');
      final String? newFcmToken = await messaging.getToken();

      // Nếu FCM token thay đổi hoặc lần đầu -> cập nhật server
      if (newFcmToken != null && newFcmToken != currentFcmToken) {
        // Tạo instance FCMService và gọi addFcmToken
        FCMService fcmService = FCMService();
        await fcmService.addFcmToken(newFcmToken); // Thêm FCM token vào server
        await prefs.setString('fcmToken', newFcmToken);
        print("🔁 FCM token đã được cập nhật");
      }

      // Khởi tạo FCM listener
      await FCMInitializer().init(); 

      return null; 
    }

    // Nếu login lỗi (401 hoặc khác)
    return response.data['error'] ?? 'Đăng nhập thất bại';
  } on DioException catch (e) {
    return e.response?.data['error'] ?? 'Lỗi từ server';
  } on TimeoutException {
    return '⏰ Server không phản hồi, vui lòng thử lại';
  } catch (err) {
    print("[LOGIN] ❌ Lỗi không xác định: $err");
    return 'Lỗi không xác định';
  }
}

Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  return token != null && token.isNotEmpty;
}
Future<bool> autoLogin() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final userId = prefs.getInt('userId');

  if (token != null && userId != null) {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    final savedFcmToken = prefs.getString('fcmToken');

    if (fcmToken != null && fcmToken != savedFcmToken) {
      // Gọi FCMService để cập nhật FCM token lên server
      FCMService fcmService = FCMService();
      await fcmService.addFcmToken(fcmToken); // Cập nhật FCM token lên server
      await prefs.setString('fcmToken', fcmToken); // Lưu FCM token vào SharedPreferences
    }

    // Khởi tạo FCM listener
    await FCMInitializer().init();

    return true;
  }

  return false; // Không có token hoặc userId trong SharedPreferences, trả về false
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
      String username, String email,String phonenumber ,String password) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          "username": username,
          "email": email,
          "phonenumber": phonenumber,
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

Future<bool> addPhoneNumber(String phoneNumber,String token) async {
    try {

      if (token == null) {
        print("🚨 Chưa đăng nhập hoặc thiếu token");
        return false;
      }
      int? userId = await getUserId(); 
      final response = await _dio.patch(
        '/add-phone/$userId',
        data: {
         "newPhone": phoneNumber,
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      print("✅ Response: ${response.data}");
      return response.statusCode == 200;
    } on DioException catch (e) {
      print("🚨 Lỗi thêm số điện thoại: ${e.response?.data ?? e.message}");
      return false;
    }
}
  Future<bool> updateUser(String username, String email,String phonenumber ,String token) async {
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
          "phonenumber":phonenumber,
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

  // Future<void> logout() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('token');
  //   await prefs.remove('user');
  // }
  Future<void> logout() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Xóa token và user khỏi prefs
  await prefs.remove('token');
  await prefs.remove('user');

  // Xóa token FCM (huỷ đăng ký nhận notification)
  await _fcm.deleteToken();

  // Nếu bạn có đăng ký topic userId, huỷ đăng ký ở đây
  // final userId = ... lấy userId từ prefs hoặc biến lưu trữ
  // await _fcm.unsubscribeFromTopic('user_$userId');
}
}

