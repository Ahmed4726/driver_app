import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/route_names.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../vehicle/data/models/vehicle_model.dart';
import '../../../vehicle/data/repositories/vehicle_repository.dart';
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

  Widget _buildQuickAction(String title, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 150,
      child: FilledButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(title),
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passenger screen coming soon.')),
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
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: isApproved
                                ? () => context.go('${RouteNames.dashboard}?tab=1&mode=create')
                                : null,
                            child: const Text('Start New Trip'),
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
                    const SizedBox(height: 24),
                    Text('Quick Actions', style: AppTextStyles.title),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildQuickAction('Start Trip', Icons.play_arrow, () => context.go('${RouteNames.dashboard}?tab=1&mode=create')),
                        _buildQuickAction('Trips', Icons.list_alt, () => context.go(RouteNames.trips)),
                        _buildQuickAction('Passengers', Icons.people, () => _showComingSoon(context)),
                        _buildQuickAction('Vehicle', Icons.directions_car, () => context.go(RouteNames.vehicleRegistration)),
                        _buildQuickAction('Earnings', Icons.attach_money, () => context.go(RouteNames.earnings)),
                        _buildQuickAction('Profile', Icons.person, () => context.go(RouteNames.profile)),
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
