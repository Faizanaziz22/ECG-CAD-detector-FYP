import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification.dart' as NotificationModel;
import 'notification_service.dart';
import 'sound_service.dart';

class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  List<NotificationModel.Notification> _notifications = [];
  Timer? _pollingTimer;
  bool _isPolling = false;
  
  List<NotificationModel.Notification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  // Start periodic polling for new notifications
  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    if (_isPolling) return;
    
    _isPolling = true;
    _pollingTimer = Timer.periodic(interval, (timer) {
      _fetchNotifications();
    });
    
    // Initial fetch
    _fetchNotifications();
  }

  // Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
  }

  // Fetch notifications from service
  Future<void> _fetchNotifications() async {
    try {
      final result = await NotificationService.getNotifications(includeRead: true);
      if (result['success']) {
        final newNotifications = result['notifications'] as List<NotificationModel.Notification>;
        
        // Check for new notifications
        final oldIds = _notifications.map((n) => n.id).toSet();
        final newIds = newNotifications.map((n) => n.id).toSet();
        final hasNewNotifications = newIds.difference(oldIds).isNotEmpty;
        
        _notifications = newNotifications;
        notifyListeners();
        
        // Trigger sound/vibration for new notifications
        if (hasNewNotifications) {
          _onNewNotifications();
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  // Handle new notifications (sound, vibration, etc.)
  void _onNewNotifications() {
    // This could be extended to play sounds or trigger vibrations
    debugPrint('New notifications received');
    
    // Process each new notification
    for (var notification in _notifications) {
      _onNewNotification(notification);
    }
  }

  // Trigger actions for new notifications
  void _onNewNotification(NotificationModel.Notification notification) {
    // Play sound/vibration based on notification type
    _playNotificationAlert(notification);
    
    // You can add more actions here like showing in-app notifications
    debugPrint('New notification: ${notification.title}');
  }
  
  // Play appropriate alert based on notification type
  Future<void> _playNotificationAlert(NotificationModel.Notification notification) async {
    switch (notification.type.toLowerCase()) {
      case 'urgent':
      case 'critical':
        await SoundService.playUrgentAlert();
        break;
      case 'info':
      case 'reminder':
        await SoundService.playInfoAlert();
        break;
      case 'success':
        await SoundService.playSuccessAlert();
        break;
      default:
        await SoundService.playNotificationAlert();
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final result = await NotificationService.markAsRead(int.parse(notificationId));
    if (result['success']) {
      final index = _notifications.indexWhere((n) => n.id.toString() == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final result = await NotificationService.markAllAsRead();
    if (result['success']) {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final result = await NotificationService.deleteNotification(int.parse(notificationId));
    if (result['success']) {
      _notifications.removeWhere((n) => n.id.toString() == notificationId);
      notifyListeners();
    }
  }

  // Refresh notifications manually
  Future<void> refresh() async {
    await _fetchNotifications();
  }

  // Add a new notification (for testing or local notifications)
  void addNotification(NotificationModel.Notification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
    _onNewNotifications();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}