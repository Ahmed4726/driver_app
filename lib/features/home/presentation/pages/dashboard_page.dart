import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../vehicle/data/models/vehicle_model.dart';
import '../../../vehicle/data/repositories/vehicle_repository.dart';
import '../../../trips/presentation/pages/trip_detail_page.dart';
import '../../../../core/di/service_locator.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isOnline = false;
  bool availabilitySaving = false;
  bool _hasInitializedAvailability = false;
  String? _lastAuthStatus;
  VehicleModel? currentVehicle;
  bool loadingVehicle = true;
  bool approvedSuccessBannerVisible = false;
  bool approvedSuccessShown = false;
  bool loadingActiveTrip = true;
  Map<String, dynamic>? activeTrip;
  String? activeTripError;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentVehicle();
    _loadActiveTrip();
  }

  Future<void> _loadActiveTrip() async {
    try {
      final response = await DioClient.dio.get(
        '/driver-trips',
        queryParameters: const {'status': 'started'},
      );
      final data = response.data is Map ? response.data['data'] : null;
      final trips = data is List ? data : const <dynamic>[];
      if (!mounted) return;
      setState(() {
        activeTrip = trips.isNotEmpty && trips.first is Map
            ? Map<String, dynamic>.from(trips.first as Map)
            : null;
        activeTripError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        activeTrip = null;
        activeTripError = 'Unable to load the active trip.';
      });
    } finally {
      if (!mounted) return;
      setState(() => loadingActiveTrip = false);
    }
  }

  void _openActiveTrip() {
    final tripId = int.tryParse(activeTrip?['id']?.toString() ?? '');
    if (tripId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripDetailPage(tripId: tripId, mapOnly: true),
      ),
    );
  }

  Future<void> _loadCurrentVehicle() async {
    try {
      final vehicle = await sl<VehicleRepository>().getCurrentVehicle();
      if (!mounted) return;
      setState(() {
        currentVehicle = vehicle;
      });
    } catch (_) {
      // ignore
    } finally {
      if (!mounted) return;
      setState(() {
        loadingVehicle = false;
      });
    }
  }

  Widget _buildOnlineToggle(bool enabled) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isOnline ? 'Online' : 'Offline',
          style: AppTextStyles.body.copyWith(
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary.withOpacity(0.6),
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: isOnline,
          activeColor: AppColors.primary,
          inactiveThumbColor: AppColors.border,
          inactiveTrackColor: AppColors.border.withOpacity(0.3),
          onChanged: enabled && !availabilitySaving
              ? (value) {
                  _saveAvailability(value);
                }
              : null,
        ),
      ],
    );
  }

  Future<void> _saveAvailability(bool value) async {
    if (!mounted) return;

    setState(() {
      isOnline = value;
      availabilitySaving = true;
    });

    try {
      await sl<AuthRepository>().updateAvailability(value);
      context.read<AuthBloc>().add(CheckAuthentication());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isOnline = !value;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        availabilitySaving = false;
      });
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  Widget _buildSummaryStat(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.subtitle),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.title),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            final status = state.user.status.toLowerCase();
            if (status == 'approved' && _lastAuthStatus != 'approved') {
              setState(() {
                approvedSuccessBannerVisible = true;
                approvedSuccessShown = true;
              });
            }
            _lastAuthStatus = status;
          }
        },
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final user = state.user;
            if (!_hasInitializedAvailability) {
              isOnline = user.driver?.isAvailable ?? false;
              _hasInitializedAvailability = true;
            }
            final firstName = user.name.split(' ').first;
            final isPending = user.status.toLowerCase() == 'pending';
            final isRejected = user.status.toLowerCase() == 'rejected';
            final isApproved = user.status.toLowerCase() == 'approved';
            final statusText = isPending
                ? 'Review'
                : isRejected
                    ? 'Rejected'
                    : 'Approved';
            final headline = isPending
                ? 'Account under review'
                : isRejected
                    ? 'Profile rejected'
                    : 'Ready to drive';
            final iconColor = isPending
                ? AppColors.warning
                : isRejected
                    ? AppColors.danger
                    : AppColors.success;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<AuthBloc>().add(CheckAuthentication());
                await _loadActiveTrip();
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: AppTextStyles.subtitle.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                firstName,
                                style: AppTextStyles.heading.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                headline,
                                style: AppTextStyles.subtitle.copyWith(
                                  color: iconColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildOnlineToggle(isApproved),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (approvedSuccessBannerVisible && isApproved)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Profile approved successfully.',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              color: AppColors.success,
                              onPressed: () {
                                setState(() {
                                  approvedSuccessBannerVisible = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    if (approvedSuccessBannerVisible && isApproved)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Profile approved successfully.',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              color: AppColors.success,
                              onPressed: () {
                                setState(() {
                                  approvedSuccessBannerVisible = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildActiveTripCard(),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vehicle', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(
                            currentVehicle != null
                                ? '${currentVehicle!.brand} ${currentVehicle!.model}'
                                : 'No vehicle registered',
                            style: AppTextStyles.title,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentVehicle != null
                                ? _capitalize(currentVehicle!.status)
                                : _capitalize(statusText),
                            style: AppTextStyles.body.copyWith(
                              color: currentVehicle != null && currentVehicle!.status.toLowerCase() == 'approved'
                                  ? AppColors.success
                                  : currentVehicle != null && currentVehicle!.status.toLowerCase() == 'rejected'
                                      ? AppColors.danger
                                      : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('Today\'s Status', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(
                            isApproved ? 'No active trip' : isPending ? 'Account under review' : 'Profile rejected',
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildSummaryStat('Upcoming Scheduled Trips', '0')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSummaryStat('Completed Today', '0 Trips')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildSummaryStat('Today\'s Earnings', 'Rs 0')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSummaryStat('Pending Withdraw', 'Rs 0')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is AuthLoading || state is AuthInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: Text(
              'Unable to load dashboard.',
              style: AppTextStyles.subtitle,
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveTripCard() {
    if (loadingActiveTrip) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (activeTrip == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.route_outlined, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  activeTripError ?? 'No active trip right now.',
                  style: AppTextStyles.body,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final from = activeTrip!['from_city_name']?.toString() ?? 'Origin';
    final to = activeTrip!['to_city_name']?.toString() ?? 'Destination';
    final tripId = activeTrip!['id']?.toString() ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bus, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Active trip', style: AppTextStyles.title),
                ),
                Text('#$tripId', style: AppTextStyles.subtitle),
              ],
            ),
            const SizedBox(height: 12),
            Text('$from → $to', style: AppTextStyles.body),
            if (activeTrip!['departure_time'] != null) ...[
              const SizedBox(height: 6),
              Text(
                'Departure: ${activeTrip!['departure_time']}',
                style: AppTextStyles.subtitle,
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openActiveTrip,
                icon: const Icon(Icons.map_outlined),
                label: const Text('View trip map'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.subtitle),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.title.copyWith(color: accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(color: textColor),
          ),
        ),
      ],
    );
  }
}
