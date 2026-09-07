import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/api/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/driver_booking.dart';
import '../../data/driver_booking_api.dart';

class DriverManifestPage extends StatefulWidget {
  const DriverManifestPage({super.key, required this.tripId});

  final int tripId;

  @override
  State<DriverManifestPage> createState() => _DriverManifestPageState();
}

class _DriverManifestPageState extends State<DriverManifestPage> {
  final DriverBookingApi _bookingApi = const DriverBookingApi();
  final Set<int> _boardingIds = {};
  final Set<int> _noShowIds = {};
  DriverManifest? _manifest;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadManifest();
  }

  Future<void> _loadManifest({bool refreshing = false}) async {
    if (!refreshing) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final response = await DioClient.dio.get(
        '/driver-trips/${widget.tripId}/bookings',
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is! Map) throw const FormatException();
      if (!mounted) return;
      setState(() {
        _manifest = DriverManifest.fromJson(Map<String, dynamic>.from(data));
        _loading = false;
        _error = null;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(error.response?.statusCode);
      });
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'The manifest response was invalid.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load the passenger manifest.';
      });
    }
  }

  String _friendlyError(int? statusCode) {
    if (statusCode == 401) {
      return 'Your session has expired. Please log in again.';
    }
    if (statusCode == 403 || statusCode == 404) {
      return 'You are not authorized to view this trip manifest.';
    }
    return 'Unable to load the passenger manifest. Please try again.';
  }

  Future<void> _confirmBoarding(DriverBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Board passenger?'),
        content: Text(
          'Confirm that ${booking.passengerName} has boarded this trip.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Board passenger'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _boardBooking(booking);
  }

  Future<void> _boardBooking(DriverBooking booking) async {
    if (_boardingIds.contains(booking.id)) return;
    setState(() => _boardingIds.add(booking.id));
    try {
      final updated = await _bookingApi.boardBooking(
        tripId: widget.tripId,
        bookingId: booking.id,
      );
      if (!mounted) return;
      final current = _manifest!;
      final bookings = current.bookings
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      setState(() {
        _manifest = DriverManifest(trip: current.trip, bookings: bookings);
        _boardingIds.remove(booking.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passenger boarded successfully.')),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _boardingIds.remove(booking.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_boardingError(error)),
          backgroundColor: AppColors.danger,
        ),
      );
    } on FormatException {
      if (!mounted) return;
      setState(() => _boardingIds.remove(booking.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to board passenger. Invalid server response.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _boardingIds.remove(booking.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to board passenger. Please try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _confirmNoShow(DriverBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark passenger as no-show?'),
        content: const Text(
          'This will mark the passenger as no-show and release their reserved seats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Mark no-show'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _markNoShow(booking);
  }

  Future<void> _markNoShow(DriverBooking booking) async {
    if (_noShowIds.contains(booking.id)) return;
    setState(() => _noShowIds.add(booking.id));
    try {
      final updated = await _bookingApi.markNoShow(
        tripId: widget.tripId,
        bookingId: booking.id,
      );
      if (!mounted) return;
      final current = _manifest!;
      final bookings = current.bookings
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      setState(() {
        _manifest = DriverManifest(trip: current.trip, bookings: bookings);
        _noShowIds.remove(booking.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passenger marked as no-show.')),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _noShowIds.remove(booking.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_noShowError(error)),
          backgroundColor: AppColors.danger,
        ),
      );
    } on FormatException {
      if (!mounted) return;
      setState(() => _noShowIds.remove(booking.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to mark passenger as no-show. Invalid server response.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _noShowIds.remove(booking.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to mark passenger as no-show. Please try again.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  String _noShowError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 401) {
      return 'Your session has expired. Please log in again.';
    }
    if (status == 403) {
      return 'You are not authorized to update this passenger.';
    }
    final data = error.response?.data;
    final message = data is Map
        ? data['message']?.toString().toLowerCase()
        : null;
    if (message?.contains('started') == true ||
        message?.contains('trip') == true) {
      return 'The trip is not currently accepting no-show updates.';
    }
    if (message?.contains('confirmed') == true) {
      return 'This passenger is no longer confirmed and cannot be marked no-show.';
    }
    return 'Unable to mark passenger as no-show. Please try again.';
  }

  String _boardingError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 401) return 'Your session has expired. Please log in again.';
    if (status == 403) return 'You are not authorized to board this passenger.';
    final data = error.response?.data;
    final message = data is Map
        ? data['message']?.toString().toLowerCase()
        : null;
    if (message?.contains('already') == true ||
        message?.contains('confirmed') == true) {
      return 'This passenger has already been boarded or is no longer confirmed.';
    }
    if (message?.contains('trip') == true) {
      return 'The trip is not currently accepting boarding.';
    }
    return 'Unable to board passenger. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passenger manifest'),
        actions: [
          IconButton(
            tooltip: 'Refresh manifest',
            onPressed: _loading ? null : () => _loadManifest(refreshing: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadManifest(refreshing: true),
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 110),
          const Icon(Icons.people_outline, size: 56, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.body),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _loadManifest,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    final manifest = _manifest!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _Summary(trip: manifest.trip),
        const SizedBox(height: 20),
        Text('Passengers', style: AppTextStyles.title),
        const SizedBox(height: 10),
        if (manifest.bookings.isEmpty)
          const _EmptyManifest()
        else
          ...manifest.bookings.map(
            (booking) => _BookingCard(
              booking: booking,
              boarding: _boardingIds.contains(booking.id),
              onBoard:
                  manifest.trip.status == 'started' &&
                      booking.status == 'confirmed'
                  ? () => _confirmBoarding(booking)
                  : null,
              noShowing: _noShowIds.contains(booking.id),
              onNoShow:
                  manifest.trip.status == 'started' &&
                      booking.status == 'confirmed'
                  ? () => _confirmNoShow(booking)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.trip});

  final DriverManifestTrip trip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trip summary', style: AppTextStyles.title),
            const SizedBox(height: 12),
            Text(
              'Status: ${driverBookingStatusLabel(trip.status)}',
              style: AppTextStyles.body,
            ),
            Text(
              'Departure: ${trip.departureTime ?? 'Not provided'}',
              style: AppTextStyles.body,
            ),
            if (trip.tripDate != null)
              Text('Date: ${trip.tripDate}', style: AppTextStyles.body),
            if (trip.vehicleName != null)
              Text('Vehicle: ${trip.vehicleName}', style: AppTextStyles.body),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Metric(label: 'Capacity', value: '${trip.totalCapacity}'),
                _Metric(label: 'Booked', value: '${trip.bookedSeats}'),
                _Metric(label: 'Available', value: '${trip.availableSeats}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.title.copyWith(color: AppColors.primary),
        ),
        Text(label, style: AppTextStyles.subtitle),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.boarding,
    required this.onBoard,
    required this.noShowing,
    required this.onNoShow,
  });

  final DriverBooking booking;
  final bool boarding;
  final VoidCallback? onBoard;
  final bool noShowing;
  final VoidCallback? onNoShow;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(booking.passengerName),
        subtitle: Text(
          '${booking.reference}\n${booking.seats} seat${booking.seats == 1 ? '' : 's'}',
        ),
        isThreeLine: true,
        trailing: onBoard == null && onNoShow == null
            ? Text(
                driverBookingStatusLabel(booking.status),
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: booking.status == 'confirmed'
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onBoard != null)
                    FilledButton(
                      onPressed: boarding ? null : onBoard,
                      child: boarding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Board'),
                    ),
                  if (onNoShow != null)
                    TextButton(
                      onPressed: noShowing ? null : onNoShow,
                      child: noShowing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Mark no-show'),
                    ),
                ],
              ),
      ),
    );
  }
}

class _EmptyManifest extends StatelessWidget {
  const _EmptyManifest();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Icon(Icons.event_seat_outlined, size: 56, color: AppColors.primary),
          SizedBox(height: 16),
          Text('No passengers yet'),
          SizedBox(height: 8),
          Text(
            'Passenger bookings will appear here when they are confirmed.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
