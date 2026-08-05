import 'package:dio/dio.dart';

import '../../../../core/api/dio_client.dart';
import '../models/vehicle_model.dart';
import '../models/vehicle_type_model.dart';

class VehicleRemoteDataSource {
  Future<List<VehicleTypeModel>> getVehicleTypes() async {
    final response = await DioClient.dio.get('/vehicle-types');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((item) => VehicleTypeModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<VehicleModel?> getCurrentVehicle() async {
    final response = await DioClient.dio.get('/vehicles/current');

    if (response.data['data'] == null) {
      return null;
    }

    return VehicleModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  FormData _buildFormData(Map<String, dynamic> payload) {
    final formData = FormData();

    payload.forEach((key, value) {
      if (value is List<MultipartFile>) {
        for (final file in value) {
          formData.files.add(MapEntry('${key}[]', file));
        }
      } else if (value is MultipartFile) {
        formData.files.add(MapEntry(key, value));
      } else {
        formData.fields.add(MapEntry(key, value?.toString() ?? ''));
      }
    });

    return formData;
  }

  Future<VehicleModel> registerVehicle(
    Map<String, dynamic> payload,
  ) async {
    final response = await DioClient.dio.post(
      '/vehicles',
      data: _buildFormData(payload),
    );

    return VehicleModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<VehicleModel> updateVehicle(
    int vehicleId,
    Map<String, dynamic> payload,
  ) async {
    final response = await DioClient.dio.post(
      '/vehicles/$vehicleId/resubmit',
      data: _buildFormData(payload),
    );

    return VehicleModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
