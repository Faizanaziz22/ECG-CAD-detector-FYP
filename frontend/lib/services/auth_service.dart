import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Update base URL to use the test server
  static const String baseUrl = 'http://localhost:5001/api';
  
  // You can change this to your actual backend URL
  // For Android emulator: http://10.0.2.2:3000/api
  // For iOS simulator: http://localhost:3000/api
  // For physical device: http://YOUR_COMPUTER_IP:3000/api

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    int? age,
    String? specialization,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      };

      // Add age for patients
      if (role == 'patient' && age != null) {
        requestBody['age'] = age;
      }

      // Add specialization for doctors
      if (role == 'doctor' && specialization != null) {
        requestBody['specialization'] = specialization;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Signup failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPatientDashboard(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/patient/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch dashboard'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDoctorDashboard(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/doctor/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch dashboard'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}