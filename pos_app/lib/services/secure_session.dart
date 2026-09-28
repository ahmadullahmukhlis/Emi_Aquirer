import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSession {
  const SecureSession([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: 'access_token');
  Future<void> saveToken(String value) =>
      _storage.write(key: 'access_token', value: value);
  Future<void> clear() => _storage.delete(key: 'access_token');
}
