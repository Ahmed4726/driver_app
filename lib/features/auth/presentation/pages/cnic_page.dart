import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/data/models/update_driver_request.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/widgets/document_upload_card.dart';
import '../../../../core/utils/image_picker_helper.dart';

class CNICPage extends StatefulWidget {
  const CNICPage({super.key});

  @override
  State<CNICPage> createState() => _CNICPageState();
}

class _CNICPageState extends State<CNICPage> {
  DateTime? issueDate;
  DateTime? expiryDate;
  File? front;
  File? back;
  bool loading = false;

  Future<void> _pickImage(Function(File) onSelected) async {
    final file = await ImagePickerHelper.pickImage(context);
    if (file != null) setState(() => onSelected(file));
  }

  Future<void> _pickDate(bool isIssue) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => isIssue ? issueDate = picked : expiryDate = picked);
  }

  Future<void> _save() async {
    setState(() => loading = true);

    final request = UpdateDriverRequest(
      cnicFront: front,
      cnicBack: back,
      cnicIssueDate: issueDate,
      cnicExpiryDate: expiryDate,
    );

    context.read<AuthBloc>().add(ProfileUpdateSubmitted(request: request));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.profile),
        ),
        title: const Text('CNIC'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CNIC Dates', style: AppTextStyles.title),
            const SizedBox(height: 12),
            ListTile(
              title: Text(issueDate != null ? DateFormat('yyyy-MM-dd').format(issueDate!) : 'Select issue date'),
              leading: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(true),
            ),
            ListTile(
              title: Text(expiryDate != null ? DateFormat('yyyy-MM-dd').format(expiryDate!) : 'Select expiry date'),
              leading: const Icon(Icons.calendar_today_outlined),
              onTap: () => _pickDate(false),
            ),
            const SizedBox(height: 16),
            Text('CNIC Images', style: AppTextStyles.title),
            const SizedBox(height: 8),
            DocumentUploadCard(title: 'Front', subtitle: 'Tap to upload', file: front, onTap: () => _pickImage((f) => front = f)),
            DocumentUploadCard(title: 'Back', subtitle: 'Tap to upload', file: back, onTap: () => _pickImage((f) => back = f)),
            const SizedBox(height: 24),
            PrimaryButton(title: 'Save CNIC', loading: loading, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
