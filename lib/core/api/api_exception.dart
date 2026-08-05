import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({
    required this.message,
    this.statusCode,
  });

  factory ApiException.fromDio(DioException e) {
    String message = 'Something went wrong';

    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;

      message = data['message'] ?? message;
    } else if (e.error != null) {
      message = e.error.toString();
    } else if (e.message != null) {
      message = e.message!;
    }

    if (message.isEmpty) {
      message = 'Connection failed or server unreachable.';
    }

    return ApiException(
      message: message,
      statusCode: e.response?.statusCode,
    );
  }

  @override
  String toString() => message;
}