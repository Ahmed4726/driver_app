import 'dart:io' show Platform;

class ApiConstants {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  static const String login = '/auth/login';

  static const String logout = '/logout';

  static const String profile = '/profile';
}