import '../../../../core/di/service_locator.dart';
import '../../../../core/repositories/base_repository.dart';
import '../../../../core/services/secure_storage_service.dart';

import '../datasource/auth_remote_datasource.dart';
import '../models/driver_registration.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/update_driver_request.dart';
import '../models/user_model.dart';

class AuthRepository extends BaseRepository {
  final AuthRemoteDataSource remote;

  AuthRepository(this.remote);

  /// ==========================
  /// Driver Registration
  /// ==========================
  Future<void> register(
    DriverRegistration registration,
  ) {
    return execute(() async {
      await remote.register(registration);
    });
  }

  /// ==========================
  /// Login
  /// ==========================
  Future<LoginResponse> login(
    LoginRequest request,
  ) {
    return execute(() async {
      final response = await remote.login(request);

      final login = LoginResponse.fromJson(
        response.data,
      );

      await sl<SecureStorageService>().saveToken(
        login.token,
      );

      return login;
    });
  }

  /// ==========================
  /// Current User
  /// ==========================
  Future<UserModel> profile() {
    return execute(() async {
      final response = await remote.profile();

      return UserModel.fromJson(
        response.data['data'],
      );
    });
  }

  /// ==========================
  /// Logout
  /// ==========================
  Future<void> logout() {
    return execute(() async {
      try {
        await remote.logout();
      } finally {
        await sl<SecureStorageService>().clear();
      }
    });
  }

  /// ==========================
  /// Update rejected driver profile
  /// ==========================
  Future<UserModel> updateDriverProfile(
    UpdateDriverRequest request,
  ) {
    return execute(() async {
      final response = await remote.updateDriverProfile(request);

      return UserModel.fromJson(
        response.data['data'],
      );
    });
  }

  /// ==========================
  /// Update general driver profile
  /// ==========================
  Future<UserModel> updateProfile(
    UpdateDriverRequest request,
  ) {
    return execute(() async {
      final response = await remote.updateProfile(request);

      return UserModel.fromJson(
        response.data['data'],
      );
    });
  }

  Future<UserModel> updateAvailability(bool isAvailable) {
    return execute(() async {
      final response = await remote.updateAvailability(isAvailable);

      return UserModel.fromJson(
        response.data['data'],
      );
    });
  }

  /// ==========================
  /// Check Login
  /// ==========================
  Future<bool> isLoggedIn() async {
    final token =
        await sl<SecureStorageService>().getToken();

    return token != null && token.isNotEmpty;
  }
}