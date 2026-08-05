import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../data/models/driver_registration.dart';
import '../../../data/repositories/city_repository.dart';

class AdditionalInformationPage extends StatefulWidget {
  final DriverRegistration registration;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const AdditionalInformationPage({
    super.key,
    required this.registration,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<AdditionalInformationPage> createState() =>
      _AdditionalInformationPageState();
}

class _AdditionalInformationPageState
    extends State<AdditionalInformationPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _addressController;
  late final TextEditingController _dobController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;

  String? bloodGroup;
  List<String> cities = [];
  String? selectedCity;
  bool isLoadingCities = true;
  String? cityLoadError;

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
  void initState() {
    super.initState();

    _addressController = TextEditingController(
      text: widget.registration.address ?? '',
    );

    _dobController = TextEditingController(
      text: widget.registration.dateOfBirth == null
          ? ''
          : DateFormat(
              'yyyy-MM-dd',
            ).format(widget.registration.dateOfBirth!),
    );

    _emergencyNameController = TextEditingController(
      text: widget.registration.emergencyContactName ?? '',
    );

    _emergencyPhoneController = TextEditingController(
      text: widget.registration.emergencyContactPhone ?? '',
    );

    selectedCity = widget.registration.city;
    _loadCities();

    bloodGroup = widget.registration.bloodGroup;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _dobController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    widget.registration.dateOfBirth = picked;

    _dobController.text =
        DateFormat('yyyy-MM-dd').format(picked);
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
    } catch (e) {
      setState(() {
        cityLoadError = 'Unable to load cities';
      });
    } finally {
      setState(() {
        isLoadingCities = false;
      });
    }
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.registration.address =
        _addressController.text.trim();

    widget.registration.city = selectedCity;

    widget.registration.emergencyContactName =
        _emergencyNameController.text.trim();

    widget.registration.emergencyContactPhone =
        _emergencyPhoneController.text.trim();

    widget.registration.bloodGroup = bloodGroup;

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              Text(
                "Additional Information",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Address",
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 20),

              if (isLoadingCities)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (cityLoadError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    cityLoadError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: selectedCity,
                  decoration: const InputDecoration(
                    labelText: "City",
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
                    if (value == null || value.isEmpty) {
                      return 'Please select a city.';
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: _pickDob,
                decoration: const InputDecoration(
                  labelText: "Date of Birth",
                  prefixIcon: Icon(Icons.cake),
                ),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: bloodGroup,
                decoration: const InputDecoration(
                  labelText: "Blood Group",
                  prefixIcon: Icon(Icons.bloodtype),
                ),
                items: bloodGroups
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    bloodGroup = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _emergencyNameController,
                decoration: const InputDecoration(
                  labelText: "Emergency Contact Name",
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _emergencyPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Emergency Contact Phone",
                  prefixIcon: Icon(Icons.phone),
                ),
              ),

              const SizedBox(height: 40),

              Row(
                children: [

                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      child: const Text("Back"),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: _continue,
                      child: const Text("Continue"),
                    ),
                  ),

                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}