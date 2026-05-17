import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyRoleCode = 'role_code';

  static Future<void> saveToken(String token) => _storage.write(key: _keyToken, value: token);
  static Future<String?> getToken() => _storage.read(key: _keyToken);

  static Future<void> saveUserId(String id) => _storage.write(key: _keyUserId, value: id);
  static Future<String?> getUserId() => _storage.read(key: _keyUserId);

  static Future<void> saveRoleCode(String role) => _storage.write(key: _keyRoleCode, value: role);
  static Future<String?> getRoleCode() => _storage.read(key: _keyRoleCode);

  static Future<void> clearAll() => _storage.deleteAll();
}
