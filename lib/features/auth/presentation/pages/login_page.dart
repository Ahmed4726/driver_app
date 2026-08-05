import 'package:driver_app/core/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppSnackbar.error(context, state.message);
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [

                        const AppLogo(size: 110),

                        const SizedBox(height: 24),

                        const Text(
                          "Welcome Back",
                          style: AppTextStyles.heading,
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "Sign in to continue",
                          style: AppTextStyles.subtitle,
                        ),

                        const SizedBox(height: 40),

                        AppTextField(
                          controller: emailController,
                          label: "Email",
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),

                        const SizedBox(height: 18),

                        AppTextField(
                          controller: passwordController,
                          label: "Password",
                          obscureText: obscurePassword,
                          validator: Validators.password,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 30),

                        PrimaryButton(
                          title: "Login",
                          loading: state is AuthLoading,
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            context.read<AuthBloc>().add(
                                  LoginSubmitted(
                                    email: emailController.text.trim(),
                                    password: passwordController.text,
                                  ),
                                );
                          },
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            context.push(RouteNames.register);
                          },
                          child: const Text(
                            "Don't have an account? Register",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
    );
  }
}