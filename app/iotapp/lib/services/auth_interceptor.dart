import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;

  AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refreshToken');

      if (refreshToken != null) {
        try {
          final response = await dio.post(
            '/refresh-token',
            data: {"refreshToken": refreshToken},
          );

          final newAccessToken = response.data['accessToken'];
          await prefs.setString('accessToken', newAccessToken);

          // Gửi lại request bị lỗi với access token mới
          final newRequest = await dio.request(
            err.requestOptions.path,
            data: err.requestOptions.data,
            options: Options(
              method: err.requestOptions.method,
              headers: {
                ...?err.requestOptions.headers,
                'Authorization': 'Bearer $newAccessToken',
              },
            ),
          );
          return handler.resolve(newRequest);
        } catch (e) {
          // Nếu refresh token cũng lỗi -> logout
          await prefs.remove('accessToken');
          await prefs.remove('refreshToken');
        }
      }
    }

    return handler.next(err);
  }
}
