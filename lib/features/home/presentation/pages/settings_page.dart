import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/di/service_locator.dart';
import '../../../vehicle/data/models/vehicle_model.dart';
import '../../../vehicle/data/repositories/vehicle_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  VehicleModel? vehicle;
  bool loadingVehicle = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentVehicle();
  }

  Future<void> _loadCurrentVehicle() async {
    try {
      final currentVehicle = await sl<VehicleRepository>().getCurrentVehicle();
      setState(() {
        vehicle = currentVehicle;
      });
    } catch (_) {
      // ignore
    } finally {
      setState(() {
        loadingVehicle = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = vehicle?.status.toLowerCase() == 'rejected';
    final subtitle = isRejected
        ? 'Fix or resubmit your rejected vehicle'
        : 'Register or update your vehicle';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTextStyles.heading),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: const Text('Vehicle registration'),
                  subtitle: Text(subtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isRejected)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '1',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                  onTap: () => context.go(RouteNames.vehicleRegistration),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
