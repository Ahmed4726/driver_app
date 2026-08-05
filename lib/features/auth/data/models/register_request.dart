import 'dart:io';

class RegisterRequest {
  final String name;

  final String email;

  final String phone;

  final String password;

  final String passwordConfirmation;

  final String cnic;

  final String licenseNumber;

  final DateTime licenseExpiry;

  final File? profilePhoto;

  final File? cnicFront;

  final File? cnicBack;

  final File? licenseFront;

  final File? licenseBack;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
    required this.cnic,
    required this.licenseNumber,
    required this.licenseExpiry,
    this.profilePhoto,
    this.cnicFront,
    this.cnicBack,
    this.licenseFront,
    this.licenseBack,
  });
}