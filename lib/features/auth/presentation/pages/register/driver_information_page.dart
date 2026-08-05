import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../data/models/driver_registration.dart';

class DriverInformationPage extends StatefulWidget {
  final DriverRegistration registration;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const DriverInformationPage({
    super.key,
    required this.registration,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<DriverInformationPage> createState() =>
      _DriverInformationPageState();
}

class _DriverInformationPageState
    extends State<DriverInformationPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _cnicController;
  late final TextEditingController _licenseController;
  late final TextEditingController _expiryController;

  DateTime? _selectedExpiryDate;

  @override
  void initState() {
    super.initState();

    _cnicController = TextEditingController(
      text: widget.registration.cnic ?? '',
    );

    _licenseController = TextEditingController(
      text: widget.registration.licenseNumber ?? '',
    );

    _selectedExpiryDate = widget.registration.licenseExpiry;

    _expiryController = TextEditingController(
      text: _selectedExpiryDate != null
          ? DateFormat('dd MMM yyyy')
              .format(_selectedExpiryDate!)
          : '',
    );
  }

  @override
  void dispose() {
    _cnicController.dispose();
    _licenseController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedExpiryDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 20),
    );

    if (picked == null) return;

    setState(() {
      _selectedExpiryDate = picked;

      _expiryController.text =
          DateFormat('dd MMM yyyy').format(picked);
    });
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.registration.cnic =
        _cnicController.text.trim();

    widget.registration.licenseNumber =
        _licenseController.text.trim();

    widget.registration.licenseExpiry =
        _selectedExpiryDate;

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
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                "Driver Information",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),

              const SizedBox(height: 8),

              Text(
                "Provide your driving licence details.",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: _cnicController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CnicInputFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: "CNIC Number",
                  hintText: "35202-1234567-1",
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "CNIC is required";
                  }

                  final regex = RegExp(
                    r'^\d{5}-\d{7}-\d$',
                  );

                  if (!regex.hasMatch(value)) {
                    return "Enter a valid CNIC";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: "Driving Licence Number",
                  prefixIcon: Icon(Icons.drive_eta),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "Licence number is required";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _expiryController,
                readOnly: true,
                onTap: _pickExpiryDate,
                decoration: const InputDecoration(
                  labelText: "Licence Expiry Date",
                  prefixIcon:
                      Icon(Icons.calendar_month),
                  suffixIcon:
                      Icon(Icons.arrow_drop_down),
                ),
                validator: (value) {
                  if (_selectedExpiryDate == null) {
                    return "Please select expiry date";
                  }

                  return null;
                },
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

class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits =
        newValue.text.replaceAll('-', '');

    if (digits.length > 13) {
      digits = digits.substring(0, 13);
    }

    String formatted = '';

    for (int i = 0; i < digits.length; i++) {
      formatted += digits[i];

      if ((i == 4 || i == 11) &&
          i != digits.length - 1) {
        formatted += '-';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}