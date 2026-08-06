import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/api/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

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
  final seatsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  @override
  void dispose() {
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
        setState(() {
          trip = payload;
          stops = parsedStops;
          seatsController.text = (payload['total_seats'] ?? payload['available_seats'] ?? '').toString();
        });
      }
    } catch (_) {
      setState(() {
        trip = {};
        stops = [];
      });
    } finally {
      setState(() => loading = false);
    }
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        if (data['message'] is String && (data['message'] as String).trim().isNotEmpty) {
          return data['message'].toString();
        }
        if (data['error'] is String && (data['error'] as String).trim().isNotEmpty) {
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
      final resp = await DioClient.dio.get('/routes/stops-between', queryParameters: {
        'from_city_id': fromCityId,
        'to_city_id': toCityId,
      });

      final data = resp.data['data'] ?? [];
      final rawStops = data is List ? List<dynamic>.from(data) : [];
      final existingIds = stops.map((stop) => stop['id']).whereType<int>().toSet();

      setState(() {
        availableStopsToAdd = rawStops.whereType<Map>().map((item) {
          return Map<String, dynamic>.from(item);
        }).where((stop) {
          final id = stop['id'];
          if (id is int) return !existingIds.contains(id);
          if (id is String) return !existingIds.contains(int.tryParse(id));
          return true;
        }).toList();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seats must be at least 1.')));
      return;
    }

    setState(() => saving = true);
    try {
      await DioClient.dio.put('/driver-trips/${widget.tripId}', data: {'total_seats': seats});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seats updated.')));
      }
    } catch (e) {
      final message = _extractErrorMessage(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> _saveStops() async {
    if (stops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A trip needs at least two stops.')));
      return;
    }

    setState(() => saving = true);
    try {
      final stopIds = stops.map((stop) => stop['id']).whereType<int>().toList();
      await DioClient.dio.put('/driver-trips/${widget.tripId}', data: {'stop_ids': stopIds});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stops updated.')));
      }
    } catch (e) {
      final message = _extractErrorMessage(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  int _totalEtaMinutes() {
    final points = stops.where((stop) => stop['latitude'] != null && stop['longitude'] != null).toList();
    if (points.length < 2) return 0;

    var total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final from = LatLng((points[i]['latitude'] as num).toDouble(), (points[i]['longitude'] as num).toDouble());
      final to = LatLng((points[i + 1]['latitude'] as num).toDouble(), (points[i + 1]['longitude'] as num).toDouble());
      final distanceKm = const Distance().as(LengthUnit.Kilometer, from, to);
      total += (distanceKm / 50 * 60).round();
    }

    return total;
  }

  List<Map<String, dynamic>> _etaList() {
    final points = stops.where((stop) => stop['latitude'] != null && stop['longitude'] != null).toList();
    if (points.length < 2) return [];

    final segmentMinutes = <int>[];
    for (int i = 0; i < points.length - 1; i++) {
      final from = LatLng((points[i]['latitude'] as num).toDouble(), (points[i]['longitude'] as num).toDouble());
      final to = LatLng((points[i + 1]['latitude'] as num).toDouble(), (points[i + 1]['longitude'] as num).toDouble());
      final distanceKm = const Distance().as(LengthUnit.Kilometer, from, to);
      segmentMinutes.add((distanceKm / 35 * 60).round());
    }

    final remainingFromStop = List<int>.filled(points.length, 0);
    for (int i = points.length - 2; i >= 0; i--) {
      remainingFromStop[i] = remainingFromStop[i + 1] + segmentMinutes[i];
    }

    return List.generate(points.length, (index) {
      final stop = points[index];
      final nextSegment = index < segmentMinutes.length ? segmentMinutes[index] : null;
      return {
        'label': stop['display_name']?.toString() ?? 'Stop ${index + 1}',
        'eta': nextSegment == null ? '0 min' : '${remainingFromStop[index]} min',
        'nextEta': nextSegment == null ? 'Arrived' : '$nextSegment min',
      };
    });
  }

  List<Marker> _markers() {
    return stops.where((stop) {
      final lat = stop['latitude'];
      final lng = stop['longitude'];
      return lat != null && lng != null;
    }).map((stop) {
      final lat = (stop['latitude'] as num).toDouble();
      final lng = (stop['longitude'] as num).toDouble();
      return Marker(
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
      );
    }).toList();
  }

  LatLng? _center() {
    final points = stops.where((stop) {
      final lat = stop['latitude'];
      final lng = stop['longitude'];
      return lat != null && lng != null;
    }).map((stop) => LatLng((stop['latitude'] as num).toDouble(), (stop['longitude'] as num).toDouble())).toList();

    if (points.isEmpty) return null;
    if (points.length == 1) return points.first;

    final latSum = points.fold<double>(0, (sum, point) => sum + point.latitude);
    final lngSum = points.fold<double>(0, (sum, point) => sum + point.longitude);
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  @override
  Widget build(BuildContext context) {
    final center = _center();
    final etaList = _etaList();

    return Scaffold(
      appBar: AppBar(
        title: Text(trip?['from_city_name'] != null && trip?['to_city_name'] != null
            ? '${trip!['from_city_name']} → ${trip!['to_city_name']}'
            : 'Trip details'),
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
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: center == null
                        ? const Center(child: Text('No map coordinates available'))
                        : FlutterMap(
                            options: MapOptions(initialCenter: center, initialZoom: 10),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.driver_app',
                              ),
                              MarkerLayer(markers: _markers()),
                            ],
                          ),
                  ),
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
                        Text('Total ETA: ${_totalEtaMinutes()} min', style: AppTextStyles.body),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: seatsController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  labelText: 'Available seats',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: saving ? null : _saveSeats,
                              child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Selected stops', style: AppTextStyles.subtitle),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
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
                      final label = stop['display_name']?.toString() ?? 'Stop';
                      final city = stop['city_name']?.toString();
                      final etaInfo = index < etaList.length ? etaList[index] : null;

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
                              const Icon(Icons.radio_button_checked, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      city != null && city.isNotEmpty ? '$label • $city' : label,
                                      style: AppTextStyles.body,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      etaInfo != null
                                          ? 'ETA from here to destination: ${etaInfo['eta']} • next leg: ${etaInfo['nextEta']}'
                                          : 'Final stop',
                                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
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
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
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
                      const Text('No additional stops are available for this route.')
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButton<int?>(
                            isExpanded: true,
                            value: selectedStopToAddId,
                            hint: const Text('Choose a stop to add'),
                            items: availableStopsToAdd.map((stop) {
                              final label = stop['display_name']?.toString() ?? 'Stop';
                              final city = stop['city_name']?.toString();
                              return DropdownMenuItem<int?>(
                                value: stop['id'] is int ? stop['id'] as int : int.tryParse(stop['id']?.toString() ?? ''),
                                child: Text(city != null && city.isNotEmpty ? '$label • $city' : label),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => selectedStopToAddId = value);
                            },
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: selectedStopToAddId == null ? null : _addSelectedStop,
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
