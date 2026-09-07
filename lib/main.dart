import 'dart:io';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/routes/app_router_notifier.dart';
import 'core/services/secure_storage_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️ TESTING ONLY:
  // Accepts invalid/self-signed SSL certificates.
  // HttpOverrides.global = MyHttpOverrides();

  await initDependencies();

  final token = await sl<SecureStorageService>().getToken();
  sl<AppRouterNotifier>().setLoggedIn(token != null && token.isNotEmpty);

  runApp(const DriverApp());
}
