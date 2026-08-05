import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  final Connectivity connectivity = Connectivity();

  Future<bool> isConnected() async {
    final result = await connectivity.checkConnectivity();

    return result != ConnectivityResult.none;
  }
}