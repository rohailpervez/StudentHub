import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // ============================================================
  // STORAGE KEYS
  // ============================================================

  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  // ============================================================
  // TOKEN
  // ============================================================

  Future<void> saveToken(String token) async {
    await _secureStorage.write(
      key: _tokenKey,
      value: token,
    );
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(
      key: _tokenKey,
    );
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(
      key: _tokenKey,
    );
  }

  // ============================================================
  // USER DATA
  // ============================================================

  Future<void> saveUser(String userData) async {
    await _secureStorage.write(
      key: _userKey,
      value: userData,
    );
  }

  Future<String?> getUser() async {
    return await _secureStorage.read(
      key: _userKey,
    );
  }

  Future<void> deleteUser() async {
    await _secureStorage.delete(
      key: _userKey,
    );
  }
}
