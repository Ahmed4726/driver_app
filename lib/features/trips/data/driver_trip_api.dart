import '../../../../core/api/dio_client.dart';

class DriverTripApi {
  const DriverTripApi();

  Future<Map<String, dynamic>> completeTrip(int tripId) async {
    final response = await DioClient.dio.post('/driver-trips/$tripId/complete');
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) {
      throw const FormatException('Invalid trip completion response.');
    }
    return Map<String, dynamic>.from(data);
  }
}
