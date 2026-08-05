import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const String tokenKey = 'access_token';

  Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: tokenKey);
  }

  Future<void> removeToken() async {
    await _storage.delete(key: tokenKey);
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}