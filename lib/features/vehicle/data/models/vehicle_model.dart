class VehicleModel {
  final int id;
  final int vehicleTypeId;
  final String vehicleType;
  final String brand;
  final String model;
  final int manufactureYear;
  final String color;
  final String registrationNumber;
  final String engineNumber;
  final String chassisNumber;
  final int totalSeats;
  final int availableSeats;
  final String? vehiclePhoto;
  final List<String>? vehiclePhotos;
  final String? registrationBook;
  final String? fitnessCertificate;
  final String? insuranceDocument;
  final List<String>? rejectionIssues;
  final String status;
  final String? remarks;

  VehicleModel({
    required this.id,
    required this.vehicleTypeId,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.manufactureYear,
    required this.color,
    required this.registrationNumber,
    required this.engineNumber,
    required this.chassisNumber,
    required this.totalSeats,
    required this.availableSeats,
    this.vehiclePhoto,
    this.vehiclePhotos,
    this.registrationBook,
    this.fitnessCertificate,
    this.insuranceDocument,
    this.rejectionIssues,
    required this.status,
    this.remarks,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    List<String>? parseStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((item) => item?.toString() ?? '').where((item) => item.isNotEmpty).toList();
      }
      return null;
    }

    return VehicleModel(
      id: parseInt(json['id']),
      vehicleTypeId: parseInt(json['vehicle_type_id']),
      vehicleType: json['vehicle_type']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      manufactureYear: parseInt(json['manufacture_year']),
      color: json['color']?.toString() ?? '',
      registrationNumber: json['registration_number']?.toString() ?? '',
      engineNumber: json['engine_number']?.toString() ?? '',
      chassisNumber: json['chassis_number']?.toString() ?? '',
      totalSeats: parseInt(json['total_seats']),
      availableSeats: parseInt(json['available_seats']),
      vehiclePhoto: json['vehicle_photo']?.toString(),
      vehiclePhotos: parseStringList(json['vehicle_photos']) ?? [],
      registrationBook: json['registration_book']?.toString(),
      fitnessCertificate: json['fitness_certificate']?.toString(),
      insuranceDocument: json['insurance_document']?.toString(),
      status: json['status']?.toString() ?? '',
      remarks: json['remarks']?.toString(),
      rejectionIssues: parseStringList(json['rejection_issues']) ?? [],
    );
  }
}
