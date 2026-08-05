import 'user_model.dart';

class LoginResponse {
  final bool success;
  final String message;
  final String token;
  final String tokenType;
  final UserModel user;

  LoginResponse({
    required this.success,
    required this.message,
    required this.token,
    required this.tokenType,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'],
      message: json['message'],
      token: json['data']['token'],
      tokenType: json['data']['token_type'],
      user: UserModel.fromJson(json['data']['user']),
    );
  }
}