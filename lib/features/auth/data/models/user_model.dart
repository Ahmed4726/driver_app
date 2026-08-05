import 'driver_model.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final DriverModel? driver;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.driver,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone']?.toString() ?? '',
      role: json['role'],
      status: json['status'],
      driver: json['driver'] != null
          ? DriverModel.fromJson(json['driver'])
          : null,
    );
  }
}