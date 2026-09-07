import 'dart:io' show Platform;

class ApiConstants {
  static String get baseUrl {
    return 'http://127.0.0.1:8000/api';
  }

  static const String login = '/auth/login';

  static const String logout = '/logout';

  static const String profile = '/profile';
}