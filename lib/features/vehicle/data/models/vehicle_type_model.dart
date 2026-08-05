class VehicleTypeModel {
  final int id;
  final String name;

  VehicleTypeModel({
    required this.id,
    required this.name,
  });

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}
