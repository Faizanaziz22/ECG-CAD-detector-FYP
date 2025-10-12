import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class ECGService {
  static const String baseUrl = 'http://192.168.100.5:5001/api/ecg';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Get authorization headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get headers for file upload
  static Future<Map<String, String>> _getFileHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Authorization': 'Bearer $token',
    };
  }

  // Upload ECG file
  static Future<Map<String, dynamic>> uploadECGFile(Uint8List fileBytes, String fileName, {String? notes}) async {
    try {
      final headers = await _getFileHeaders();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      
      request.headers.addAll(headers);
      request.files.add(http.MultipartFile.fromBytes('ecgFile', fileBytes, filename: fileName));
      
      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      }
      request.fields['recordingType'] = 'upload';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Upload failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Record ECG (simulate)
  static Future<Map<String, dynamic>> recordECG({int duration = 30, String? notes}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/record'),
        headers: headers,
        body: json.encode({
          'duration': duration,
          'notes': notes ?? '',
        }),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Recording failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Get ECG history
  static Future<Map<String, dynamic>> getECGHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to fetch history',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Get detailed ECG report
  static Future<Map<String, dynamic>> getECGReport(int recordId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/report/$recordId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to fetch report',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Request doctor review
  static Future<Map<String, dynamic>> requestDoctorReview(int recordId, {String? message}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/request-review'),
        headers: headers,
        body: json.encode({
          'recordId': recordId,
          'message': message ?? '',
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to request review',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Get pending reviews (for doctors)
  static Future<Map<String, dynamic>> getPendingReviews() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/pending-reviews'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to fetch pending reviews',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Submit doctor review
  static Future<Map<String, dynamic>> submitDoctorReview({
    required int recordId,
    required String diagnosis,
    String? recommendations,
    String severity = 'normal',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/submit-review'),
        headers: headers,
        body: json.encode({
          'recordId': recordId,
          'diagnosis': diagnosis,
          'recommendations': recommendations ?? '',
          'severity': severity,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to submit review',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Generate PDF report
  static Future<Map<String, dynamic>> generatePDFReport(String recordId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$baseUrl/report/$recordId/pdf'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to generate PDF report: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating PDF report: $e');
    }
  }

  // Download PDF report
  static Future<List<int>> downloadPDFReport(String fileName) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/download/$fileName'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download PDF report: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error downloading PDF report: $e');
    }
  }
}