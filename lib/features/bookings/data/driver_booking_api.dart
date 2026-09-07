import '../../../../core/api/dio_client.dart';
import 'driver_booking.dart';

class DriverBookingApi {
  const DriverBookingApi();

  Future<DriverBooking> boardBooking({
    required int tripId,
    required int bookingId,
  }) async {
    final response = await DioClient.dio.post(
      '/driver-trips/$tripId/bookings/$bookingId/board',
    );
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) {
      throw const FormatException('Invalid boarding response.');
    }
    return DriverBooking.fromJson(Map<String, dynamic>.from(data));
  }

  Future<DriverBooking> markNoShow({
    required int tripId,
    required int bookingId,
  }) async {
    final response = await DioClient.dio.post(
      '/driver-trips/$tripId/bookings/$bookingId/no-show',
    );
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) {
      throw const FormatException('Invalid no-show response.');
    }
    return DriverBooking.fromJson(Map<String, dynamic>.from(data));
  }
}
