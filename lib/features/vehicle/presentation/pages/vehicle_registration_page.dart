import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../../../core/routes/route_names.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/vehicle_type_model.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class VehicleRegistrationPage extends StatefulWidget {
  const VehicleRegistrationPage({super.key});

  @override
  State<VehicleRegistrationPage> createState() => _VehicleRegistrationPageState();
}

class _VehicleRegistrationPageState extends State<VehicleRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final brandController = TextEditingController();
  final modelController = TextEditingController();
  final manufactureYearController = TextEditingController();
  final colorController = TextEditingController();
  final registrationNumberController = TextEditingController();
  final engineNumberController = TextEditingController();
  final chassisNumberController = TextEditingController();
  final totalSeatsController = TextEditingController();
  final availableSeatsController = TextEditingController();

  int? selectedVehicleTypeId;
  List<VehicleTypeModel> vehicleTypes = [];

  List<File> vehiclePhotos = [];
  File? registrationBook;
  File? fitnessCertificate;
  File? insuranceDocument;

  VehicleModel? currentVehicle;
  bool loading = false;
  bool loadingTypes = true;
  bool loadingVehicle = true;
  bool driverApproved = false;

  bool get isPending => currentVehicle?.status.toLowerCase() == 'pending';
  bool get isRejected => currentVehicle?.status.toLowerCase() == 'rejected';
  bool get isApproved => currentVehicle?.status.toLowerCase() == 'approved';
  bool get canEdit => currentVehicle == null ? driverApproved : isRejected;

  List<String> get selectedFieldsToUpdate => currentVehicle?.rejectionIssues ?? [];

  bool get _shouldFilterRejectedFields => isRejected && selectedFieldsToUpdate.isNotEmpty;

  bool _showRejectedField(String key) {
    if (!_shouldFilterRejectedFields) return true;

    if (key == 'vehicle_photos') {
      return selectedFieldsToUpdate.contains('vehicle_photos') || selectedFieldsToUpdate.contains('vehicle_photo');
    }

    return selectedFieldsToUpdate.contains(key);
  }

  String _fieldLabel(String fieldKey) {
    switch (fieldKey) {
      case 'vehicle_photo':
        return 'Vehicle photo';
      case 'vehicle_photos':
        return 'Vehicle photos';
      case 'registration_book':
        return 'Registration book';
      case 'fitness_certificate':
        return 'Fitness certificate';
      case 'insurance_document':
        return 'Insurance document';
      case 'brand':
        return 'Brand';
      case 'model':
        return 'Model';
      case 'manufacture_year':
        return 'Manufacture year';
      case 'color':
        return 'Color';
      case 'registration_number':
        return 'Registration number';
      case 'engine_number':
        return 'Engine number';
      case 'chassis_number':
        return 'Chassis number';
      case 'total_seats':
        return 'Total seats';
      case 'available_seats':
        return 'Available seats';
      default:
        return fieldKey
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}')
          .join(' ');
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
    _loadCurrentVehicle();
  }

  @override
  void dispose() {
    brandController.dispose();
    modelController.dispose();
    manufactureYearController.dispose();
    colorController.dispose();
    registrationNumberController.dispose();
    engineNumberController.dispose();
    chassisNumberController.dispose();
    totalSeatsController.dispose();
    availableSeatsController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleTypes() async {
    try {
      final types = await sl<VehicleRepository>().getVehicleTypes();
      setState(() {
        vehicleTypes = types;
        loadingTypes = false;
      });
    } catch (_) {
      setState(() {
        loadingTypes = false;
      });
    }
  }

  Future<void> _loadCurrentVehicle() async {
    try {
      final vehicle = await sl<VehicleRepository>().getCurrentVehicle();
      if (vehicle != null) {
        setState(() {
          currentVehicle = vehicle;
          selectedVehicleTypeId = vehicle.vehicleTypeId;
          brandController.text = vehicle.brand;
          modelController.text = vehicle.model;
          manufactureYearController.text = vehicle.manufactureYear.toString();
          colorController.text = vehicle.color;
          registrationNumberController.text = vehicle.registrationNumber;
          engineNumberController.text = vehicle.engineNumber;
          chassisNumberController.text = vehicle.chassisNumber;
          totalSeatsController.text = vehicle.totalSeats.toString();
          availableSeatsController.text = vehicle.availableSeats.toString();
        });
      }
    } catch (_) {
      // ignore
    } finally {
      setState(() {
        loadingVehicle = false;
      });
    }
  }

  Future<void> _pickFile(Function(File) onSelected) async {
    final file = await ImagePickerHelper.pickImage(context);
    if (file != null) {
      setState(() {
        onSelected(file);
      });
    }
  }

  Future<void> _submit() async {
    if (!canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Your vehicle registration is under review. Please wait for admin approval.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (vehiclePhotos.length > 0 && vehiclePhotos.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Select at least 5 vehicle photos or remove the selection.'),
        ),
      );
      return;
    }

    if (currentVehicle == null && vehiclePhotos.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('At least 5 vehicle photos are required.'),
        ),
      );
      return;
    }

    if (currentVehicle == null && registrationBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Registration book is required.'),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final payload = <String, dynamic>{
      'vehicle_type_id': selectedVehicleTypeId,
      'brand': brandController.text.trim(),
      'model': modelController.text.trim(),
      'manufacture_year': int.parse(manufactureYearController.text.trim()),
      'color': colorController.text.trim(),
      'registration_number': registrationNumberController.text.trim(),
      'engine_number': engineNumberController.text.trim(),
      'chassis_number': chassisNumberController.text.trim(),
      'total_seats': int.parse(totalSeatsController.text.trim()),
      'available_seats': int.parse(availableSeatsController.text.trim()),
    };

    if (vehiclePhotos.isNotEmpty) {
      payload['vehicle_photos'] = await Future.wait(vehiclePhotos.asMap().entries.map(
        (entry) async {
          final index = entry.key;
          final file = entry.value;
          return MultipartFile.fromFile(
            file.path,
            filename: 'vehicle_photo_${index + 1}.jpg',
          );
        },
      ));
    }

    if (registrationBook != null) {
      payload['registration_book'] = await MultipartFile.fromFile(
        registrationBook!.path,
        filename: 'registration_book.jpg',
      );
    }

    if (fitnessCertificate != null) {
      payload['fitness_certificate'] = await MultipartFile.fromFile(
        fitnessCertificate!.path,
        filename: 'fitness_certificate.jpg',
      );
    }

    if (insuranceDocument != null) {
      payload['insurance_document'] = await MultipartFile.fromFile(
        insuranceDocument!.path,
        filename: 'insurance_document.jpg',
      );
    }

    try {
      final vehicle = currentVehicle != null
          ? await sl<VehicleRepository>().updateVehicle(currentVehicle!.id, payload)
          : await sl<VehicleRepository>().registerVehicle(payload);

      if (!mounted) return;
      setState(() {
        currentVehicle = vehicle;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Vehicle submitted for review.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  List<Widget> _buildVehicleInputFields() {
    return [
      if (_showRejectedField('vehicle_type_id')) ...[
        DropdownButtonFormField<int>(
          value: selectedVehicleTypeId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Vehicle type'),
          items: vehicleTypes
              .map(
                (type) => DropdownMenuItem(
                  value: type.id,
                  child: Text(type.name),
                ),
              )
              .toList(),
          onChanged: canEdit
              ? (value) => setState(() {
                    selectedVehicleTypeId = value;
                  })
              : null,
          validator: (value) => value == null ? 'Select vehicle type' : null,
        ),
        const SizedBox(height: 16),
      ],
      if (_showRejectedField('brand')) ...[
        AppTextField(
          controller: brandController,
          label: 'Brand',
          enabled: canEdit,
          validator: (value) => value == null || value.trim().isEmpty ? 'Enter brand' : null,
        ),
        const SizedBox(height: 16),
      ],
      if (_showRejectedField('model')) ...[
        AppTextField(
          controller: modelController,
          label: 'Model',
          enabled: canEdit,
          validator: (value) => value == null || value.trim().isEmpty ? 'Enter model' : null,
        ),
        const SizedBox(height: 16),
      ],
      if (_showRejectedField('manufacture_year')) ...[
        AppTextField(
          controller: manufactureYearController,
          label: 'Manufacture year',
          enabled: canEdit,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter manufacture year';
            }
            final year = int.tryParse(value.trim());
            if (year == null || year < 1900 || year > DateTime.now().year) {
              return 'Enter a valid year';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
      if (_showRejectedField('color')) ...[
        AppTextField(
          controller: colorController,
          label: 'Color',
          enabled: canEdit,
          validator: (value) => value == null || value.trim().isEmpty ? 'Enter color' : null,
        ),
        const SizedBox(height: 16),
      ],
      if (_showRejectedField('registration_number')) ...[
        AppTextField(
          controller: registrationNumberController,
          label: 'Registration number',
          enabled: canEdit,
          validator: (value) => value == null || value.trim().isEmpty ? 'Enter registration number' : null,
        ),
        const SizedBox(height: 16),
      ],
      if (_showRejectedField('engine_number')) ...[
        AppTextField(
          controller: engineNumberController,
          label: 'Engine number',
          enabled: canEdit,
        ),
        const SizedBox(height: 16),
      ],
      if (_showRejectedField('chassis_number')) ...[
        AppTextField(
          controller: chassisNumberController,
          label: 'Chassis number',
          enabled: canEdit,
        ),
        const SizedBox(height: 16),
      ],
      if (_showRejectedField('total_seats')) ...[
        AppTextField(
          controller: totalSeatsController,
          label: 'Total seats',
          enabled: canEdit,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
      ],
      if (_showRejectedField('available_seats')) ...[
        AppTextField(
          controller: availableSeatsController,
          label: 'Available seats',
          enabled: canEdit,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
      ],
      if (_showRejectedField('vehicle_photos')) ...[
        ElevatedButton(
          onPressed: canEdit
              ? () => _pickFile((file) {
                    setState(() {
                      if (vehiclePhotos.length < 10) {
                        vehiclePhotos.add(file);
                      }
                    });
                  })
              : null,
          child: Text(
            vehiclePhotos.isEmpty
                ? 'Add vehicle photos (5+ required)'
                : 'Add more vehicle photos (${vehiclePhotos.length})',
          ),
        ),
        if (vehiclePhotos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vehiclePhotos.asMap().entries.map(
              (entry) {
                final index = entry.key;
                return Chip(
                  label: Text('Photo ${index + 1}'),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: canEdit
                      ? () {
                          setState(() {
                            vehiclePhotos.removeAt(index);
                          });
                        }
                      : null,
                );
              },
            ).toList(),
          ),
        ],
        const SizedBox(height: 12),
      ],
      if (_showRejectedField('registration_book')) ...[
        ElevatedButton(
          onPressed: canEdit ? () => _pickFile((file) => registrationBook = file) : null,
          child: Text(registrationBook == null ? 'Upload registration book' : 'Registration book selected'),
        ),
        const SizedBox(height: 12),
      ],
      if (_showRejectedField('fitness_certificate')) ...[
        ElevatedButton(
          onPressed: canEdit ? () => _pickFile((file) => fitnessCertificate = file) : null,
          child: Text(fitnessCertificate == null ? 'Upload fitness certificate (optional)' : 'Fitness certificate selected'),
        ),
        const SizedBox(height: 12),
      ],
      if (_showRejectedField('insurance_document')) ...[
        ElevatedButton(
          onPressed: canEdit ? () => _pickFile((file) => insuranceDocument = file) : null,
          child: Text(insuranceDocument == null ? 'Upload insurance document (optional)' : 'Insurance document selected'),
        ),
        const SizedBox(height: 24),
      ],
      PrimaryButton(
        title: currentVehicle == null
            ? 'Register vehicle'
            : isRejected
                ? 'Resubmit vehicle'
                : 'Submit for review',
        onPressed: canEdit ? _submit : null,
        loading: loading,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    driverApproved = authState is AuthAuthenticated && authState.user.status.toLowerCase() == 'approved';

    final pageTitle = currentVehicle == null
        ? 'Vehicle Registration'
        : isPending
            ? 'Vehicle Under Review'
            : isRejected
                ? 'Vehicle Rejected'
                : 'Vehicle Registered';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.dashboard);
            }
          },
        ),
        title: Text(pageTitle),
      ),
      body: (loadingTypes || loadingVehicle)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentVehicle == null
                          ? 'Fill in your vehicle details to register and start receiving rides.'
                          : 'Update your vehicle information below and resubmit for review.',
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!driverApproved && currentVehicle == null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Vehicle registration is disabled until your driver profile is approved.',
                          style: AppTextStyles.body.copyWith(color: AppColors.warning),
                        ),
                      ),
                    if (!driverApproved && currentVehicle != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Vehicle updates are disabled until your driver profile is approved.',
                          style: AppTextStyles.body.copyWith(color: AppColors.warning),
                        ),
                      ),
                    if ((!driverApproved && currentVehicle == null) ||
                        (!driverApproved && currentVehicle != null))
                      const SizedBox(height: 24),
                    if (currentVehicle != null) ...[
                      Text('Current vehicle status', style: AppTextStyles.subtitle),
                      const SizedBox(height: 8),
                      Text(
                        currentVehicle!.status,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPending
                                  ? 'Submitted and under review'
                                  : isRejected
                                      ? 'Vehicle rejected. Fix the fields below and resubmit.'
                                      : 'Vehicle approved. Vehicle is registered successfully.',
                              style: AppTextStyles.subtitle.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (currentVehicle!.remarks != null && currentVehicle!.remarks!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                currentVehicle!.remarks!,
                                style: AppTextStyles.body.copyWith(
                                  color: isRejected ? AppColors.danger : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (currentVehicle == null) ...[
                      Text('Register your vehicle', style: AppTextStyles.subtitle),
                      const SizedBox(height: 16),
                      ..._buildVehicleInputFields(),
                    ] else if (isPending) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Your vehicle registration is under review. Please wait for admin review and do not submit a new request.',
                          style: AppTextStyles.body.copyWith(color: AppColors.warning),
                        ),
                      ),
                    ] else if (isRejected) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vehicle rejected. Fix the issues below and resubmit.',
                              style: AppTextStyles.subtitle.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (selectedFieldsToUpdate.isNotEmpty) ...[
                              Text(
                                'Please update only the fields marked by admin:',
                                style: AppTextStyles.body.copyWith(color: AppColors.danger),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: selectedFieldsToUpdate.map(
                                  (field) => Chip(
                                    label: Text(_fieldLabel(field)),
                                    backgroundColor: AppColors.danger.withOpacity(0.12),
                                    labelStyle: AppTextStyles.body.copyWith(color: AppColors.danger),
                                  ),
                                ).toList(),
                              ),
                            ] else ...[
                              Text(
                                'Admin requested changes. Update the form below and resubmit.',
                                style: AppTextStyles.body.copyWith(color: AppColors.danger),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ..._buildVehicleInputFields(),
                    ] else if (isApproved) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vehicle registered successfully.',
                              style: AppTextStyles.subtitle.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow('Vehicle type', currentVehicle!.vehicleType),
                            const SizedBox(height: 8),
                            _buildDetailRow('Brand', currentVehicle!.brand),
                            const SizedBox(height: 8),
                            _buildDetailRow('Model', currentVehicle!.model),
                            const SizedBox(height: 8),
                            _buildDetailRow('Registration number', currentVehicle!.registrationNumber),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
