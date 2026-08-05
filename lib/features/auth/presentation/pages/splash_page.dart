import 'package:driver_app/core/routes/app_router_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../data/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/routes/route_names.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();

    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authRepository = sl<AuthRepository>();
    final loggedIn = await authRepository.isLoggedIn();
    sl<AppRouterNotifier>().setLoggedIn(loggedIn);

    if (!mounted) return;

    if (!loggedIn) {
      context.go(RouteNames.login);
      return;
    }

    context.read<AuthBloc>().add(CheckAuthentication());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(RouteNames.dashboard);
        }

        if (state is AuthUnauthenticated) {
          context.go(RouteNames.login);
        }
      },
      child: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              AppLogo(size: 120),

              SizedBox(height: 20),

              Text(
                "Transport Driver",
                style: AppTextStyles.heading,
              ),

              SizedBox(height: 40),

              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}