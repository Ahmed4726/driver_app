import '../datasource/city_remote_datasource.dart';
import 'city_repository.dart';

class CityRepositoryImpl implements CityRepository {
  final CityRemoteDataSource remote;

  CityRepositoryImpl(this.remote);

  @override
  Future<List<String>> getCities() async {
    final response = await remote.fetchCities();
    var data = response.data;

    if (data is Map && data['data'] is List) {
      data = data['data'];
    }

    if (data is! List) {
      throw Exception('Unexpected city response format');
    }

    return data
        .map((item) {
          if (item is Map) {
            return item['name']?.toString() ?? '';
          }
          return item.toString();
        })
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
