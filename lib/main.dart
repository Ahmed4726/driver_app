import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/routes/app_router_notifier.dart';
import 'core/services/secure_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initDependencies();

  final token = await sl<SecureStorageService>().getToken();
  sl<AppRouterNotifier>().setLoggedIn(token != null && token.isNotEmpty);

  runApp(const DriverApp());
}