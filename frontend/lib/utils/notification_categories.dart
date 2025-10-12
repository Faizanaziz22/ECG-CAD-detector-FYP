import 'package:flutter/material.dart';

enum NotificationCategory {
  urgent,
  medical,
  appointment,
  reminder,
  system,
  info,
  success,
  warning,
  error,
}

class NotificationCategoryHelper {
  static const Map<NotificationCategory, String> _categoryNames = {
    NotificationCategory.urgent: 'Urgent',
    NotificationCategory.medical: 'Medical',
    NotificationCategory.appointment: 'Appointments',
    NotificationCategory.reminder: 'Reminders',
    NotificationCategory.system: 'System',
    NotificationCategory.info: 'Information',
    NotificationCategory.success: 'Success',
    NotificationCategory.warning: 'Warning',
    NotificationCategory.error: 'Error',
  };

  static const Map<NotificationCategory, IconData> _categoryIcons = {
    NotificationCategory.urgent: Icons.priority_high,
    NotificationCategory.medical: Icons.medical_services,
    NotificationCategory.appointment: Icons.calendar_today,
    NotificationCategory.reminder: Icons.alarm,
    NotificationCategory.system: Icons.settings,
    NotificationCategory.info: Icons.info,
    NotificationCategory.success: Icons.check_circle,
    NotificationCategory.warning: Icons.warning,
    NotificationCategory.error: Icons.error,
  };

  static const Map<NotificationCategory, Color> _categoryColors = {
    NotificationCategory.urgent: Colors.red,
    NotificationCategory.medical: Colors.blue,
    NotificationCategory.appointment: Colors.green,
    NotificationCategory.reminder: Colors.orange,
    NotificationCategory.system: Colors.grey,
    NotificationCategory.info: Colors.lightBlue,
    NotificationCategory.success: Colors.green,
    NotificationCategory.warning: Colors.amber,
    NotificationCategory.error: Colors.red,
  };

  // Get category from notification type string
  static NotificationCategory getCategoryFromType(String type) {
    switch (type.toLowerCase()) {
      case 'urgent':
      case 'critical':
        return NotificationCategory.urgent;
      case 'medical':
      case 'ecg':
      case 'diagnosis':
        return NotificationCategory.medical;
      case 'appointment':
      case 'schedule':
        return NotificationCategory.appointment;
      case 'reminder':
        return NotificationCategory.reminder;
      case 'system':
        return NotificationCategory.system;
      case 'success':
        return NotificationCategory.success;
      case 'warning':
        return NotificationCategory.warning;
      case 'error':
        return NotificationCategory.error;
      default:
        return NotificationCategory.info;
    }
  }

  // Get category name
  static String getCategoryName(NotificationCategory category) {
    return _categoryNames[category] ?? 'Unknown';
  }

  // Get category icon
  static IconData getCategoryIcon(NotificationCategory category) {
    return _categoryIcons[category] ?? Icons.notifications;
  }

  // Get category color
  static Color getCategoryColor(NotificationCategory category) {
    return _categoryColors[category] ?? Colors.grey;
  }

  // Get all categories
  static List<NotificationCategory> getAllCategories() {
    return NotificationCategory.values;
  }

  // Get category display name for filters
  static String getCategoryDisplayName(NotificationCategory category) {
    return getCategoryName(category);
  }

  // Check if category should show badge
  static bool shouldShowBadge(NotificationCategory category) {
    return category == NotificationCategory.urgent || 
           category == NotificationCategory.medical ||
           category == NotificationCategory.error;
  }
}