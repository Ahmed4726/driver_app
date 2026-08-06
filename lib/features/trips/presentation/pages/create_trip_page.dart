import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../features/vehicle/data/models/vehicle_model.dart';
import '../../../../features/vehicle/data/repositories/vehicle_repository.dart';
import '../../../../core/di/service_locator.dart';

class CreateTripPage extends StatelessWidget {
  const CreateTripPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.trips);
            }
          },
        ),
      ),
      body: const CreateTripForm(),
    );
  }
}

class CreateTripForm extends StatefulWidget {
  const CreateTripForm({super.key, this.onBackToTrips});

  final VoidCallback? onBackToTrips;

  @override
  State<CreateTripForm> createState() => _CreateTripFormState();
}

class _CreateTripFormState extends State<CreateTripForm> {
  List<dynamic> cities = [];
  List<dynamic> fromCityStops = [];
  List<dynamic> toCityStops = [];
  List<dynamic> journeyStops = [];
  int? fromCityId;
  int? toCityId;
  int? fromStopId;
  int? toStopId;
  List<int> selectedStopIds = [];
  VehicleModel? currentVehicle;
  bool fromCityStopsLoading = false;
  bool toCityStopsLoading = false;
  bool journeyStopsLoading = false;
  String? fromCityStopsError;
  String? toCityStopsError;
  String? journeyStopsError;
  final seatsController = TextEditingController();
  bool loading = false;
  bool citiesLoading = false;
  String? formError;
  String? seatsError;

  @override
  void initState() {
    super.initState();
    _loadCurrentVehicle();
    _loadCities();
  }

  Future<void> _loadCurrentVehicle() async {
    final vehicle = await sl<VehicleRepository>().getCurrentVehicle();
    setState(() {
      currentVehicle = vehicle;
      if (vehicle != null) {
        final isApprovedVehicle = vehicle.status.toLowerCase() == 'approved';
        final maxSeats = isApprovedVehicle && vehicle.availableSeats > 0 ? vehicle.availableSeats : 1;
        final currentValue = int.tryParse(seatsController.text) ?? 0;
        if (currentValue < 1 || (isApprovedVehicle && currentValue > maxSeats)) {
          seatsController.text = maxSeats.toString();
        }
      }
    });
  }

  Future<void> _loadCities() async {
    setState(() => citiesLoading = true);
    try {
      final resp = await DioClient.dio.get('/cities');
      var data = resp.data;

      if (data is Map && data['data'] is List) {
        data = data['data'];
      }

      if (data is! List) {
        data = [];
      }

      final parsed = <Map<String, dynamic>>[];
      for (final item in data) {
        if (item is Map) {
          final rawId = item['id'];
          final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;
          parsed.add({'id': id, 'name': item['name']?.toString() ?? ''});
        } else {
          parsed.add({'id': 0, 'name': item.toString()});
        }
      }

      setState(() {
        cities = parsed.where((c) => (c['id'] as int) > 0).toList();
      });
    } catch (_) {
      setState(() {
        cities = [];
      });
    } finally {
      setState(() => citiesLoading = false);
    }
  }

  String _stopLabel(dynamic stop) {
    if (stop is Map<String, dynamic>) {
      final displayName = stop['display_name']?.toString();
      if (displayName?.isNotEmpty == true) return displayName!;

      final locationName = stop['location_name']?.toString();
      if (locationName?.isNotEmpty == true) return locationName!;

      final address = stop['address']?.toString();
      if (address?.isNotEmpty == true) return address!;

      final cityName = (stop['city'] is Map) ? (stop['city']['name']?.toString() ?? '') : '';
      final order = stop['stop_order']?.toString();
      if (cityName.isNotEmpty && order != null) {
        return '$cityName stop $order';
      }
      if (cityName.isNotEmpty) {
        return cityName;
      }
      return 'Stop ${stop['id'] ?? ''}';
    }
    return stop?.toString() ?? 'Stop';
  }

  Future<void> _loadCityStops({required int cityId, required bool isFrom}) async {
    if (cityId <= 0) return;

    setState(() {
      if (isFrom) {
        fromCityStopsLoading = true;
        fromCityStopsError = null;
        fromCityStops = [];
        fromStopId = null;
      } else {
        toCityStopsLoading = true;
        toCityStopsError = null;
        toCityStops = [];
        toStopId = null;
      }
    });

    try {
      final resp = await DioClient.dio.get('/cities/$cityId/stops');
      final data = resp.data['data'] ?? [];
      final stops = data is List ? List<dynamic>.from(data) : [];

      setState(() {
        if (isFrom) {
          fromCityStops = stops;
        } else {
          toCityStops = stops;
        }
      });
    } catch (e) {
      setState(() {
        if (isFrom) {
          fromCityStopsError = 'Unable to fetch stops for selected departure city.';
        } else {
          toCityStopsError = 'Unable to fetch stops for selected destination city.';
        }
      });
    } finally {
      setState(() {
        if (isFrom) {
          fromCityStopsLoading = false;
        } else {
          toCityStopsLoading = false;
        }
      });
    }
  }

  List<dynamic> get _effectiveFromStopOptions => fromCityStops;

  List<dynamic> get _effectiveToStopOptions => toCityStops;

  List<dynamic> get _intermediateStopOptions {
    if (fromStopId == null || toStopId == null) {
      return [];
    }
    final selectedIds = <int>{fromStopId!, toStopId!};
    return journeyStops.where((stop) {
      final id = stop['id'];
      if (id is int) return !selectedIds.contains(id);
      if (id is String) return !selectedIds.contains(int.tryParse(id));
      return true;
    }).toList();
  }

  Future<void> _loadJourneyStops() async {
    if (fromCityId == null || toCityId == null || fromCityId == toCityId) {
      setState(() {
        journeyStops = [];
        journeyStopsError = null;
      });
      return;
    }

    setState(() {
      journeyStopsLoading = true;
      journeyStopsError = null;
      journeyStops = [];
    });

    try {
      final resp = await DioClient.dio.get('/routes/stops-between', queryParameters: {
        'from_city_id': fromCityId,
        'to_city_id': toCityId,
      });

      final data = resp.data['data'] ?? [];
      final stops = data is List ? List<dynamic>.from(data) : [];

      setState(() {
        journeyStops = stops;
      });
    } catch (e) {
      setState(() {
        journeyStopsError = 'Unable to load journey stops.';
      });
    } finally {
      setState(() {
        journeyStopsLoading = false;
      });
    }
  }

  void _updateSelectedCities({int? fromCity, int? toCity}) {
    setState(() {
      fromCityId = fromCity;
      toCityId = toCity;
      fromStopId = null;
      toStopId = null;
      selectedStopIds = [];
      fromCityStops = [];
      toCityStops = [];
      journeyStops = [];
      fromCityStopsError = null;
      toCityStopsError = null;
      journeyStopsError = null;
    });

    if (fromCity != null) {
      _loadCityStops(cityId: fromCity, isFrom: true);
    }
    if (toCity != null) {
      _loadCityStops(cityId: toCity, isFrom: false);
    }
    if (fromCity != null && toCity != null && fromCity != toCity) {
      _loadJourneyStops();
    }
  }

  void _setFormError({String? formMessage, String? seatMessage}) {
    setState(() {
      formError = formMessage;
      seatsError = seatMessage;
    });
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
        return 'Please review the trip details and try again.';
      }
    }

    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }

    return 'Unable to create trip right now.';
  }

  Future<void> _submit() async {
    _setFormError(formMessage: null, seatMessage: null);

    if (currentVehicle == null) {
      _setFormError(formMessage: 'Please register a vehicle before creating a trip.', seatMessage: null);
      return;
    }

    final isApprovedVehicle = currentVehicle!.status.toLowerCase() == 'approved';
    final maxSeats = isApprovedVehicle && currentVehicle!.availableSeats > 0 ? currentVehicle!.availableSeats : 1;
    final requestedSeats = int.tryParse(seatsController.text) ?? 0;

    if (requestedSeats < 1) {
      _setFormError(formMessage: 'Seats must be at least 1.', seatMessage: 'Seats must be at least 1.');
      return;
    }

    if (isApprovedVehicle && requestedSeats > maxSeats) {
      _setFormError(
        formMessage: 'Seats cannot exceed $maxSeats for this approved vehicle.',
        seatMessage: 'Seats cannot exceed $maxSeats for this approved vehicle.',
      );
      return;
    }

    if (fromCityId == null || toCityId == null || fromCityId == toCityId || fromStopId == null || toStopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select cities, start/end stops, and valid trip stops.')));
      return;
    }

    final sortedStopIds = [...selectedStopIds];

    setState(() => loading = true);

    final payload = {
      'vehicle_id': currentVehicle!.id,
      'total_seats': requestedSeats,
      'from_stop_id': fromStopId,
      'to_stop_id': toStopId,
      'selected_stop_ids': sortedStopIds,
      'is_instant': true,
    };

    try {
      final resp = await DioClient.dio.post('/driver-trips', data: payload);
      if (resp.data['success'] == true) {
        _setFormError(formMessage: null, seatMessage: null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip created.')));
        }
        if (widget.onBackToTrips != null) {
          widget.onBackToTrips!();
        } else if (context.mounted) {
          context.go(RouteNames.trips);
        }
      }
    } catch (e) {
      final message = _extractErrorMessage(e);
      _setFormError(formMessage: message, seatMessage: null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('From city', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          DropdownButton<int?>(
            isExpanded: true,
            value: fromCityId,
            hint: const Text('Choose departure city'),
            items: cities.map((c) {
              return DropdownMenuItem<int?>(value: c['id'] as int, child: Text(c['name'] ?? ''));
            }).toList(),
            onChanged: (value) {
              _updateSelectedCities(fromCity: value, toCity: toCityId);
            },
          ),
          const SizedBox(height: 12),
          Text('To city', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          DropdownButton<int?>(
            isExpanded: true,
            value: toCityId,
            hint: const Text('Choose destination city'),
            items: cities.map((c) {
              return DropdownMenuItem<int?>(value: c['id'] as int, child: Text(c['name'] ?? ''));
            }).toList(),
            onChanged: (value) {
              _updateSelectedCities(fromCity: fromCityId, toCity: value);
            },
          ),
          if (fromCityId != null && toCityId != null && fromCityId == toCityId) ...[
            const SizedBox(height: 12),
            const Text('Departure and destination cities cannot be the same.', style: TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          if (journeyStopsLoading) ...[
            const Text('Loading journey stops...', style: AppTextStyles.body),
            const SizedBox(height: 12),
          ] else if (journeyStopsError != null) ...[
            Text(journeyStopsError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
          ] else if (fromCityStopsLoading || toCityStopsLoading) ...[
            if (fromCityStopsLoading)
              const Text('Loading departure city stops...', style: AppTextStyles.body),
            if (toCityStopsLoading)
              const Text('Loading destination city stops...', style: AppTextStyles.body),
            const SizedBox(height: 12),
          ] else if (fromCityStopsError != null || toCityStopsError != null) ...[
            if (fromCityStopsError != null) ...[
              Text(fromCityStopsError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            if (toCityStopsError != null) ...[
              Text(toCityStopsError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
          ] else if (journeyStops.isNotEmpty || fromCityStops.isNotEmpty || toCityStops.isNotEmpty) ...[
            Text('Select your start stop', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            DropdownButton<int?>(
              isExpanded: true,
              value: fromStopId,
              hint: const Text('Choose departure stop'),
              items: _effectiveFromStopOptions.map((stop) {
                return DropdownMenuItem<int?>(
                  value: stop['id'] as int?,
                  child: Text(_stopLabel(stop)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  fromStopId = value;
                  selectedStopIds = [];
                });
              },
            ),
            const SizedBox(height: 12),
            Text('Select your end stop', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            DropdownButton<int?>(
              isExpanded: true,
              value: toStopId,
              hint: const Text('Choose destination stop'),
              items: _effectiveToStopOptions.map((stop) {
                return DropdownMenuItem<int?>(
                  value: stop['id'] as int?,
                  child: Text(_stopLabel(stop)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  toStopId = value;
                  selectedStopIds = [];
                });
              },
            ),
            const SizedBox(height: 16),
            if (fromStopId != null && toStopId != null) ...[
              Text('Intermediate stops between your selected journey', style: AppTextStyles.subtitle),
              const SizedBox(height: 8),
              if (_intermediateStopOptions.isEmpty)
                const Text('No intermediate stops available for the selected journey.', style: AppTextStyles.body)
              else
                ..._intermediateStopOptions.map((stop) {
                  final stopId = stop['id'];
                  final selected = stopId is int ? selectedStopIds.contains(stopId) : false;
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_stopLabel(stop)),
                    value: selected,
                    onChanged: (value) {
                      if (stopId is! int) return;
                      setState(() {
                        if (value == true) {
                          selectedStopIds = [...selectedStopIds, stopId];
                        } else {
                          selectedStopIds = selectedStopIds.where((id) => id != stopId).toList();
                        }
                      });
                    },
                  );
                }),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 12),
          Text('Trip details', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          const Text('This trip is created instantly and will begin from the selected stops.'),
          const SizedBox(height: 12),
          Text('Seats', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          TextField(
            controller: seatsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Enter seats',
              border: const OutlineInputBorder(),
              errorText: seatsError,
              helperText: currentVehicle != null
                  ? (currentVehicle!.status.toLowerCase() == 'approved'
                      ? 'Approved vehicle capacity: ${currentVehicle!.availableSeats}'
                      : 'Seat count must be at least 1')
                  : 'Vehicle capacity unavailable',
            ),
          ),
          if (formError != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(formError!, style: const TextStyle(color: Colors.red)),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : _submit,
            child: loading ? const CircularProgressIndicator() : const Text('Create Trip'),
          ),
        ],
      ),
    );
  }
}
