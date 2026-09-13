import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iotapp/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  final Dio _dio = Dio();
  Future<void> addFcmToken(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print("Chưa đăng nhập, không thể thêm FCM token.");
      return;
    }

    final language =
        EasyLocalization.of(
          navigatorKey.currentContext!,
        )?.locale.languageCode ??
        'vi';

    try {
      final response = await _dio.post(
        'https://dungtc.iothings.vn/api/fcm-token',
        data: {'fcmToken': fcmToken, 'language': language},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        print("FCM token & language đã được cập nhật.");
      } else {
        print("FCM token chưa được cập nhật - ${response.statusCode}");
      }
    } catch (e) {
      print(" Lỗi thêm FCM token: $e");
    }
  }
}
