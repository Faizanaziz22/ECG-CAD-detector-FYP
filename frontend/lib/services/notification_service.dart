import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification.dart';
import '../utils/auth_storage.dart';
import '../config/api_config.dart';

class NotificationService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all notifications for the current user
  static Future<Map<String, dynamic>> getNotifications({bool includeRead = true}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl?includeRead=$includeRead'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final notifications = (data['notifications'] as List)
            .map((json) => Notification.fromJson(json))
            .toList();
        
        return {
          'success': true,
          'notifications': notifications,
          'unreadCount': data['unreadCount'] ?? 0,
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to fetch notifications',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get unread notification count
  static Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/unread-count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'unreadCount': data['unreadCount'] ?? 0,
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to fetch unread count',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Mark a notification as read
  static Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/$notificationId/read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Notification marked as read',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to mark notification as read',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Mark all notifications as read
  static Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/mark-all-read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'All notifications marked as read',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to mark all notifications as read',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Delete a notification
  static Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$notificationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Notification deleted',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to delete notification',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Create a test notification (for development/testing)
  static Future<Map<String, dynamic>> createTestNotification({
    required String title,
    required String message,
    String type = 'system_alert',
    Map<String, dynamic>? data,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/test'),
        headers: headers,
        body: json.encode({
          'type': type,
          'title': title,
          'message': message,
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'notification': Notification.fromJson(responseData['notification']),
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to create test notification',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}