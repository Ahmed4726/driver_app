import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/data/models/update_driver_request.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/widgets/document_upload_card.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/data/repositories/city_repository.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../../../core/routes/route_names.dart';

class RejectedDriverFixPage extends StatefulWidget {
  const RejectedDriverFixPage({super.key});

  @override
  State<RejectedDriverFixPage> createState() => _RejectedDriverFixPageState();
}

class _RejectedDriverFixPageState extends State<RejectedDriverFixPage> {
  final _formKey = GlobalKey<FormState>();

  final addressController = TextEditingController();
  final dobController = TextEditingController();
  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();

  String? selectedCity;
  String? selectedBloodGroup;
  final List<String> bloodGroups = const [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  List<String> cities = [];
  bool isLoadingCities = true;
  String? cityLoadError;
  bool fieldsInitialized = false;

  Set<String> selectedIssueKeys = {};

  File? profilePhoto;
  File? cnicFront;
  File? cnicBack;
  File? licenseFront;
  File? licenseBack;

  bool loading = false;

  @override
  void dispose() {
    addressController.dispose();
    dobController.dispose();
    emergencyNameController.dispose();
    emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    setState(() {
      isLoadingCities = true;
      cityLoadError = null;
    });

    try {
      final loadedCities = await sl<CityRepository>().getCities();
      setState(() {
        cities = loadedCities;
        if (selectedCity != null && !cities.contains(selectedCity)) {
          selectedCity = null;
        }
      });
    } catch (_) {
      setState(() {
        cityLoadError = 'Unable to load cities';
      });
    } finally {
      setState(() {
        isLoadingCities = false;
      });
    }
  }

  Widget _buildField(
    String key,
    String label,
    TextEditingController controller,
  ) {
    final isSelected = selectedIssueKeys.contains(key);

    if (!isSelected) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter $label.';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(_iconForKey(key)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  IconData _iconForKey(String key) {
    switch (key) {
      case 'address':
        return Icons.home;
      case 'city':
        return Icons.location_city;
      case 'date_of_birth':
        return Icons.cake;
      case 'emergency_contact_name':
        return Icons.person_outline;
      case 'emergency_contact_phone':
        return Icons.phone;
      case 'blood_group':
        return Icons.bloodtype;
      case 'profile_photo':
        return Icons.photo;
      case 'cnic_front':
      case 'cnic_back':
        return Icons.badge;
      case 'license_front':
      case 'license_back':
        return Icons.drive_eta;
      default:
        return Icons.edit;
    }
  }

  Future<void> _pickImage(Function(File) onSelected) async {
    final file = await ImagePickerHelper.pickImage(context);
    if (file != null) {
      setState(() {
        onSelected(file);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final requiredDocumentIssues = [
      'profile_photo',
      'cnic_front',
      'cnic_back',
      'license_front',
      'license_back',
    ];

    final missingDocumentIssue = requiredDocumentIssues.firstWhere(
      (issue) => selectedIssueKeys.contains(issue) && _hasNoFile(issue),
      orElse: () => '',
    );

    if (missingDocumentIssue.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please upload the required document before resubmitting.'),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final request = UpdateDriverRequest(
      address: addressController.text.trim().isEmpty
          ? null
          : addressController.text.trim(),
      city: selectedCity,
      dateOfBirth: dobController.text.trim().isEmpty
          ? null
          : DateTime.tryParse(dobController.text.trim()),
      emergencyContactName: emergencyNameController.text.trim().isEmpty
          ? null
          : emergencyNameController.text.trim(),
      emergencyContactPhone: emergencyPhoneController.text.trim().isEmpty
          ? null
          : emergencyPhoneController.text.trim(),
      bloodGroup: selectedBloodGroup,
      profilePhoto: profilePhoto,
      cnicFront: cnicFront,
      cnicBack: cnicBack,
      licenseFront: licenseFront,
      licenseBack: licenseBack,
    );

    context.read<AuthBloc>().add(
          UpdateDriverProfileSubmitted(request: request),
        );
  }

  bool _hasNoFile(String issue) {
    switch (issue) {
      case 'profile_photo':
        return profilePhoto == null;
      case 'cnic_front':
        return cnicFront == null;
      case 'cnic_back':
        return cnicBack == null;
      case 'license_front':
        return licenseFront == null;
      case 'license_back':
        return licenseBack == null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leadingWidth: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.dashboard),
        ),
        title: const Text('Fix Application'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUpdateSuccessful) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Application resubmitted successfully.'),
              ),
            );
            context.go(RouteNames.dashboard);
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red,
                content: Text(state.message),
              ),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state is AuthAuthenticated ? state.user : null;
            final driver = user?.driver;

            if (driver != null && !fieldsInitialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  selectedIssueKeys = Set<String>.from(driver.rejectionIssues ?? []);
                  selectedCity = selectedCity ?? driver.city;
                  selectedBloodGroup = selectedBloodGroup ?? driver.bloodGroup;
                  if (dobController.text.isEmpty && driver.dateOfBirth != null) {
                    dobController.text = driver.dateOfBirth!;
                  }
                  fieldsInitialized = true;
                });
                _loadCities();
              });
            }

            final issueLines = <String>[];
            final rejectionRemarks = driver?.remarks;
            final issueMap = {
              'profile_photo': 'Profile photo',
              'cnic_front': 'CNIC front',
              'cnic_back': 'CNIC back',
              'license_front': 'License front',
              'license_back': 'License back',
              'address': 'Address',
              'city': 'City',
              'date_of_birth': 'Date of birth',
              'emergency_contact_name': 'Emergency contact name',
              'emergency_contact_phone': 'Emergency contact phone',
              'blood_group': 'Blood group',
            };

            final selectedIssues = driver?.rejectionIssues
                    ?.map((issue) => issueMap[issue] ?? issue)
                    .toList() ??
                [];

            if (selectedIssues.isNotEmpty) {
              issueLines.add('Fix the following items: ${selectedIssues.join(', ')}');
            }
            if (rejectionRemarks != null && rejectionRemarks.isNotEmpty) {
              issueLines.insert(0, 'Rejection reason: $rejectionRemarks');
            }
            if (selectedIssues.isEmpty && driver != null) {
              issueLines.add(
                'No specific issues were selected by admin. Please review your profile and update the most relevant information.',
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (issueLines.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: issueLines
                              .map(
                                (issue) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    issue,
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      'Update your application',
                      style: AppTextStyles.heading,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add missing details or replace rejected documents so we can review your profile again.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 24),
                    if (selectedIssueKeys.contains('address'))
                      _buildField('address', 'Address', addressController),
                    if (selectedIssueKeys.contains('city')) ...[
                      isLoadingCities
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : DropdownButtonFormField<String>(
                              value: selectedCity,
                              decoration: const InputDecoration(
                                labelText: 'City',
                                prefixIcon: Icon(Icons.location_city),
                              ),
                              items: cities
                                  .map(
                                    (city) => DropdownMenuItem(
                                      value: city,
                                      child: Text(city),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCity = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please select City.';
                                }
                                return null;
                              },
                              hint: const Text('Select city'),
                            ),
                      const SizedBox(height: 16),
                    ],
                    if (cityLoadError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        child: Text(
                          cityLoadError!,
                          style: AppTextStyles.body.copyWith(color: AppColors.danger),
                        ),
                      ),
                    if (selectedIssueKeys.contains('date_of_birth')) ...[
                      TextFormField(
                        controller: dobController,
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            dobController.text = picked.toIso8601String().split('T').first;
                          }
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please select Date of birth.';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Date of birth',
                          prefixIcon: Icon(Icons.cake),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (selectedIssueKeys.contains('emergency_contact_name'))
                      _buildField('emergency_contact_name', 'Emergency contact name', emergencyNameController),
                    if (selectedIssueKeys.contains('emergency_contact_phone'))
                      _buildField('emergency_contact_phone', 'Emergency contact phone', emergencyPhoneController),
                    if (selectedIssueKeys.contains('blood_group')) ...[
                      DropdownButtonFormField<String>(
                        value: selectedBloodGroup,
                        decoration: const InputDecoration(
                          labelText: 'Blood group',
                          prefixIcon: Icon(Icons.bloodtype),
                        ),
                        items: bloodGroups
                            .map(
                              (group) => DropdownMenuItem(
                                value: group,
                                child: Text(group),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedBloodGroup = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please select Blood group.';
                          }
                          return null;
                        },
                        hint: const Text('Select blood group'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (selectedIssueKeys.contains('profile_photo') ||
                        selectedIssueKeys.contains('cnic_front') ||
                        selectedIssueKeys.contains('cnic_back') ||
                        selectedIssueKeys.contains('license_front') ||
                        selectedIssueKeys.contains('license_back')) ...[
                      const SizedBox(height: 8),
                      Text('Replace documents', style: AppTextStyles.title),
                      const SizedBox(height: 12),
                      if (selectedIssueKeys.contains('profile_photo'))
                        DocumentUploadCard(
                          title: 'Profile Photo',
                          subtitle: 'Tap to choose a new profile photo',
                          file: profilePhoto,
                          onTap: () => _pickImage((file) => profilePhoto = file),
                        ),
                      if (selectedIssueKeys.contains('cnic_front'))
                        DocumentUploadCard(
                          title: 'CNIC Front',
                          subtitle: 'Tap to replace CNIC front',
                          file: cnicFront,
                          onTap: () => _pickImage((file) => cnicFront = file),
                        ),
                      if (selectedIssueKeys.contains('cnic_back'))
                        DocumentUploadCard(
                          title: 'CNIC Back',
                          subtitle: 'Tap to replace CNIC back',
                          file: cnicBack,
                          onTap: () => _pickImage((file) => cnicBack = file),
                        ),
                      if (selectedIssueKeys.contains('license_front'))
                        DocumentUploadCard(
                          title: 'License Front',
                          subtitle: 'Tap to replace license front',
                          file: licenseFront,
                          onTap: () => _pickImage((file) => licenseFront = file),
                        ),
                      if (selectedIssueKeys.contains('license_back'))
                        DocumentUploadCard(
                          title: 'License Back',
                          subtitle: 'Tap to replace license back',
                          file: licenseBack,
                          onTap: () => _pickImage((file) => licenseBack = file),
                        ),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      title: 'Resubmit application',
                      loading: loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
