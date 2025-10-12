import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'offline_storage_service.dart';

class EnhancedNotificationService {
  static final EnhancedNotificationService _instance = EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Notification types
  static const String typeReportReady = 'report_ready';
  static const String typeDoctorFeedback = 'doctor_feedback';
  static const String typeSystemUpdate = 'system_update';
  static const String typeReviewRequest = 'review_request';
  static const String typeUrgentAlert = 'urgent_alert';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _isInitialized = true;
    debugPrint('EnhancedNotificationService: Initialized successfully');
  }

  Future<void> _requestPermissions() async {
    // Request notification permission
    final status = await Permission.notification.request();
    if (status.isDenied) {
      debugPrint('EnhancedNotificationService: Notification permission denied');
    }

    // For Android 13+ (API level 33+), request POST_NOTIFICATIONS permission
    if (await Permission.notification.isPermanentlyDenied) {
      debugPrint('EnhancedNotificationService: Notification permission permanently denied');
    }
  }

  Future<void> _createNotificationChannels() async {
    // High priority channel for urgent notifications
    const AndroidNotificationChannel urgentChannel = AndroidNotificationChannel(
      'urgent_channel',
      'Urgent Notifications',
      description: 'Critical medical alerts and urgent notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Normal priority channel for general notifications
    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general_channel',
      'General Notifications',
      description: 'General app notifications and updates',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // Low priority channel for background updates
    const AndroidNotificationChannel backgroundChannel = AndroidNotificationChannel(
      'background_channel',
      'Background Updates',
      description: 'Background sync and system updates',
      importance: Importance.low,
      playSound: false,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(urgentChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(backgroundChannel);
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        _handleNotificationTap(data);
      } catch (e) {
        debugPrint('EnhancedNotificationService: Error parsing notification payload: $e');
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    final recordId = data['recordId'];

    debugPrint('EnhancedNotificationService: Notification tapped - Type: $type, RecordId: $recordId');

    // Handle different notification types
    switch (type) {
      case typeReportReady:
        // Navigate to ECG report
        _navigateToECGReport(recordId);
        break;
      case typeDoctorFeedback:
        // Navigate to doctor feedback
        _navigateToDoctorFeedback(recordId);
        break;
      case typeReviewRequest:
        // Navigate to review request
        _navigateToReviewRequest(recordId);
        break;
      default:
        // Navigate to notifications screen
        _navigateToNotifications();
        break;
    }
  }

  void _navigateToECGReport(String? recordId) {
    // This would be implemented with your navigation system
    debugPrint('EnhancedNotificationService: Navigate to ECG report: $recordId');
  }

  void _navigateToDoctorFeedback(String? recordId) {
    // This would be implemented with your navigation system
    debugPrint('EnhancedNotificationService: Navigate to doctor feedback: $recordId');
  }

  void _navigateToReviewRequest(String? recordId) {
    // This would be implemented with your navigation system
    debugPrint('EnhancedNotificationService: Navigate to review request: $recordId');
  }

  void _navigateToNotifications() {
    // This would be implemented with your navigation system
    debugPrint('EnhancedNotificationService: Navigate to notifications');
  }

  // Show local notification
  Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    bool saveToStorage = true,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Save notification to local storage
    if (saveToStorage) {
      await _saveNotificationToStorage(id, title, body, type, data);
    }

    // Determine notification channel and priority
    String channelId;
    Importance importance;
    Priority priority;

    switch (type) {
      case typeUrgentAlert:
        channelId = 'urgent_channel';
        importance = Importance.high;
        priority = Priority.high;
        break;
      case typeReportReady:
      case typeDoctorFeedback:
      case typeReviewRequest:
        channelId = 'general_channel';
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
        break;
      default:
        channelId = 'background_channel';
        importance = Importance.low;
        priority = Priority.low;
        break;
    }

    // Create notification details
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: importance,
      priority: priority,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      icon: _getNotificationIcon(type),
      color: Color(_getNotificationColor(type) ?? 0xFF2196F3),
      enableVibration: type == typeUrgentAlert,
      playSound: type != typeSystemUpdate,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Create payload
    final payload = jsonEncode({
      'type': type,
      'id': id,
      ...?data,
    });

    // Show notification
    await _flutterLocalNotificationsPlugin.show(
      id.hashCode,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    debugPrint('EnhancedNotificationService: Notification shown - $title');
  }

  Future<void> _saveNotificationToStorage(String id, String title, String body, String type, Map<String, dynamic>? data) async {
    await OfflineStorageService.saveNotification({
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'urgent_channel':
        return 'Urgent Notifications';
      case 'general_channel':
        return 'General Notifications';
      case 'background_channel':
        return 'Background Updates';
      default:
        return 'Notifications';
    }
  }

  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'urgent_channel':
        return 'Critical medical alerts and urgent notifications';
      case 'general_channel':
        return 'General app notifications and updates';
      case 'background_channel':
        return 'Background sync and system updates';
      default:
        return 'App notifications';
    }
  }

  String? _getNotificationIcon(String type) {
    switch (type) {
      case typeReportReady:
        return '@drawable/ic_report';
      case typeDoctorFeedback:
        return '@drawable/ic_doctor';
      case typeUrgentAlert:
        return '@drawable/ic_alert';
      case typeReviewRequest:
        return '@drawable/ic_review';
      default:
        return null;
    }
  }

  int? _getNotificationColor(String type) {
    switch (type) {
      case typeUrgentAlert:
        return 0xFFFF0000; // Red
      case typeReportReady:
        return 0xFF4CAF50; // Green
      case typeDoctorFeedback:
        return 0xFF2196F3; // Blue
      case typeReviewRequest:
        return 0xFFFF9800; // Orange
      default:
        return null;
    }
  }

  // Predefined notification methods
  Future<void> showReportReadyNotification(String recordId, String filename) async {
    await showNotification(
      id: 'report_ready_$recordId',
      title: 'ECG Report Ready',
      body: 'Your ECG analysis for $filename is now available',
      type: typeReportReady,
      data: {'recordId': recordId, 'filename': filename},
    );
  }

  Future<void> showDoctorFeedbackNotification(String recordId, String doctorName) async {
    await showNotification(
      id: 'doctor_feedback_$recordId',
      title: 'Doctor Review Complete',
      body: 'Dr. $doctorName has reviewed your ECG and provided feedback',
      type: typeDoctorFeedback,
      data: {'recordId': recordId, 'doctorName': doctorName},
    );
  }

  Future<void> showReviewRequestNotification(String recordId, String patientName) async {
    await showNotification(
      id: 'review_request_$recordId',
      title: 'New Review Request',
      body: '$patientName has requested a review for their ECG',
      type: typeReviewRequest,
      data: {'recordId': recordId, 'patientName': patientName},
    );
  }

  Future<void> showUrgentAlertNotification(String message, {Map<String, dynamic>? data}) async {
    await showNotification(
      id: 'urgent_alert_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Urgent Medical Alert',
      body: message,
      type: typeUrgentAlert,
      data: data,
    );
  }

  Future<void> showSystemUpdateNotification(String message) async {
    await showNotification(
      id: 'system_update_${DateTime.now().millisecondsSinceEpoch}',
      title: 'System Update',
      body: message,
      type: typeSystemUpdate,
    );
  }

  // Get stored notifications
  Future<List<Map<String, dynamic>>> getStoredNotifications() async {
    return await OfflineStorageService.getNotifications();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await OfflineStorageService.markNotificationAsRead(notificationId);
  }

  // Cancel notification
  Future<void> cancelNotification(String notificationId) async {
    await _flutterLocalNotificationsPlugin.cancel(notificationId.hashCode);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Schedule notification for later
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required String type,
    required DateTime scheduledDate,
    Map<String, dynamic>? data,
  }) async {
    // This would require additional setup for scheduled notifications
    // For now, we'll just show it immediately if the time has passed
    if (scheduledDate.isBefore(DateTime.now())) {
      await showNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        data: data,
      );
    }
  }
}