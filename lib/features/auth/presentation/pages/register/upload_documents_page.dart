import 'package:flutter/material.dart';

import '../../../../../core/utils/image_picker_helper.dart';
import '../../../data/models/driver_registration.dart';
import '../../widgets/document_upload_card.dart';

class UploadDocumentsPage extends StatefulWidget {
  final DriverRegistration registration;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const UploadDocumentsPage({
    super.key,
    required this.registration,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<UploadDocumentsPage> createState() =>
      _UploadDocumentsPageState();
}

class _UploadDocumentsPageState
    extends State<UploadDocumentsPage> {
  bool get isCompleted =>
      widget.registration.profilePhoto != null &&
      widget.registration.cnicFront != null &&
      widget.registration.cnicBack != null &&
      widget.registration.licenseFront != null &&
      widget.registration.licenseBack != null;

  Future<void> _pickProfilePhoto() async {
    final file = await ImagePickerHelper.pickImage(context);

    if (file == null) return;

    setState(() {
      widget.registration.profilePhoto = file;
    });
  }

  Future<void> _pickCnicFront() async {
    final file = await ImagePickerHelper.pickImage(context);

    if (file == null) return;

    setState(() {
      widget.registration.cnicFront = file;
    });
  }

  Future<void> _pickCnicBack() async {
    final file = await ImagePickerHelper.pickImage(context);

    if (file == null) return;

    setState(() {
      widget.registration.cnicBack = file;
    });
  }

  Future<void> _pickLicenseFront() async {
    final file = await ImagePickerHelper.pickImage(context);

    if (file == null) return;

    setState(() {
      widget.registration.licenseFront = file;
    });
  }

  Future<void> _pickLicenseBack() async {
    final file = await ImagePickerHelper.pickImage(context);

    if (file == null) return;

    setState(() {
      widget.registration.licenseBack = file;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Text(
                    "Upload Documents",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Please upload clear images of all required documents.",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),

                  const SizedBox(height: 24),

                  DocumentUploadCard(
                    title: "Profile Photo",
                    subtitle: "Take or choose a profile photo",
                    file: widget.registration.profilePhoto,
                    onTap: _pickProfilePhoto,
                  ),

                  DocumentUploadCard(
                    title: "CNIC Front",
                    subtitle: "Front side of your CNIC",
                    file: widget.registration.cnicFront,
                    onTap: _pickCnicFront,
                  ),

                  DocumentUploadCard(
                    title: "CNIC Back",
                    subtitle: "Back side of your CNIC",
                    file: widget.registration.cnicBack,
                    onTap: _pickCnicBack,
                  ),

                  DocumentUploadCard(
                    title: "Driving Licence Front",
                    subtitle: "Front side of licence",
                    file: widget.registration.licenseFront,
                    onTap: _pickLicenseFront,
                  ),

                  DocumentUploadCard(
                    title: "Driving Licence Back",
                    subtitle: "Back side of licence",
                    file: widget.registration.licenseBack,
                    onTap: _pickLicenseBack,
                  ),

                  if (!isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        "Please upload all required documents to continue.",
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

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
                    onPressed: isCompleted
                        ? widget.onNext
                        : null,
                    child: const Text("Continue"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}