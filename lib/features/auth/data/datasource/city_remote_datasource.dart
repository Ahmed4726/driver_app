import 'package:dio/dio.dart';

import '../../../../core/api/dio_client.dart';

class CityRemoteDataSource {
  Future<Response> fetchCities() {
    return DioClient.dio.get('/cities');
  }
}
