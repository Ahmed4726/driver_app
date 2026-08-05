import '../../data/datasource/vehicle_remote_datasource.dart';
import '../models/vehicle_model.dart';
import '../models/vehicle_type_model.dart';
import 'vehicle_repository.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleRemoteDataSource remote;

  VehicleRepositoryImpl(this.remote);

  @override
  Future<List<VehicleTypeModel>> getVehicleTypes() {
    return remote.getVehicleTypes();
  }

  @override
  Future<VehicleModel?> getCurrentVehicle() {
    return remote.getCurrentVehicle();
  }

  @override
  Future<VehicleModel> registerVehicle(Map<String, dynamic> payload) {
    return remote.registerVehicle(payload);
  }

  @override
  Future<VehicleModel> updateVehicle(int vehicleId, Map<String, dynamic> payload) {
    return remote.updateVehicle(vehicleId, payload);
  }
}
