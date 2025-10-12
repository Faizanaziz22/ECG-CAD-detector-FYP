import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Get the stored authentication token
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: 'auth_token');
    } catch (e) {
      print('Error reading auth token: $e');
      return null;
    }
  }

  /// Store the authentication token
  static Future<void> setToken(String token) async {
    try {
      await _storage.write(key: 'auth_token', value: token);
    } catch (e) {
      print('Error storing auth token: $e');
    }
  }

  /// Remove the stored authentication token
  static Future<void> removeToken() async {
    try {
      await _storage.delete(key: 'auth_token');
    } catch (e) {
      print('Error removing auth token: $e');
    }
  }

  /// Get the stored user data
  static Future<String?> getUserData() async {
    try {
      return await _storage.read(key: 'user_data');
    } catch (e) {
      print('Error reading user data: $e');
      return null;
    }
  }

  /// Store the user data
  static Future<void> setUserData(String userData) async {
    try {
      await _storage.write(key: 'user_data', value: userData);
    } catch (e) {
      print('Error storing user data: $e');
    }
  }

  /// Remove the stored user data
  static Future<void> removeUserData() async {
    try {
      await _storage.delete(key: 'user_data');
    } catch (e) {
      print('Error removing user data: $e');
    }
  }

  /// Clear all stored authentication data
  static Future<void> clearAll() async {
    await removeToken();
    await removeUserData();
  }
}