import 'package:get_it/get_it.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/data/datasource/auth_remote_datasource.dart';
import '../../features/auth/data/datasource/city_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/city_repository.dart';
import '../../features/auth/data/repositories/city_repository_impl.dart';
import '../../features/vehicle/data/datasource/vehicle_remote_datasource.dart';
import '../../features/vehicle/data/repositories/vehicle_repository.dart';
import '../../features/vehicle/data/repositories/vehicle_repository_impl.dart';
import '../services/secure_storage_service.dart';
import '../routes/app_router_notifier.dart';
import '../services/network_service.dart';
import '../../features/auth/presentation/bloc/register/register_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerLazySingleton<NetworkService>(
    () => NetworkService(),
  );

  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(),
  );

  sl.registerLazySingleton<CityRemoteDataSource>(
    () => CityRemoteDataSource(),
  );

  sl.registerLazySingleton<CityRepository>(
    () => CityRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<VehicleRemoteDataSource>(
    () => VehicleRemoteDataSource(),
  );

  sl.registerLazySingleton<VehicleRepository>(
    () => VehicleRepositoryImpl(sl()),
  );

  sl.registerSingleton<AppRouterNotifier>(
    AppRouterNotifier(),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(sl()),
  );

  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(sl()),
  );
  sl.registerFactory<RegisterBloc>(
    () => RegisterBloc(
      sl<AuthRepository>(),
    ),
  );
}