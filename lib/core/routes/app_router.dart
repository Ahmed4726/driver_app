import 'package:go_router/go_router.dart';

import '../di/service_locator.dart';
import 'app_router_notifier.dart';
import 'route_names.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/cnic_page.dart';
import '../../features/auth/presentation/pages/license_page.dart';
import '../../features/auth/presentation/pages/register/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_shell_page.dart';
import '../../features/home/presentation/pages/trips_page.dart';
import '../../features/home/presentation/pages/earnings_page.dart';
import '../../features/home/presentation/pages/rejected_driver_fix_page.dart';
import '../../features/vehicle/presentation/pages/vehicle_registration_page.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: RouteNames.splash,

    refreshListenable: sl<AppRouterNotifier>(),

    redirect: (context, state) {
      final loggedIn = sl<AppRouterNotifier>().loggedIn;

      final location = state.matchedLocation;

      if (location == RouteNames.splash) {
        return null;
      }

      final publicRoutes = {
        RouteNames.login,
        RouteNames.register,
      };

      if (!loggedIn && publicRoutes.contains(location)) {
        return null;
      }

      if (!loggedIn) {
        return RouteNames.login;
      }

      if (loggedIn && publicRoutes.contains(location)) {
        return RouteNames.dashboard;
      }

      return null;
    },

    routes: [

      GoRoute(
        path: RouteNames.splash,
        builder: (_, __) => const SplashPage(),
      ),

      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const LoginPage(),
      ),

      GoRoute(
        path: RouteNames.dashboard,
        builder: (context, state) {
          final tabParam = state.uri.queryParameters['tab'];
          final modeParam = state.uri.queryParameters['mode'];
          final initialTab = tabParam == '1'
              ? 1
              : tabParam == '2'
                  ? 2
                  : tabParam == '3'
                      ? 3
                      : 0;
          final initialTripMode = modeParam == 'create'
              ? TripPageMode.create
              : TripPageMode.list;

          return HomeShellPage(initialTab: initialTab, initialTripMode: initialTripMode);
        },
      ),
      GoRoute(
        path: RouteNames.vehicleRegistration,
        builder: (_, __) => const VehicleRegistrationPage(),
      ),
      GoRoute(
        path: RouteNames.trips,
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] == 'create'
              ? TripPageMode.create
              : TripPageMode.list;
          return HomeShellPage(initialTab: 1, initialTripMode: mode);
        },
      ),
      GoRoute(
        path: RouteNames.createTrip,
        builder: (_, __) => const HomeShellPage(initialTab: 1, initialTripMode: TripPageMode.create),
      ),
      GoRoute(
        path: RouteNames.earnings,
        builder: (_, __) => const EarningsPage(),
      ),
      GoRoute(
        path: RouteNames.rejectedFix,
        builder: (_, __) => const RejectedDriverFixPage(),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (_, __) => const ProfilePage(),
      ),
      GoRoute(
        path: RouteNames.cnic,
        builder: (_, __) => const CNICPage(),
      ),
      GoRoute(
        path: RouteNames.license,
        builder: (_, __) => const LicensePage(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (_, __) => const RegisterPage(),
      ),
    ],
  );
}
