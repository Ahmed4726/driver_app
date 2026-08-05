import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/secure_storage_service.dart';

import '../models/driver_registration.dart';
import '../models/login_request.dart';
import '../models/update_driver_request.dart';

class AuthRemoteDataSource {
  Future<Response> login(LoginRequest request) {
    return DioClient.dio.post(
      '/auth/login',
      data: request.toJson(),
    );
  }

  Future<Response> register(
    DriverRegistration request,
  ) async {
    final formData = FormData.fromMap({
      // ==========================
      // Personal Information
      // ==========================

      'name': request.name,
      'email': request.email,
      'phone': request.phone,

      // ==========================
      // Authentication
      // ==========================

      'password': request.password,
      'password_confirmation': request.passwordConfirmation,

      // ==========================
      // Driver Information
      // ==========================

      'cnic': request.cnic,
      'license_number': request.licenseNumber,
      'license_expiry': request.licenseExpiry == null
          ? null
          : DateFormat('yyyy-MM-dd')
              .format(request.licenseExpiry!),

      // ==========================
      // Additional Information
      // ==========================

      'address': request.address,
      'city': request.city,

      'date_of_birth': request.dateOfBirth == null
          ? null
          : DateFormat('yyyy-MM-dd')
              .format(request.dateOfBirth!),

      'emergency_contact_name':
          request.emergencyContactName,

      'emergency_contact_phone':
          request.emergencyContactPhone,

      'blood_group': request.bloodGroup,

      // ==========================
      // Documents
      // ==========================

      if (request.profilePhoto != null)
        'profile_photo': await MultipartFile.fromFile(
          request.profilePhoto!.path,
          filename: 'profile.jpg',
        ),

      if (request.cnicFront != null)
        'cnic_front': await MultipartFile.fromFile(
          request.cnicFront!.path,
          filename: 'cnic_front.jpg',
        ),

      if (request.cnicBack != null)
        'cnic_back': await MultipartFile.fromFile(
          request.cnicBack!.path,
          filename: 'cnic_back.jpg',
        ),

      if (request.licenseFront != null)
        'license_front': await MultipartFile.fromFile(
          request.licenseFront!.path,
          filename: 'license_front.jpg',
        ),

      if (request.licenseBack != null)
        'license_back': await MultipartFile.fromFile(
          request.licenseBack!.path,
          filename: 'license_back.jpg',
        ),
    });

    return DioClient.dio.post(
      '/auth/register/driver',
      data: formData,
    );
  }

  Future<Response> profile() {
    return DioClient.dio.get('/profile');
  }

  Future<Response> updateAvailability(bool isAvailable) {
    return DioClient.dio.post(
      '/profile/availability',
      data: {
        'is_available': isAvailable,
      },
    );
  }

  Future<Response> updateDriverProfile(
    UpdateDriverRequest request,
  ) async {
    final token = await sl<SecureStorageService>().getToken();
    final formData = FormData.fromMap({
      if (request.address != null) 'address': request.address,
      if (request.city != null) 'city': request.city,
      if (request.dateOfBirth != null)
        'date_of_birth': request.dateOfBirth!.toIso8601String(),
      if (request.emergencyContactName != null)
        'emergency_contact_name': request.emergencyContactName,
      if (request.emergencyContactPhone != null)
        'emergency_contact_phone': request.emergencyContactPhone,
      if (request.bloodGroup != null) 'blood_group': request.bloodGroup,
      if (request.profilePhoto != null)
        'profile_photo': await MultipartFile.fromFile(
          request.profilePhoto!.path,
          filename: 'profile_photo.jpg',
        ),
      if (request.cnicIssueDate != null)
        'cnic_issue_date': DateFormat('yyyy-MM-dd').format(request.cnicIssueDate!),
      if (request.cnicExpiryDate != null)
        'cnic_expiry_date': DateFormat('yyyy-MM-dd').format(request.cnicExpiryDate!),
      if (request.licenseIssueDate != null)
        'license_issue_date': DateFormat('yyyy-MM-dd').format(request.licenseIssueDate!),
      if (request.licenseExpiryDate != null)
        'license_expiry_date': DateFormat('yyyy-MM-dd').format(request.licenseExpiryDate!),
      if (request.cnicFront != null)
        'cnic_front': await MultipartFile.fromFile(
          request.cnicFront!.path,
          filename: 'cnic_front.jpg',
        ),
      if (request.cnicBack != null)
        'cnic_back': await MultipartFile.fromFile(
          request.cnicBack!.path,
          filename: 'cnic_back.jpg',
        ),
      if (request.licenseFront != null)
        'license_front': await MultipartFile.fromFile(
          request.licenseFront!.path,
          filename: 'license_front.jpg',
        ),
      if (request.licenseBack != null)
        'license_back': await MultipartFile.fromFile(
          request.licenseBack!.path,
          filename: 'license_back.jpg',
        ),
    });

    return DioClient.dio.post(
      '/application/resubmit',
      data: formData,
      options: Options(
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<Response> updateProfile(
    UpdateDriverRequest request,
  ) async {
    final token = await sl<SecureStorageService>().getToken();
    final formData = FormData.fromMap({
      if (request.address != null) 'address': request.address,
      if (request.city != null) 'city': request.city,
      if (request.dateOfBirth != null)
        'date_of_birth': request.dateOfBirth!.toIso8601String(),
      if (request.emergencyContactName != null)
        'emergency_contact_name': request.emergencyContactName,
      if (request.emergencyContactPhone != null)
        'emergency_contact_phone': request.emergencyContactPhone,
      if (request.bloodGroup != null) 'blood_group': request.bloodGroup,
      if (request.profilePhoto != null)
        'profile_photo': await MultipartFile.fromFile(
          request.profilePhoto!.path,
          filename: 'profile_photo.jpg',
        ),
      if (request.cnicIssueDate != null)
        'cnic_issue_date': DateFormat('yyyy-MM-dd').format(request.cnicIssueDate!),
      if (request.cnicExpiryDate != null)
        'cnic_expiry_date': DateFormat('yyyy-MM-dd').format(request.cnicExpiryDate!),
      if (request.licenseIssueDate != null)
        'license_issue_date': DateFormat('yyyy-MM-dd').format(request.licenseIssueDate!),
      if (request.licenseExpiryDate != null)
        'license_expiry_date': DateFormat('yyyy-MM-dd').format(request.licenseExpiryDate!),
      if (request.cnicFront != null)
        'cnic_front': await MultipartFile.fromFile(
          request.cnicFront!.path,
          filename: 'cnic_front.jpg',
        ),
      if (request.cnicBack != null)
        'cnic_back': await MultipartFile.fromFile(
          request.cnicBack!.path,
          filename: 'cnic_back.jpg',
        ),
      if (request.licenseFront != null)
        'license_front': await MultipartFile.fromFile(
          request.licenseFront!.path,
          filename: 'license_front.jpg',
        ),
      if (request.licenseBack != null)
        'license_back': await MultipartFile.fromFile(
          request.licenseBack!.path,
          filename: 'license_back.jpg',
        ),
    });

    return DioClient.dio.post(
      '/profile/personal-update',
      data: formData,
      options: Options(
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<Response> logout() {
    return DioClient.dio.post('/logout');
  }
}