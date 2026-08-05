import '../../data/models/driver_registration.dart';

abstract class RegisterRepository {
  Future<void> register(
    DriverRegistration registration,
  );
}