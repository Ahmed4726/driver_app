import 'package:flutter/material.dart';

import '../../../../core/api/dio_client.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../trips/presentation/pages/create_trip_page.dart';

enum TripPageMode { list, create }

class TripsPage extends StatefulWidget {
  const TripsPage({super.key, this.initialMode = TripPageMode.list, this.onBackToTrips});

  final TripPageMode initialMode;
  final VoidCallback? onBackToTrips;

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  bool loading = false;
  List<dynamic> trips = [];
  late TripPageMode mode;

  @override
  void initState() {
    super.initState();
    mode = widget.initialMode;
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => loading = true);
    try {
      final resp = await DioClient.dio.get('/driver-trips');
      final data = resp.data['data'] ?? [];
      setState(() => trips = data is List ? List<dynamic>.from(data) : []);
    } catch (_) {
      setState(() => trips = []);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _deleteTrip(int tripId) async {
    try {
      await DioClient.dio.delete('/driver-trips/$tripId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip deleted.')));
        await _loadTrips();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete trip.')));
      }
    }
  }

  void _showCreateForm() {
    setState(() => mode = TripPageMode.create);
  }

  @override
  Widget build(BuildContext context) {
    if (mode == TripPageMode.create) {
      return CreateTripForm(onBackToTrips: widget.onBackToTrips);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Your trips',
                  style: AppTextStyles.subtitle,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : trips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Trips will appear here once you start driving.',
                            style: AppTextStyles.subtitle.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _showCreateForm,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Trip'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: trips.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final trip = trips[index] as Map<String, dynamic>;
                        final status = trip['status']?.toString() ?? 'scheduled';

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  [trip['from_city_name'] ?? '', trip['to_city_name'] ?? '']
                                      .where((value) => value.toString().isNotEmpty)
                                      .join(' → '),
                                  style: AppTextStyles.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text('Stops: ${trip['stop_count'] ?? trip['stops_count'] ?? '-'}', style: AppTextStyles.body),
                                const SizedBox(height: 6),
                                Text('Available seats: ${trip['total_seats'] ?? trip['available_seats'] ?? '-'}', style: AppTextStyles.body),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip details coming soon.')));
                                        },
                                        icon: const Icon(Icons.visibility_outlined),
                                        label: const Text('View'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: status.toLowerCase() == 'started' ? null : () {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip started.')));
                                        },
                                        icon: const Icon(Icons.play_arrow),
                                        label: const Text('Start'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final tripId = trip['id'];
                                      if (tripId is int) {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (dialogContext) => AlertDialog(
                                            title: const Text('Delete trip?'),
                                            content: const Text('This action cannot be undone.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(dialogContext).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              FilledButton(
                                                onPressed: () => Navigator.of(dialogContext).pop(true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          await _deleteTrip(tripId);
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Delete'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
