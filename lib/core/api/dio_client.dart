import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/app_config.dart';
import 'auth_interceptor.dart';

class DioClient {
  DioClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.timeout,
      receiveTimeout: AppConfig.timeout,
      sendTimeout: AppConfig.timeout,
      headers: const {
        'Accept': 'application/json',
      },
    ),
  )
    ..interceptors.add(AuthInterceptor())
    ..interceptors.add(
      PrettyDioLogger(
        requestBody: true,
        requestHeader: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    );
}