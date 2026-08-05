import 'package:driver_app/features/auth/data/datasource/register_remote_data_source.dart';
import 'package:driver_app/features/auth/data/repositories/register_repository.dart';

import '../models/driver_registration.dart';

class RegisterRepositoryImpl
    implements RegisterRepository {

  final RegisterRemoteDataSource remote;

  RegisterRepositoryImpl(this.remote);

  @override
  Future<void> register(
    DriverRegistration registration,
  ) async {
    await remote.register(registration);
  }
}