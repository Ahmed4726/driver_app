class DriverModel {
  final int id;
  final String cnic;
  final String licenseNumber;
  final String? licenseExpiry;
  final String? address;
  final String? city;
  final String? dateOfBirth;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? bloodGroup;
  final bool isAvailable;
  final String? remarks;
  final List<String>? rejectionIssues;
  final String? profilePhoto;
  final String? cnicFront;
  final String? cnicBack;
  final String? licenseFront;
  final String? licenseBack;

  DriverModel({
    required this.id,
    required this.cnic,
    required this.licenseNumber,
    this.licenseExpiry,
    this.address,
    this.city,
    this.dateOfBirth,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.bloodGroup,
    required this.isAvailable,
    this.remarks,
    this.rejectionIssues,
    this.profilePhoto,
    this.cnicFront,
    this.cnicBack,
    this.licenseFront,
    this.licenseBack,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'],
      cnic: json['cnic'] ?? '',
      licenseNumber: json['license_number'] ?? '',
      licenseExpiry: json['license_expiry']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      emergencyContactName: json['emergency_contact_name']?.toString(),
      emergencyContactPhone: json['emergency_contact_phone']?.toString(),
      bloodGroup: json['blood_group']?.toString(),
      isAvailable: json['is_available'] == null
          ? false
          : json['is_available'] is bool
              ? json['is_available']
              : json['is_available'].toString().toLowerCase() == 'true',
      remarks: json['remarks']?.toString(),
      rejectionIssues: json['rejection_issues'] != null
          ? List<String>.from(json['rejection_issues'])
          : null,
      profilePhoto: json['profile_photo']?.toString(),
      cnicFront: json['cnic_front']?.toString(),
      cnicBack: json['cnic_back']?.toString(),
      licenseFront: json['license_front']?.toString(),
      licenseBack: json['license_back']?.toString(),
    );
  }
}
