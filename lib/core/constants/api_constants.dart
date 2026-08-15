import 'dart:io' show Platform;

class ApiConstants {
  static String get baseUrl {
    return 'http://api.booksdada.com/api';
  }

  static const String login = '/auth/login';

  static const String logout = '/logout';

  static const String profile = '/profile';
}