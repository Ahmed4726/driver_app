import '../models/driver_registration.dart';

abstract class RegisterRemoteDataSource {
  Future<void> register(
    DriverRegistration registration,
  );
}