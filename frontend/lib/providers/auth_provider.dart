import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Getters
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null && _token != null;

  // Initialize auth state from storage
  Future<void> initializeAuth() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final userJson = await _storage.read(key: 'user_data');

      if (token != null && userJson != null) {
        _token = token;
        _user = User.fromJsonString(userJson);
        notifyListeners();
      }
    } catch (e) {
      print('Error initializing auth: $e');
    }
  }

  // Signup method
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    int? age,
    String? specialization,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.signup(
        name: name,
        email: email,
        password: password,
        role: role,
        age: age,
        specialization: specialization,
      );

      if (result['success']) {
        _setError(null);
        _setLoading(false);
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Signup failed: $e');
      _setLoading(false);
      return false;
    }
  }

  // Login method
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.login(
        email: email,
        password: password,
      );

      if (result['success']) {
        final data = result['data'];
        _token = data['token'];
        _user = User.fromJson(data['user']);

        // Store in secure storage
        await _storage.write(key: 'auth_token', value: _token);
        await _storage.write(key: 'user_data', value: _user!.toJsonString());

        _setError(null);
        _setLoading(false);
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      _setLoading(false);
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    _user = null;
    _token = null;
    _errorMessage = null;

    // Clear secure storage
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_data');

    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}