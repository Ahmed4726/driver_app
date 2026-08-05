import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routes/route_names.dart';
import '../../../data/models/driver_registration.dart';
import '../../bloc/register/register_bloc.dart';
import '../../bloc/register/register_event.dart';
import '../../bloc/register/register_state.dart';

class ReviewRegistrationPage extends StatefulWidget {
  final DriverRegistration registration;
  final VoidCallback onBack;

  const ReviewRegistrationPage({
    super.key,
    required this.registration,
    required this.onBack,
  });

  @override
  State<ReviewRegistrationPage> createState() =>
      _ReviewRegistrationPageState();
}

class _ReviewRegistrationPageState
    extends State<ReviewRegistrationPage> {
  bool acceptedTerms = false;

  String _formatDate(DateTime? date) {
    if (date == null) return "-";

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _tile(
    String title,
    String value,
  ) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(value.isEmpty ? "-" : value),
    );
  }

  Widget _document(
    String title,
    bool uploaded,
  ) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        uploaded
            ? Icons.check_circle
            : Icons.cancel,
        color:
            uploaded ? Colors.green : Colors.red,
      ),
      title: Text(title),
      subtitle: Text(
        uploaded ? "Uploaded" : "Missing",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
            ),
          );

          context.go(RouteNames.login);
        }

        if (state is RegisterFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(state.message),
            ),
          );
        }
      },
      builder: (context, state) {
        final loading = state is RegisterLoading;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  "Review Registration",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),

                const SizedBox(height: 8),

                Text(
                  "Please review all information before submitting.",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),

                const SizedBox(height: 30),

                _sectionTitle(
                    "👤 Personal Information"),

                _tile(
                  "Full Name",
                  widget.registration.name ?? "",
                ),

                _tile(
                  "Email",
                  widget.registration.email ?? "",
                ),

                _tile(
                  "Phone",
                  widget.registration.phone ?? "",
                ),

                const Divider(height: 40),

                _sectionTitle(
                    "🪪 Driver Information"),

                _tile(
                  "CNIC",
                  widget.registration.cnic ?? "",
                ),

                _tile(
                  "Licence Number",
                  widget.registration
                          .licenseNumber ??
                      "",
                ),

                _tile(
                  "Licence Expiry",
                  _formatDate(widget
                      .registration
                      .licenseExpiry),
                ),

                const Divider(height: 40),

                _sectionTitle(
                    "📍 Additional Information"),

                _tile(
                  "Address",
                  widget.registration.address ?? "",
                ),

                _tile(
                  "City",
                  widget.registration.city ?? "",
                ),

                _tile(
                  "Date of Birth",
                  _formatDate(widget
                      .registration
                      .dateOfBirth),
                ),

                _tile(
                  "Blood Group",
                  widget.registration
                          .bloodGroup ??
                      "",
                ),

                _tile(
                  "Emergency Contact",
                  widget.registration
                          .emergencyContactName ??
                      "",
                ),

                _tile(
                  "Emergency Phone",
                  widget.registration
                          .emergencyContactPhone ??
                      "",
                ),

                const Divider(height: 40),

                _sectionTitle(
                    "📷 Uploaded Documents"),

                _document(
                  "Profile Photo",
                  widget.registration
                          .profilePhoto !=
                      null,
                ),

                _document(
                  "CNIC Front",
                  widget.registration
                          .cnicFront !=
                      null,
                ),

                _document(
                  "CNIC Back",
                  widget.registration
                          .cnicBack !=
                      null,
                ),

                _document(
                  "Licence Front",
                  widget.registration
                          .licenseFront !=
                      null,
                ),

                _document(
                  "Licence Back",
                  widget.registration
                          .licenseBack !=
                      null,
                ),

                const SizedBox(height: 20),

                CheckboxListTile(
                  value: acceptedTerms,
                  contentPadding: EdgeInsets.zero,
                  onChanged: loading
                      ? null
                      : (value) {
                          setState(() {
                            acceptedTerms =
                                value ?? false;
                          });
                        },
                  title: const Text(
                    "I certify that all information provided is accurate.",
                  ),
                  controlAffinity:
                      ListTileControlAffinity.leading,
                ),

                const SizedBox(height: 25),

                Row(
                  children: [

                    Expanded(
                      child: OutlinedButton(
                        onPressed: loading
                            ? null
                            : widget.onBack,
                        child:
                            const Text("Back"),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: loading ||
                                !acceptedTerms
                            ? null
                            : () {
                                context
                                    .read<
                                        RegisterBloc>()
                                    .add(
                                      RegisterSubmitted(
                                        widget.registration,
                                      ),
                                    );
                              },
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Text(
                                "Submit",
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}