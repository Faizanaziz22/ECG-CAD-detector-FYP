import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/notification.dart' as NotificationModel;
import '../services/notification_service.dart';
import '../utils/notification_categories.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel.Notification> notifications = [];
  bool isLoading = true;
  String? error;
  bool showOnlyUnread = false;
  NotificationCategory? selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final result = await NotificationService.getNotifications(
      includeRead: !showOnlyUnread,
    );

    if (mounted) {
      setState(() {
        isLoading = false;
        if (result['success']) {
          notifications = result['notifications'];
        } else {
          error = result['error'];
        }
      });
    }
  }

  Future<void> _markAsRead(NotificationModel.Notification notification) async {
    if (notification.isRead) return;

    final result = await NotificationService.markAsRead(notification.id);
    if (result['success']) {
      setState(() {
        final index = notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          notifications[index] = notification.copyWith(isRead: true);
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'])),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final result = await NotificationService.markAllAsRead();
    if (result['success']) {
      setState(() {
        notifications = notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'])),
        );
      }
    }
  }

  Future<void> _deleteNotification(NotificationModel.Notification notification) async {
    final result = await NotificationService.deleteNotification(notification.id);
    if (result['success']) {
      setState(() {
        notifications.removeWhere((n) => n.id == notification.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'])),
        );
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    final category = NotificationCategoryHelper.getCategoryFromType(type);
    return NotificationCategoryHelper.getCategoryIcon(category);
  }

  Color _getNotificationColor(String type) {
    final category = NotificationCategoryHelper.getCategoryFromType(type);
    return NotificationCategoryHelper.getCategoryColor(category);
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Get filtered notifications based on current filters
  List<NotificationModel.Notification> get _filteredNotifications {
    var filtered = notifications.where((notification) {
      // Filter by read status
      if (showOnlyUnread && notification.isRead) {
        return false;
      }
      
      // Filter by category
      if (selectedCategory != null) {
        final notificationCategory = NotificationCategoryHelper.getCategoryFromType(notification.type);
        if (notificationCategory != selectedCategory) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  // Get appropriate empty state message
  String _getEmptyStateMessage() {
    if (selectedCategory != null && showOnlyUnread) {
      return 'No unread ${NotificationCategoryHelper.getCategoryName(selectedCategory!).toLowerCase()} notifications';
    } else if (selectedCategory != null) {
      return 'No ${NotificationCategoryHelper.getCategoryName(selectedCategory!).toLowerCase()} notifications';
    } else if (showOnlyUnread) {
      return 'No unread notifications';
    } else {
      return 'No notifications yet';
    }
  }

  // Get appropriate empty state subtitle
  String _getEmptyStateSubtitle() {
    if (selectedCategory != null || showOnlyUnread) {
      return 'Try adjusting your filters';
    } else {
      return 'Notifications will appear here when you have them';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/notification-preferences'),
            tooltip: 'Notification Settings',
          ),
          PopupMenuButton<NotificationCategory?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by category',
            onSelected: (category) {
              setState(() {
                selectedCategory = category;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem<NotificationCategory?>(
                value: null,
                child: Text('All Categories'),
              ),
              ...NotificationCategoryHelper.getAllCategories().map(
                (category) => PopupMenuItem<NotificationCategory>(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        NotificationCategoryHelper.getCategoryIcon(category),
                        color: NotificationCategoryHelper.getCategoryColor(category),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(NotificationCategoryHelper.getCategoryName(category)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(showOnlyUnread ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                showOnlyUnread = !showOnlyUnread;
              });
            },
            tooltip: showOnlyUnread ? 'Show all' : 'Show unread only',
          ),
          if (notifications.any((n) => !n.isRead))
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading notifications',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _filteredNotifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getEmptyStateMessage(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getEmptyStateSubtitle(),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        itemCount: _filteredNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = _filteredNotifications[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            elevation: notification.isRead ? 1 : 3,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getNotificationColor(notification.type),
                                child: Icon(
                                  _getNotificationIcon(notification.type),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.isRead 
                                      ? FontWeight.normal 
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(notification.message),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTimeAgo(notification.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'mark_read':
                                      _markAsRead(notification);
                                      break;
                                    case 'delete':
                                      _deleteNotification(notification);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (!notification.isRead)
                                    const PopupMenuItem(
                                      value: 'mark_read',
                                      child: Row(
                                        children: [
                                          Icon(Icons.mark_email_read),
                                          SizedBox(width: 8),
                                          Text('Mark as read'),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _markAsRead(notification),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}