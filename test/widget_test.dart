// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:driver_app/features/bookings/data/driver_booking.dart';

void main() {
  test('parses a manifest and keeps the safe passenger fields', () {
    final manifest = DriverManifest.fromJson({
      'trip': {
        'total_capacity': 4,
        'booked_seats': 2,
        'available_seats': 2,
        'status': 'scheduled',
      },
      'bookings': [
        {
          'id': 1,
          'booking_reference': 'TE-TEST',
          'seats': 2,
          'status': 'confirmed',
          'passenger': {'name': 'Ahmed'},
        },
      ],
    });

    expect(manifest.trip.bookedSeats, 2);
    expect(manifest.trip.availableSeats, 2);
    expect(manifest.bookings.single.passengerName, 'Ahmed');
    expect(driverBookingStatusLabel('no_show'), 'No-show');
  });

  test('malformed optional values use safe defaults', () {
    final manifest = DriverManifest.fromJson({
      'bookings': [{}],
    });

    expect(manifest.trip.totalCapacity, 0);
    expect(manifest.bookings.single.seats, 0);
    expect(manifest.bookings.single.passengerName, 'Passenger');
  });
}
