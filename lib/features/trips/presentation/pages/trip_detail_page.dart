import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/api/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../bookings/presentation/pages/driver_manifest_page.dart';
import '../../data/driver_trip_api.dart';

class TripDetailPage extends StatefulWidget {
  const TripDetailPage({super.key, required this.tripId});

  final int tripId;

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  bool loading = true;
  bool saving = false;
  bool editingStops = false;
  Map<String, dynamic>? trip;
  List<Map<String, dynamic>> stops = [];
  List<Map<String, dynamic>> availableStopsToAdd = [];
  bool loadingAvailableStops = false;
  int? selectedStopToAddId;
  LatLng? driverLocation;
  StreamSubscription<Position>? _locationSubscription;
  final seatsController = TextEditingController();
  final MapController _mapController = MapController();
  final DriverTripApi _tripApi = const DriverTripApi();

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    seatsController.dispose();
    super.dispose();
  }

  Future<void> _loadTrip() async {
    setState(() => loading = true);
    try {
      final resp = await DioClient.dio.get('/driver-trips/${widget.tripId}');
      final payload = resp.data['data'];
      if (payload is Map<String, dynamic>) {
        final parsedStops = <Map<String, dynamic>>[];
        final rawStops = payload['stops'];
        if (rawStops is List) {
          for (final item in rawStops) {
            if (item is Map) {
              parsedStops.add(Map<String, dynamic>.from(item));
            }
          }
        }
        final latestLocation = payload['latest_location'];
        setState(() {
          trip = payload;
          stops = parsedStops;
          seatsController.text =
              (payload['total_seats'] ?? payload['available_seats'] ?? '')
                  .toString();
          if (latestLocation is Map &&
              latestLocation['latitude'] != null &&
              latestLocation['longitude'] != null) {
            driverLocation = LatLng(
              (latestLocation['latitude'] as num).toDouble(),
              (latestLocation['longitude'] as num).toDouble(),
            );
          }
        });
      }
    } catch (_) {
      setState(() {
        trip = {};
        stops = [];
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
      _maybeStartLiveTrackingIfNeeded();
    }
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        if (data['message'] is String &&
            (data['message'] as String).trim().isNotEmpty) {
          return data['message'].toString();
        }
        if (data['error'] is String &&
            (data['error'] as String).trim().isNotEmpty) {
          return data['error'].toString();
        }
      }
      if (error.response?.statusCode == 422) {
        return 'Please review the updated values and try again.';
      }
    }

    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }

    return 'Unable to update right now.';
  }

  Future<void> _loadAvailableStopsToAdd() async {
    final fromCityId = trip?['from_city_id'];
    final toCityId = trip?['to_city_id'];

    if (fromCityId == null || toCityId == null || fromCityId == toCityId) {
      setState(() {
        availableStopsToAdd = [];
        selectedStopToAddId = null;
      });
      return;
    }

    setState(() {
      loadingAvailableStops = true;
      availableStopsToAdd = [];
      selectedStopToAddId = null;
    });

    try {
      final resp = await DioClient.dio.get(
        '/routes/stops-between',
        queryParameters: {'from_city_id': fromCityId, 'to_city_id': toCityId},
      );

      final data = resp.data['data'] ?? [];
      final rawStops = data is List ? List<dynamic>.from(data) : [];
      final existingIds = stops
          .map((stop) => stop['id'])
          .whereType<int>()
          .toSet();

      setState(() {
        availableStopsToAdd = rawStops
            .whereType<Map>()
            .map((item) {
              return Map<String, dynamic>.from(item);
            })
            .where((stop) {
              final id = stop['id'];
              if (id is int) return !existingIds.contains(id);
              if (id is String) return !existingIds.contains(int.tryParse(id));
              return true;
            })
            .toList();
      });
    } catch (_) {
      setState(() {
        availableStopsToAdd = [];
      });
    } finally {
      if (mounted) {
        setState(() => loadingAvailableStops = false);
      }
    }
  }

  void _addSelectedStop() {
    if (selectedStopToAddId == null) return;

    final selectedStop = availableStopsToAdd.firstWhere(
      (stop) => stop['id'] == selectedStopToAddId,
      orElse: () => const <String, dynamic>{},
    );

    if (selectedStop.isEmpty) return;

    final newStop = Map<String, dynamic>.from(selectedStop);
    final newLat = newStop['latitude'];
    final newLng = newStop['longitude'];

    if (newLat is num && newLng is num) {
      final existingPoints = stops.where((stop) {
        final lat = stop['latitude'];
        final lng = stop['longitude'];
        return lat is num && lng is num;
      }).toList();

      int insertIndex = stops.length;
      double? bestDistance;
      for (int index = 0; index < existingPoints.length; index++) {
        final currentPoint = existingPoints[index];
        final currentLat = currentPoint['latitude'];
        final currentLng = currentPoint['longitude'];
        if (currentLat is! num || currentLng is! num) continue;

        final distance = const Distance().as(
          LengthUnit.Kilometer,
          LatLng(currentLat.toDouble(), currentLng.toDouble()),
          LatLng(newLat.toDouble(), newLng.toDouble()),
        );

        if (bestDistance == null || distance < bestDistance) {
          bestDistance = distance;
          insertIndex = index + 1;
        }
      }

      setState(() {
        stops.insert(insertIndex, newStop);
        selectedStopToAddId = null;
      });
      return;
    }

    setState(() {
      stops.add(newStop);
      selectedStopToAddId = null;
    });
  }

  Future<void> _saveSeats() async {
    final seats = int.tryParse(seatsController.text) ?? 0;
    if (seats < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seats must be at least 1.')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      await DioClient.dio.put(
        '/driver-trips/${widget.tripId}',
        data: {'total_seats': seats},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Seats updated.')));
      }
    } catch (e) {
      final message = _extractErrorMessage(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> _saveStops() async {
    if (stops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A trip needs at least two stops.')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      final stopIds = stops.map((stop) => stop['id']).whereType<int>().toList();
      await DioClient.dio.put(
        '/driver-trips/${widget.tripId}',
        data: {'stop_ids': stopIds},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Stops updated.')));
      }
    } catch (e) {
      final message = _extractErrorMessage(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> _sendCurrentLocation(double latitude, double longitude) async {
    try {
      await DioClient.dio.post(
        '/driver-trips/${widget.tripId}/locations',
        data: {'latitude': latitude, 'longitude': longitude},
      );
    } catch (_) {
      // Ignore location sync failures while the trip is moving; the next poll will recover.
    }
  }

  Future<void> _maybeStartLiveTrackingIfNeeded() async {
    if (!mounted || trip?['status']?.toString() != 'started') {
      _locationSubscription?.cancel();
      _locationSubscription = null;
      return;
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return;
      }

      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(
        () => driverLocation = LatLng(current.latitude, current.longitude),
      );
      await _sendCurrentLocation(current.latitude, current.longitude);

      if (_locationSubscription != null) {
        return;
      }

      _locationSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 15,
            ),
          ).listen((position) async {
            if (!mounted || trip?['status']?.toString() != 'started') {
              return;
            }

            final nextLocation = LatLng(position.latitude, position.longitude);
            if (mounted) {
              setState(() => driverLocation = nextLocation);
            }
            await _sendCurrentLocation(position.latitude, position.longitude);
          });
    } catch (_) {
      // Ignore tracking setup errors and allow the user to retry once the trip is active.
    }
  }

  Future<void> _startTrip() async {
    setState(() => saving = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required to start a trip.');
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw Exception('Turn on device location to start the trip.');
      }

      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await DioClient.dio.post(
        '/driver-trips/${widget.tripId}/start',
        data: {'latitude': current.latitude, 'longitude': current.longitude},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip started from your current location.'),
          ),
        );
        await _loadTrip();
      }
    } catch (e) {
      final message = _extractErrorMessage(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> _confirmCompleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete this trip?'),
        content: const Text(
          'All passengers who have not boarded will be marked as no-show.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Complete trip'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _completeTrip();
  }

  Future<void> _completeTrip() async {
    if (saving || trip?['status']?.toString() != 'started') return;
    setState(() => saving = true);
    try {
      await _tripApi.completeTrip(widget.tripId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip completed successfully.')),
      );
      await _loadTrip();
    } on DioException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(error)),
          backgroundColor: Colors.red,
        ),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(error)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  int _totalEtaMinutes() {
    final points = stops
        .where((stop) => stop['latitude'] != null && stop['longitude'] != null)
        .toList();
    if (points.length < 2) return 0;

    var total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final from = LatLng(
        (points[i]['latitude'] as num).toDouble(),
        (points[i]['longitude'] as num).toDouble(),
      );
      final to = LatLng(
        (points[i + 1]['latitude'] as num).toDouble(),
        (points[i + 1]['longitude'] as num).toDouble(),
      );
      final distanceKm = const Distance().as(LengthUnit.Kilometer, from, to);
      total += (distanceKm / 50 * 60).round();
    }

    return total;
  }

  List<Map<String, dynamic>> _etaList() {
    final points = stops
        .where((stop) => stop['latitude'] != null && stop['longitude'] != null)
        .toList();
    if (points.length < 2) return [];

    final segmentMinutes = <int>[];
    for (int i = 0; i < points.length - 1; i++) {
      final from = LatLng(
        (points[i]['latitude'] as num).toDouble(),
        (points[i]['longitude'] as num).toDouble(),
      );
      final to = LatLng(
        (points[i + 1]['latitude'] as num).toDouble(),
        (points[i + 1]['longitude'] as num).toDouble(),
      );
      final distanceKm = const Distance().as(LengthUnit.Kilometer, from, to);
      segmentMinutes.add((distanceKm / 35 * 60).round());
    }

    final remainingFromStop = List<int>.filled(points.length, 0);
    for (int i = points.length - 2; i >= 0; i--) {
      remainingFromStop[i] = remainingFromStop[i + 1] + segmentMinutes[i];
    }

    return List.generate(points.length, (index) {
      final stop = points[index];
      final nextSegment = index < segmentMinutes.length
          ? segmentMinutes[index]
          : null;
      return {
        'label': stop['display_name']?.toString() ?? 'Stop ${index + 1}',
        'eta': nextSegment == null
            ? '0 min'
            : '${remainingFromStop[index]} min',
        'nextEta': nextSegment == null ? 'Arrived' : '$nextSegment min',
      };
    });
  }

  List<Marker> _markers() {
    final markers = <Marker>[];

    for (final stop in stops.where((stop) {
      final lat = stop['latitude'];
      final lng = stop['longitude'];
      return lat != null && lng != null;
    })) {
      final lat = (stop['latitude'] as num).toDouble();
      final lng = (stop['longitude'] as num).toDouble();
      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    if (driverLocation != null) {
      markers.add(
        Marker(
          point: driverLocation!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.directions_car,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  List<LatLng> _routePoints() {
    return stops
        .where((stop) {
          final lat = stop['latitude'];
          final lng = stop['longitude'];
          return lat != null && lng != null;
        })
        .map(
          (stop) => LatLng(
            (stop['latitude'] as num).toDouble(),
            (stop['longitude'] as num).toDouble(),
          ),
        )
        .toList();
  }

  LatLng? _center() {
    final points = stops
        .where((stop) {
          final lat = stop['latitude'];
          final lng = stop['longitude'];
          return lat != null && lng != null;
        })
        .map(
          (stop) => LatLng(
            (stop['latitude'] as num).toDouble(),
            (stop['longitude'] as num).toDouble(),
          ),
        )
        .toList();

    if (points.isEmpty) return null;
    if (points.length == 1) return points.first;

    final latSum = points.fold<double>(0, (sum, point) => sum + point.latitude);
    final lngSum = points.fold<double>(
      0,
      (sum, point) => sum + point.longitude,
    );
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  @override
  Widget build(BuildContext context) {
    final center = _center();
    final etaList = _etaList();
    final routePoints = _routePoints();
    final isTripLive = trip?['status']?.toString() == 'started';
    final isReadOnly =
        trip?['status']?.toString() == 'completed' ||
        trip?['status']?.toString() == 'cancelled';

    if (isTripLive && driverLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(driverLocation!, 13);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          trip?['from_city_name'] != null && trip?['to_city_name'] != null
              ? '${trip!['from_city_name']} → ${trip!['to_city_name']}'
              : 'Trip details',
        ),
        actions: isTripLive
            ? [
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Center(
                    child: Chip(
                      label: Text('Live'),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ]
            : null,
        backgroundColor: AppColors.primary,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTrip,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: center == null
                          ? const Center(
                              child: Text('No map coordinates available'),
                            )
                          : FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter:
                                    center ?? const LatLng(24.8607, 67.0011),
                                initialZoom: 10,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.driver_app',
                                ),
                                if (routePoints.length > 1)
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: routePoints,
                                        color: AppColors.primary,
                                        strokeWidth: 4,
                                      ),
                                    ],
                                  ),
                                MarkerLayer(markers: _markers()),
                              ],
                            ),
                    ),
                    if (trip?['status']?.toString() == 'started') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: saving ? null : _confirmCompleteTrip,
                          icon: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.flag_outlined),
                          label: Text(
                            saving ? 'Completing trip...' : 'Complete trip',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Trip simulator', style: AppTextStyles.subtitle),
                          const SizedBox(height: 8),
                          Text(
                            'Total ETA: ${_totalEtaMinutes()} min',
                            style: AppTextStyles.body,
                          ),
                          if (driverLocation != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Driver location: ${driverLocation!.latitude.toStringAsFixed(5)}, ${driverLocation!.longitude.toStringAsFixed(5)}',
                              style: AppTextStyles.body,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed:
                                      saving ||
                                          trip?['status']?.toString() !=
                                              'scheduled'
                                      ? null
                                      : _startTrip,
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Start trip'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: seatsController,
                                  keyboardType: TextInputType.number,
                                  readOnly: isReadOnly,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Total capacity',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: saving || isReadOnly
                                    ? null
                                    : _saveSeats,
                                child: saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Save'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                DriverManifestPage(tripId: widget.tripId),
                          ),
                        ),
                        icon: const Icon(Icons.people_outline),
                        label: const Text('View passenger manifest'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Selected stops', style: AppTextStyles.subtitle),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: isReadOnly
                              ? null
                              : () {
                                  setState(() => editingStops = !editingStops);
                                  if (editingStops) {
                                    _loadAvailableStopsToAdd();
                                  }
                                },
                          icon: Icon(editingStops ? Icons.done : Icons.edit),
                          label: Text(editingStops ? 'Done' : 'Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (stops.isEmpty)
                      Text('No stop data available.', style: AppTextStyles.body)
                    else
                      ...stops.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stop = entry.value;
                        final label =
                            stop['display_name']?.toString() ?? 'Stop';
                        final city = stop['city_name']?.toString();
                        final etaInfo = index < etaList.length
                            ? etaList[index]
                            : null;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.radio_button_checked,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        city != null && city.isNotEmpty
                                            ? '$label • $city'
                                            : label,
                                        style: AppTextStyles.body,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        etaInfo != null
                                            ? 'ETA from here to destination: ${etaInfo['eta']} • next leg: ${etaInfo['nextEta']}'
                                            : 'Final stop',
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (editingStops)
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        stops.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Remove stop',
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    if (editingStops) ...[
                      const SizedBox(height: 12),
                      Text('Add another stop', style: AppTextStyles.subtitle),
                      const SizedBox(height: 8),
                      if (loadingAvailableStops)
                        const Text('Loading available stops...')
                      else if (availableStopsToAdd.isEmpty)
                        const Text(
                          'No additional stops are available for this route.',
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButton<int?>(
                              isExpanded: true,
                              value: selectedStopToAddId,
                              hint: const Text('Choose a stop to add'),
                              items: availableStopsToAdd.map((stop) {
                                final label =
                                    stop['display_name']?.toString() ?? 'Stop';
                                final city = stop['city_name']?.toString();
                                return DropdownMenuItem<int?>(
                                  value: stop['id'] is int
                                      ? stop['id'] as int
                                      : int.tryParse(
                                          stop['id']?.toString() ?? '',
                                        ),
                                  child: Text(
                                    city != null && city.isNotEmpty
                                        ? '$label • $city'
                                        : label,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => selectedStopToAddId = value);
                              },
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: selectedStopToAddId == null
                                  ? null
                                  : _addSelectedStop,
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Add stop'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: saving ? null : _saveStops,
                              icon: const Icon(Icons.save_alt),
                              label: const Text('Save stop changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
