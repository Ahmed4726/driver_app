import 'dart:io';

class DriverRegistration {
  // ===========================
  // Personal Information
  // ===========================

  String? name;
  String? email;
  String? phone;

  // ===========================
  // Authentication
  // ===========================

  String? password;
  String? passwordConfirmation;

  // ===========================
  // Driver Information
  // ===========================

  String? cnic;
  String? licenseNumber;
  DateTime? licenseExpiry;

  // ===========================
  // Additional Information
  // ===========================

  String? address;
  String? city;
  DateTime? dateOfBirth;

  String? emergencyContactName;
  String? emergencyContactPhone;

  String? bloodGroup;

  // ===========================
  // Documents
  // ===========================

  File? profilePhoto;
  File? cnicFront;
  File? cnicBack;
  File? licenseFront;
  File? licenseBack;

  DriverRegistration({
    this.name,
    this.email,
    this.phone,
    this.password,
    this.passwordConfirmation,
    this.cnic,
    this.licenseNumber,
    this.licenseExpiry,
    this.address,
    this.city,
    this.dateOfBirth,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.bloodGroup,
    this.profilePhoto,
    this.cnicFront,
    this.cnicBack,
    this.licenseFront,
    this.licenseBack,
  });

  DriverRegistration copyWith({
    String? name,
    String? email,
    String? phone,
    String? password,
    String? passwordConfirmation,
    String? cnic,
    String? licenseNumber,
    DateTime? licenseExpiry,
    String? address,
    String? city,
    DateTime? dateOfBirth,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    File? profilePhoto,
    File? cnicFront,
    File? cnicBack,
    File? licenseFront,
    File? licenseBack,
  }) {
    return DriverRegistration(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      passwordConfirmation:
          passwordConfirmation ?? this.passwordConfirmation,
      cnic: cnic ?? this.cnic,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      address: address ?? this.address,
      city: city ?? this.city,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      emergencyContactName:
          emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      cnicFront: cnicFront ?? this.cnicFront,
      cnicBack: cnicBack ?? this.cnicBack,
      licenseFront: licenseFront ?? this.licenseFront,
      licenseBack: licenseBack ?? this.licenseBack,
    );
  }

  /// Required fields before submitting registration
  bool get isComplete =>
      name != null &&
      name!.trim().isNotEmpty &&
      email != null &&
      email!.trim().isNotEmpty &&
      phone != null &&
      phone!.trim().isNotEmpty &&
      password != null &&
      password!.isNotEmpty &&
      passwordConfirmation != null &&
      passwordConfirmation!.isNotEmpty &&
      cnic != null &&
      cnic!.trim().isNotEmpty &&
      licenseNumber != null &&
      licenseNumber!.trim().isNotEmpty &&
      licenseExpiry != null &&
      profilePhoto != null &&
      cnicFront != null &&
      cnicBack != null &&
      licenseFront != null &&
      licenseBack != null;

  @override
  String toString() {
    return '''
DriverRegistration(
  name: $name,
  email: $email,
  phone: $phone,

  cnic: $cnic,
  licenseNumber: $licenseNumber,
  licenseExpiry: $licenseExpiry,

  address: $address,
  city: $city,
  dateOfBirth: $dateOfBirth,

  emergencyContactName: $emergencyContactName,
  emergencyContactPhone: $emergencyContactPhone,
  bloodGroup: $bloodGroup,

  profilePhoto: ${profilePhoto != null},
  cnicFront: ${cnicFront != null},
  cnicBack: ${cnicBack != null},
  licenseFront: ${licenseFront != null},
  licenseBack: ${licenseBack != null},
)
''';
  }
}