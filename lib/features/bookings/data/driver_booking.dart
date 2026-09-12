class DriverBooking {
  const DriverBooking({
    required this.id,
    required this.reference,
    required this.seats,
    required this.status,
    required this.passengerName,
    this.passengerPhone,
  });

  factory DriverBooking.fromJson(Map<String, dynamic> json) {
    final passenger = json['passenger'];
    final passengerMap = passenger is Map
        ? Map<String, dynamic>.from(passenger)
        : const <String, dynamic>{};
    return DriverBooking(
      id: _asInt(json['id']) ?? 0,
      reference: json['booking_reference']?.toString() ?? 'Booking',
      seats: _asInt(json['seats']) ?? 0,
      status: json['status']?.toString() ?? 'unknown',
      passengerName: passengerMap['name']?.toString() ?? 'Passenger',
      passengerPhone: passengerMap['phone']?.toString(),
    );
  }

  final int id;
  final String reference;
  final int seats;
  final String status;
  final String passengerName;
  final String? passengerPhone;

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class DriverManifest {
  const DriverManifest({required this.trip, required this.bookings});

  factory DriverManifest.fromJson(Map<String, dynamic> json) {
    final tripValue = json['trip'];
    final bookingValue = json['bookings'];
    final rawBookings = bookingValue is List ? bookingValue : const <dynamic>[];
    return DriverManifest(
      trip: tripValue is Map
          ? DriverManifestTrip.fromJson(Map<String, dynamic>.from(tripValue))
          : const DriverManifestTrip(),
      bookings: rawBookings
          .whereType<Map>()
          .map(
            (item) => DriverBooking.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  final DriverManifestTrip trip;
  final List<DriverBooking> bookings;
}

class DriverManifestTrip {
  const DriverManifestTrip({
    this.status = 'unknown',
    this.tripDate,
    this.departureTime,
    this.totalCapacity = 0,
    this.bookedSeats = 0,
    this.availableSeats = 0,
    this.vehicleName,
  });

  factory DriverManifestTrip.fromJson(Map<String, dynamic> json) {
    return DriverManifestTrip(
      status: json['status']?.toString() ?? 'unknown',
      tripDate: json['trip_date']?.toString(),
      departureTime: json['departure_time']?.toString(),
      totalCapacity: _asInt(json['total_capacity']) ?? 0,
      bookedSeats: _asInt(json['booked_seats']) ?? 0,
      availableSeats: _asInt(json['available_seats']) ?? 0,
      vehicleName: json['vehicle_name']?.toString(),
    );
  }

  final String status;
  final String? tripDate;
  final String? departureTime;
  final int totalCapacity;
  final int bookedSeats;
  final int availableSeats;
  final String? vehicleName;

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

String driverBookingStatusLabel(String status) {
  switch (status) {
    case 'confirmed':
      return 'Confirmed';
    case 'cancelled':
      return 'Cancelled';
    case 'boarded':
      return 'Boarded';
    case 'completed':
      return 'Completed';
    case 'no_show':
      return 'No-show';
    default:
      return status.isEmpty ? 'Unknown' : status;
  }
}
