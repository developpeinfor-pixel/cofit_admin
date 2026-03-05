import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    try {
      await storage.write(key: 'jwt', value: token);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    try {
      return storage.read(key: 'jwt');
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await storage.delete(key: 'jwt');
    } catch (_) {}
  }

  Future<void> saveRole(String role) async {
    try {
      await storage.write(key: 'role', value: role);
    } catch (_) {}
  }

  Future<String?> getRole() async {
    try {
      return storage.read(key: 'role');
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    try {
      await storage.delete(key: 'jwt');
      await storage.delete(key: 'role');
    } catch (_) {}
  }
}
