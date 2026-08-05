import '../models/vehicle_model.dart';
import '../models/vehicle_type_model.dart';

abstract class VehicleRepository {
  Future<List<VehicleTypeModel>> getVehicleTypes();
  Future<VehicleModel?> getCurrentVehicle();
  Future<VehicleModel> registerVehicle(Map<String, dynamic> payload);
  Future<VehicleModel> updateVehicle(int vehicleId, Map<String, dynamic> payload);
}
