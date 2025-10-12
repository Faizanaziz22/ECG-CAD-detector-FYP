const express = require('express');
const jwt = require('jsonwebtoken');
const NotificationService = require('../services/notification_service');

const router = express.Router();
const notificationService = new NotificationService();

// JWT Secret (should be in environment variables)
const JWT_SECRET = process.env.JWT_SECRET || 'test_secret_key';

// Middleware to verify JWT token
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Get all notifications for the authenticated user
router.get('/', authenticateToken, (req, res) => {
  try {
    const { includeRead = 'true' } = req.query;
    const notifications = notificationService.getUserNotifications(
      req.user.id,
      includeRead === 'true'
    );

    res.json({
      success: true,
      notifications: notifications.map(n => n.toJson()),
      unreadCount: notificationService.getUnreadCount(req.user.id)
    });
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

// Get unread notification count
router.get('/unread-count', authenticateToken, (req, res) => {
  try {
    const unreadCount = notificationService.getUnreadCount(req.user.id);
    res.json({
      success: true,
      unreadCount
    });
  } catch (error) {
    console.error('Error fetching unread count:', error);
    res.status(500).json({ error: 'Failed to fetch unread count' });
  }
});

// Mark a notification as read
router.patch('/:id/read', authenticateToken, (req, res) => {
  try {
    const notificationId = parseInt(req.params.id);
    const success = notificationService.markAsRead(req.user.id, notificationId);

    if (success) {
      res.json({
        success: true,
        message: 'Notification marked as read'
      });
    } else {
      res.status(404).json({ error: 'Notification not found' });
    }
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({ error: 'Failed to mark notification as read' });
  }
});

// Mark all notifications as read
router.patch('/mark-all-read', authenticateToken, (req, res) => {
  try {
    const count = notificationService.markAllAsRead(req.user.id);
    res.json({
      success: true,
      message: `${count} notifications marked as read`
    });
  } catch (error) {
    console.error('Error marking all notifications as read:', error);
    res.status(500).json({ error: 'Failed to mark all notifications as read' });
  }
});

// Delete a notification
router.delete('/:id', authenticateToken, (req, res) => {
  try {
    const notificationId = parseInt(req.params.id);
    const success = notificationService.deleteNotification(req.user.id, notificationId);

    if (success) {
      res.json({
        success: true,
        message: 'Notification deleted'
      });
    } else {
      res.status(404).json({ error: 'Notification not found' });
    }
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({ error: 'Failed to delete notification' });
  }
});

// Create a test notification (for development/testing)
router.post('/test', authenticateToken, (req, res) => {
  try {
    const { type = 'system_alert', title, message, data = {} } = req.body;

    if (!title || !message) {
      return res.status(400).json({ error: 'Title and message are required' });
    }

    const notification = notificationService.createNotification({
      userId: req.user.id,
      type,
      title,
      message,
      data
    });

    res.status(201).json({
      success: true,
      notification: notification.toJson()
    });
  } catch (error) {
    console.error('Error creating test notification:', error);
    res.status(500).json({ error: 'Failed to create test notification' });
  }
});

// Export the notification service instance for use in other modules
router.notificationService = notificationService;

module.exports = router;