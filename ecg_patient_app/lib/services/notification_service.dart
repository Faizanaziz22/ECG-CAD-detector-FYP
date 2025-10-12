import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Notification channels
  static const String _reportChannelId = 'ecg_reports';
  static const String _systemChannelId = 'system_updates';
  static const String _reminderChannelId = 'reminders';

  Future<void> initialize() async {
    if (_initialized) return;

    // Request notification permissions
    await _requestPermissions();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
    
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    // Request notification permission
    final status = await Permission.notification.request();
    
    if (status.isDenied) {
      // Log notification permission denied
      debugPrint('Notification permission denied');
    }
  }

  Future<void> _createNotificationChannels() async {
    // ECG Reports channel
    const AndroidNotificationChannel reportsChannel = AndroidNotificationChannel(
      _reportChannelId,
      'ECG Reports',
      description: 'Notifications for ECG analysis results',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // System Updates channel
    const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
      _systemChannelId,
      'System Updates',
      description: 'App updates and system notifications',
      importance: Importance.defaultImportance,
      enableVibration: false,
      playSound: false,
    );

    // Reminders channel
    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      _reminderChannelId,
      'Health Reminders',
      description: 'Health checkup and medication reminders',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reportsChannel);
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(systemChannel);
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Handle notification tap based on payload
      debugPrint('Notification tapped with payload: $payload');
      // In a real app, you would navigate to specific screens based on the payload
    }
  }

  // ECG Report Notifications
  Future<void> showECGAnalysisComplete({
    required String reportId,
    required String classification,
    required double confidence,
  }) async {
    if (!await _areNotificationsEnabled()) return;

    final id = _generateNotificationId();
    const title = '🫀 ECG Analysis Complete';
    final body = 'Your ECG shows: $classification (${(confidence * 100).toStringAsFixed(1)}% confidence)';
    
    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reportChannelId,
          'ECG Reports',
          channelDescription: 'ECG analysis results',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: _getNotificationColor(classification),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'ecg_report:$reportId',
    );

    await _saveNotificationHistory({
      'id': id,
      'type': 'ecg_analysis',
      'title': title,
      'body': body,
      'payload': 'ecg_report:$reportId',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> showAbnormalECGAlert({
    required String reportId,
    required String classification,
  }) async {
    if (!await _areNotificationsEnabled()) return;

    final id = _generateNotificationId();
    const title = '⚠️ Abnormal ECG Detected';
    final body = 'Abnormal pattern detected: $classification. Please consult your healthcare provider.';
    
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _reportChannelId,
          'ECG Reports',
          channelDescription: 'Important ECG alerts',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFF5722), // Red color for alerts
          ongoing: true,
          autoCancel: false,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: 'ecg_alert:$reportId',
    );

    await _saveNotificationHistory({
      'id': id,
      'type': 'ecg_alert',
      'title': title,
      'body': body,
      'payload': 'ecg_alert:$reportId',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // System Notifications
  Future<void> showAppUpdate({
    required String version,
    required String features,
  }) async {
    if (!await _areNotificationsEnabled()) return;

    final id = _generateNotificationId();
    const title = '🔄 App Update Available';
    final body = 'Version $version is available with new features: $features';
    
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _systemChannelId,
          'System Updates',
          channelDescription: 'App updates and announcements',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF9C27B0), // Purple color
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        ),
      ),
      payload: 'app_update:$version',
    );

    await _saveNotificationHistory({
      'id': id,
      'type': 'app_update',
      'title': title,
      'body': body,
      'payload': 'app_update:$version',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> showDataSyncComplete(int syncedItems) async {
    if (!await _areNotificationsEnabled()) return;

    final id = _generateNotificationId();
    const title = '☁️ Data Sync Complete';
    final body = 'Successfully synced $syncedItems items to the cloud.';
    
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _systemChannelId,
          'System Updates',
          channelDescription: 'Data synchronization status',
          importance: Importance.low,
          priority: Priority.low,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF607D8B), // Blue grey color
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        ),
      ),
      payload: 'sync_complete:$syncedItems',
    );

    await _saveNotificationHistory({
      'id': id,
      'type': 'sync_complete',
      'title': title,
      'body': body,
      'payload': 'sync_complete:$syncedItems',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Health Reminders
  Future<void> scheduleHealthCheckupReminder({
    required DateTime scheduledDate,
    required String reminderText,
  }) async {
    if (!await _areNotificationsEnabled()) return;

    final id = _generateNotificationId();
    const title = '🏥 Health Checkup Reminder';
    final body = reminderText;
    
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          'Health Reminders',
          channelDescription: 'Health and medication reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFF9800), // Orange color
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'health_reminder:${scheduledDate.toIso8601String()}',
    );

    await _saveNotificationHistory({
      'id': id,
      'type': 'health_reminder',
      'title': title,
      'body': body,
      'payload': 'health_reminder:${scheduledDate.toIso8601String()}',
      'timestamp': DateTime.now().toIso8601String(),
      'scheduled_for': scheduledDate.toIso8601String(),
    });
  }

  Future<void> showMedicationReminder({
    required String medicationName,
    required String dosage,
  }) async {
    if (!await _areNotificationsEnabled()) return;

    final id = _generateNotificationId();
    const title = '💊 Medication Reminder';
    final body = 'Time to take your $medicationName ($dosage)';
    
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          'Health Reminders',
          channelDescription: 'Medication reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF4CAF50), // Green color
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'medication:$medicationName',
    );

    await _saveNotificationHistory({
      'id': id,
      'type': 'medication_reminder',
      'title': title,
      'body': body,
      'payload': 'medication:$medicationName',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Utility methods
  int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  Color _getNotificationColor(String classification) {
    switch (classification.toLowerCase()) {
      case 'normal sinus rhythm':
        return const Color(0xFF4CAF50); // Green
      case 'atrial fibrillation':
      case 'premature ventricular contractions':
        return const Color(0xFFFF5722); // Red
      case 'sinus bradycardia':
      case 'sinus tachycardia':
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }

  Future<bool> _areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> _saveNotificationHistory(Map<String, dynamic> notification) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('notification_history') ?? [];
    
    // Keep only last 50 notifications
    if (history.length >= 50) {
      history.removeAt(0);
    }
    
    history.add(jsonEncode(notification));
    await prefs.setStringList('notification_history', history);
  }

  // Public methods for managing notifications
  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('notification_history') ?? [];
    
    return history.map((item) => Map<String, dynamic>.from(jsonDecode(item))).toList().reversed.toList();
  }

  Future<void> clearNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_history');
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    
    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  // Test notification for debugging
  Future<void> showTestNotification() async {
    await showECGAnalysisComplete(
      reportId: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
      classification: 'Normal Sinus Rhythm',
      confidence: 0.95,
    );
  }
}