import '../api/api_exception.dart';
import '../di/service_locator.dart';
import '../services/network_service.dart';
import 'package:dio/dio.dart';

abstract class BaseRepository {
  Future<T> execute<T>(
    Future<T> Function() action,
  ) async {
    final connected =
        await sl<NetworkService>().isConnected();

    if (!connected) {
      throw ApiException(
        message: 'No internet connection.',
      );
    }

    try {
      return await action();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    } catch (e) {
      throw ApiException(
        message: e.toString(),
      );
    }
  }
}