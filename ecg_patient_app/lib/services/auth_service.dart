import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  
  AuthService._();
  
  final ApiService _apiService = ApiService.instance;
  
  // Current user data
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentUser => _currentUser;
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _apiService.getAuthToken();
    return token != null;
  }
  
  // Register new user
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      final response = await _apiService.post('/auth/register', body: {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (gender != null) 'gender': gender,
      });
      
      if (response.success && response.data != null) {
        final userData = response.data['user'];
        final tokens = response.data['tokens'];
        
        // Store tokens
        await _apiService.setAuthToken(tokens['accessToken']);
        await _apiService.setRefreshToken(tokens['refreshToken']);
        
        // Store user data
        _currentUser = userData;
        await _storeUserData(userData);
        
        return AuthResult(
          success: true,
          message: response.message,
          user: userData,
        );
      }
      
      return AuthResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }
  
  // Login user
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post('/auth/login', body: {
        'email': email,
        'password': password,
      });
      
      if (response.success && response.data != null) {
        final userData = response.data['user'];
        final tokens = response.data['tokens'];
        
        // Store tokens
        await _apiService.setAuthToken(tokens['accessToken']);
        await _apiService.setRefreshToken(tokens['refreshToken']);
        
        // Store user data
        _currentUser = userData;
        await _storeUserData(userData);
        
        return AuthResult(
          success: true,
          message: response.message,
          user: userData,
        );
      }
      
      return AuthResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }
  
  // Logout user
  Future<AuthResult> logout() async {
    try {
      final refreshToken = await _apiService.getRefreshToken();
      
      // Call logout API
      await _apiService.post('/auth/logout', body: {
        if (refreshToken != null) 'refreshToken': refreshToken,
      });
      
      // Clear local data
      await _clearUserData();
      
      return AuthResult(
        success: true,
        message: 'Logged out successfully',
      );
    } catch (e) {
      // Clear local data even if API call fails
      await _clearUserData();
      
      return AuthResult(
        success: true,
        message: 'Logged out successfully',
      );
    }
  }
  
  // Get current user profile
  Future<AuthResult> getProfile() async {
    try {
      final response = await _apiService.get('/auth/profile');
      
      if (response.success && response.data != null) {
        final userData = response.data['user'];
        
        // Update stored user data
        _currentUser = userData;
        await _storeUserData(userData);
        
        return AuthResult(
          success: true,
          message: 'Profile loaded successfully',
          user: userData,
        );
      }
      
      return AuthResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to load profile: ${e.toString()}',
      );
    }
  }
  
  // Update user profile
  Future<AuthResult> updateProfile({
    String? name,
    String? phone,
    String? dateOfBirth,
    String? gender,
    Map<String, dynamic>? emergencyContact,
    Map<String, dynamic>? medicalHistory,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
      if (gender != null) body['gender'] = gender;
      if (emergencyContact != null) body['emergencyContact'] = emergencyContact;
      if (medicalHistory != null) body['medicalHistory'] = medicalHistory;
      if (settings != null) body['settings'] = settings;
      
      final response = await _apiService.put('/auth/profile', body: body);
      
      if (response.success && response.data != null) {
        final userData = response.data['user'];
        
        // Update stored user data
        _currentUser = userData;
        await _storeUserData(userData);
        
        return AuthResult(
          success: true,
          message: response.message,
          user: userData,
        );
      }
      
      return AuthResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Profile update failed: ${e.toString()}',
      );
    }
  }
  
  // Change password
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.put('/auth/change-password', body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      
      return AuthResult(
        success: response.success,
        message: response.message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Password change failed: ${e.toString()}',
      );
    }
  }
  
  // Request password reset
  Future<AuthResult> requestPasswordReset({
    required String email,
  }) async {
    try {
      final response = await _apiService.post('/auth/forgot-password', body: {
        'email': email,
      });
      
      return AuthResult(
        success: response.success,
        message: response.message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Password reset request failed: ${e.toString()}',
      );
    }
  }
  
  // Reset password with token
  Future<AuthResult> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post('/auth/reset-password', body: {
        'token': token,
        'newPassword': newPassword,
      });
      
      return AuthResult(
        success: response.success,
        message: response.message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Password reset failed: ${e.toString()}',
      );
    }
  }
  
  // Verify email
  Future<AuthResult> verifyEmail({
    required String verificationCode,
  }) async {
    try {
      final response = await _apiService.post('/auth/verify-email', body: {
        'verificationCode': verificationCode,
      });
      
      if (response.success) {
        // Update user data to reflect email verification
        if (_currentUser != null) {
          _currentUser!['isEmailVerified'] = true;
          await _storeUserData(_currentUser!);
        }
      }
      
      return AuthResult(
        success: response.success,
        message: response.message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Email verification failed: ${e.toString()}',
      );
    }
  }
  
  // Load user data from local storage
  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        _currentUser = json.decode(userDataString);
      }
    } catch (e) {
        // Log error loading user data
        debugPrint('Error loading user data: $e');
    }
  }
  
  // Store user data locally
  Future<void> _storeUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(userData));
    } catch (e) {
        // Log error storing user data
        debugPrint('Error storing user data: $e');
    }
  }
  
  // Clear all user data
  Future<void> _clearUserData() async {
    try {
      _currentUser = null;
      await _apiService.clearTokens();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
        // Log error clearing user data
        debugPrint('Error clearing user data: $e');
    }
  }
  
  // Initialize auth service
  Future<void> initialize() async {
    await loadUserData();
    
    // Check if token is still valid by trying to get profile
    if (await isLoggedIn()) {
      final result = await getProfile();
      if (!result.success) {
        // Token is invalid, clear data
        await _clearUserData();
      }
    }
  }
}

class AuthResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? user;
  
  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
  
  @override
  String toString() {
    return 'AuthResult(success: $success, message: $message)';
  }
}