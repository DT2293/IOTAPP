import 'package:iotapp/models/user_model.dart';

class AuthModel {
  final String message;
  final String token;
  final User user;

  AuthModel({required this.message, required this.token, required this.user});

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      message: json['message'],
      token: json['token'],
      user: User.fromJson(json['user']),
    );
  }
}