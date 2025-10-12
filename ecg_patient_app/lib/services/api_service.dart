import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();

  ApiService._();

  // Get stored auth token
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Store auth token
  Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Get stored refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Store refresh token
  Future<void> setRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  // Clear all tokens
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Handle API response
  ApiResponse _handleResponse(http.Response response) {
    final Map<String, dynamic> data = json.decode(response.body);

    return ApiResponse(
      success: data['success'] ?? false,
      message: data['message'] ?? '',
      data: data['data'],
      statusCode: response.statusCode,
    );
  }

  // Handle API errors
  ApiResponse _handleError(dynamic error) {
    String message = 'Network error occurred';

    if (error is SocketException) {
      message = 'No internet connection';
    } else if (error is http.ClientException) {
      message = 'Connection failed';
    } else if (error is FormatException) {
      message = 'Invalid response format';
    }

    return ApiResponse(
      success: false,
      message: message,
      statusCode: 0,
    );
  }

  // Refresh access token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: await _getHeaders(includeAuth: false),
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data']['accessToken'] != null) {
          await setAuthToken(data['data']['accessToken']);
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Generic GET request
  Future<ApiResponse> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    try {
      Uri uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      // Handle token expiration
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          final retryResponse = await http.get(
            uri,
            headers: await _getHeaders(),
          );
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Generic POST request
  Future<ApiResponse> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: body != null ? json.encode(body) : null,
      );

      // Handle token expiration
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          final retryResponse = await http.post(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _getHeaders(),
            body: body != null ? json.encode(body) : null,
          );
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Generic PUT request
  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: body != null ? json.encode(body) : null,
      );

      // Handle token expiration
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          final retryResponse = await http.put(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _getHeaders(),
            body: body != null ? json.encode(body) : null,
          );
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Generic DELETE request
  Future<ApiResponse> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );

      // Handle token expiration
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          final retryResponse = await http.delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _getHeaders(),
          );
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Upload file with multipart request
  Future<ApiResponse> uploadFile(
    String endpoint,
    File file, {
    String fieldName = 'file',
    Map<String, String>? additionalFields,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );

      // Add headers
      final headers = await _getHeaders();
      headers.remove('Content-Type'); // Let http package set this for multipart
      request.headers.addAll(headers);

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, file.path),
      );

      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Handle token expiration
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          final retryRequest = http.MultipartRequest(
            'POST',
            Uri.parse('$baseUrl$endpoint'),
          );

          final newHeaders = await _getHeaders();
          newHeaders.remove('Content-Type');
          retryRequest.headers.addAll(newHeaders);

          retryRequest.files.add(
            await http.MultipartFile.fromPath(fieldName, file.path),
          );

          if (additionalFields != null) {
            retryRequest.fields.addAll(additionalFields);
          }

          final retryStreamedResponse = await retryRequest.send();
          final retryResponse =
              await http.Response.fromStream(retryStreamedResponse);
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Upload file from bytes with multipart request
  Future<ApiResponse> uploadFileFromBytes(
    String endpoint, {
    required Uint8List bytes,
    required String fileName,
    String fieldName = 'file',
    Map<String, String>? additionalFields,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );
      
      // Add headers
      final headers = await _getHeaders();
      headers.remove('Content-Type'); // Let http package set this for multipart
      request.headers.addAll(headers);
      
      // Add file from bytes
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: fileName,
        ),
      );
      
      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Handle token expiration
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          final retryRequest = http.MultipartRequest(
            'POST',
            Uri.parse('$baseUrl$endpoint'),
          );
          
          final newHeaders = await _getHeaders();
          newHeaders.remove('Content-Type');
          retryRequest.headers.addAll(newHeaders);
          
          retryRequest.files.add(
            http.MultipartFile.fromBytes(
              fieldName,
              bytes,
              filename: fileName,
            ),
          );
          
          if (additionalFields != null) {
            retryRequest.fields.addAll(additionalFields);
          }
          
          final retryStreamedResponse = await retryRequest.send();
          final retryResponse = await http.Response.fromStream(retryStreamedResponse);
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }
}

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, statusCode: $statusCode)';
  }
}
