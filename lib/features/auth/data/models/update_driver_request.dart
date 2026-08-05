import 'dart:io';

class UpdateDriverRequest {
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final DateTime? dateOfBirth;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? bloodGroup;
  final File? profilePhoto;
  final File? cnicFront;
  final File? cnicBack;
  final File? licenseFront;
  final File? licenseBack;
  final DateTime? cnicIssueDate;
  final DateTime? cnicExpiryDate;
  final DateTime? licenseIssueDate;
  final DateTime? licenseExpiryDate;

  UpdateDriverRequest({
    this.name,
    this.email,
    this.phone,
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
    this.cnicIssueDate,
    this.cnicExpiryDate,
    this.licenseIssueDate,
    this.licenseExpiryDate,
  });
}
