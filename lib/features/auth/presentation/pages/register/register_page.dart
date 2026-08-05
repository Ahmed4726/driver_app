import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../../core/routes/route_names.dart';

import '../../bloc/register/register_bloc.dart';

import '../../../data/models/driver_registration.dart';

import 'personal_information_page.dart';
import 'driver_information_page.dart';
import 'additional_information_page.dart';
import 'upload_documents_page.dart';
import 'review_registration_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final PageController controller = PageController();

  int currentPage = 0;

  final DriverRegistration registration = DriverRegistration();

  static const int totalPages = 5;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void nextPage() {
    if (currentPage >= totalPages - 1) return;

    controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    setState(() {
      currentPage++;
    });
  }

  void previousPage() {
    if (currentPage <= 0) return;

    controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    setState(() {
      currentPage--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RegisterBloc>(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (currentPage > 0) {
                previousPage();
                return;
              }

              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RouteNames.login);
              }
            },
          ),
          title: const Text("Driver Registration"),
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: (currentPage + 1) / totalPages,
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Step ${currentPage + 1} of $totalPages",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: PageView(
                controller: controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  /// Step 1
                  PersonalInformationPage(
                    registration: registration,
                    onNext: nextPage,
                  ),

                  /// Step 2
                  DriverInformationPage(
                    registration: registration,
                    onNext: nextPage,
                    onBack: previousPage,
                  ),

                  /// Step 3
                  AdditionalInformationPage(
                    registration: registration,
                    onNext: nextPage,
                    onBack: previousPage,
                  ),

                  /// Step 4
                  UploadDocumentsPage(
                    registration: registration,
                    onNext: nextPage,
                    onBack: previousPage,
                  ),

                  /// Step 5
                  ReviewRegistrationPage(
                    registration: registration,
                    onBack: previousPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}