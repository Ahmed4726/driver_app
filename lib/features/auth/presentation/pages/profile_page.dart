import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/data/models/update_driver_request.dart';
import '../../../auth/data/repositories/city_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/widgets/document_upload_card.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../../../core/routes/route_names.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool initialized = false;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final dobController = TextEditingController();
  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();

  String? selectedCity;
  List<String> cities = [];
  bool isLoadingCities = true;
  String? cityLoadError;
  String? selectedBloodGroup;

  File? profilePhoto;
  File? cnicFront;
  File? cnicBack;
  File? licenseFront;
  File? licenseBack;

  bool loading = false;
  String? remoteProfileImage;

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

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    dobController.dispose();
    emergencyNameController.dispose();
    emergencyPhoneController.dispose();
    super.dispose();
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

    setState(() {
      loading = true;
    });

    final request = UpdateDriverRequest(
      name: nameController.text.trim().isEmpty
          ? null
          : nameController.text.trim(),
      email: emailController.text.trim().isEmpty
          ? null
          : emailController.text.trim(),
      phone: phoneController.text.trim().isEmpty
          ? null
          : phoneController.text.trim(),
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
          ProfileUpdateSubmitted(request: request),
        );
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

  void _initializeForUser(AuthAuthenticated state) {
    if (initialized) return;
    final driver = state.user.driver;
    nameController.text = state.user.name;
    phoneController.text = state.user.phone;
    emailController.text = state.user.email;
    addressController.text = driver?.address ?? '';
    selectedCity = driver?.city;
    dobController.text = driver?.dateOfBirth ?? '';
    emergencyNameController.text = driver?.emergencyContactName ?? '';
    emergencyPhoneController.text = driver?.emergencyContactPhone ?? '';
    selectedBloodGroup = driver?.bloodGroup;
    remoteProfileImage = driver?.profilePhoto;
    initialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadCities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.dashboard),
        ),
        title: const Text('Profile'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUpdateSuccessful) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Profile updated successfully.'),
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
            if (state is AuthAuthenticated) {
              _initializeForUser(state);

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<AuthBloc>().add(CheckAuthentication());
                  await Future.delayed(const Duration(milliseconds: 400));
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _pickImage((file) => profilePhoto = file),
                              child: CircleAvatar(
                                radius: 72,
                                backgroundColor: AppColors.primary,
                                backgroundImage: profilePhoto != null
                                    ? FileImage(profilePhoto!)
                                    : (remoteProfileImage != null && remoteProfileImage!.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            'http://127.0.0.1:8000/storage/$remoteProfileImage',
                                          )
                                        : null),
                                child: profilePhoto == null && (remoteProfileImage == null || remoteProfileImage!.isEmpty)
                                    ? Text(
                                        state.user.name.isNotEmpty
                                            ? state.user.name.substring(0, 1).toUpperCase()
                                            : 'D',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.user.name,
                              style: AppTextStyles.title,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.user.email,
                              style: AppTextStyles.subtitle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            if (state.user.status.toLowerCase() != 'approved')
                              Text(
                                'Keep your profile accurate so admins can review your application quickly.',
                                style: AppTextStyles.body,
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Personal details', style: AppTextStyles.title),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          prefixIcon: Icon(Icons.phone_android),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.home),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (cityLoadError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            cityLoadError!,
                            style: AppTextStyles.body.copyWith(color: AppColors.danger),
                          ),
                        ),
                      if (isLoadingCities)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (cities.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'No cities available. Please try again later.',
                            style: AppTextStyles.body.copyWith(color: AppColors.danger),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: selectedCity,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(Icons.location_city),
                          ),
                          items: cities
                              .map(
                                (city) => DropdownMenuItem(value: city, child: Text(city)),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCity = value;
                            });
                          },
                          hint: const Text('Select city'),
                        ),
                      const SizedBox(height: 16),
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
                        decoration: const InputDecoration(
                          labelText: 'Date of birth',
                          prefixIcon: Icon(Icons.cake),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emergencyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Emergency contact name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emergencyPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Emergency contact phone',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedBloodGroup,
                        decoration: const InputDecoration(
                          labelText: 'Blood group',
                          prefixIcon: Icon(Icons.bloodtype),
                        ),
                        items: bloodGroups
                            .map(
                              (group) => DropdownMenuItem(value: group, child: Text(group)),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedBloodGroup = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      // Documents section removed per current requirement
                      // Text('Documents', style: AppTextStyles.title),
                      // const SizedBox(height: 12),
                      // DocumentUploadCard(
                      //   title: 'Profile Photo',
                      //   subtitle: 'Tap to choose a profile photo',
                      //   file: profilePhoto,
                      //   onTap: () => _pickImage((file) => profilePhoto = file),
                      // ),
                      // DocumentUploadCard(
                      //   title: 'CNIC',
                      //   subtitle: 'Open CNIC details and images',
                      //   file: cnicFront ?? cnicBack,
                      //   onTap: () => context.go(RouteNames.cnic),
                      // ),
                      // DocumentUploadCard(
                      //   title: 'License',
                      //   subtitle: 'Open license details and images',
                      //   file: licenseFront ?? licenseBack,
                      //   onTap: () => context.go(RouteNames.license),
                      // ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        title: 'Save profile',
                        loading: loading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                  ),
                ),
              );
            }

            if (state is AuthLoading || state is AuthInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            return Center(
              child: Text(
                'Unable to load profile.',
                style: AppTextStyles.subtitle,
              ),
            );
          },
        ),
      ),
    );
  }
}
