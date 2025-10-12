const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const notificationService = require('../services/notificationService');
const User = require('../models/User');
const router = express.Router();

// Get user's notifications
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { page = 1, limit = 20, unreadOnly = false } = req.query;
    
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    let notifications = user.notifications || [];
    
    // Filter unread only if requested
    if (unreadOnly === 'true') {
      notifications = notifications.filter(n => !n.read);
    }

    // Sort by creation date (newest first)
    notifications.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    // Pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const paginatedNotifications = notifications.slice(skip, skip + parseInt(limit));

    // Count unread notifications
    const unreadCount = notifications.filter(n => !n.read).length;

    res.json({
      success: true,
      data: {
        notifications: paginatedNotifications,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(notifications.length / parseInt(limit)),
          totalRecords: notifications.length,
          hasNext: skip + paginatedNotifications.length < notifications.length,
          hasPrev: parseInt(page) > 1
        },
        unreadCount
      }
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get notifications'
    });
  }
});

// Mark notifications as read
router.put('/mark-read', authenticateToken, async (req, res) => {
  try {
    const { notificationIds = [] } = req.body;
    
    await notificationService.markAsRead(req.user._id, notificationIds);
    
    res.json({
      success: true,
      message: notificationIds.length === 0 
        ? 'All notifications marked as read' 
        : 'Selected notifications marked as read'
    });
  } catch (error) {
    console.error('Mark notifications as read error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark notifications as read'
    });
  }
});

// Get notification count
router.get('/count', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const notifications = user.notifications || [];
    const unreadCount = notifications.filter(n => !n.read).length;
    const totalCount = notifications.length;

    res.json({
      success: true,
      data: {
        unreadCount,
        totalCount
      }
    });
  } catch (error) {
    console.error('Get notification count error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get notification count'
    });
  }
});

// Clear all notifications
router.delete('/clear', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    user.notifications = [];
    await user.save();

    res.json({
      success: true,
      message: 'All notifications cleared'
    });
  } catch (error) {
    console.error('Clear notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to clear notifications'
    });
  }
});

// Delete specific notifications
router.delete('/', authenticateToken, async (req, res) => {
  try {
    const { notificationIds } = req.body;
    
    if (!notificationIds || !Array.isArray(notificationIds)) {
      return res.status(400).json({
        success: false,
        message: 'Notification IDs array is required'
      });
    }

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Filter out the notifications to be deleted
    user.notifications = user.notifications.filter(
      n => !notificationIds.includes(n._id.toString())
    );
    
    await user.save();

    res.json({
      success: true,
      message: 'Selected notifications deleted'
    });
  } catch (error) {
    console.error('Delete notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete notifications'
    });
  }
});

// Get notification preferences
router.get('/preferences', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('notificationPreferences');
    
    const defaultPreferences = {
      email: {
        ecgUploaded: true,
        ecgAnalyzed: true,
        reviewRequested: true,
        reviewAssigned: true,
        reviewCompleted: true,
        reviewMessage: true,
        systemUpdates: false
      },
      push: {
        ecgUploaded: true,
        ecgAnalyzed: true,
        reviewRequested: true,
        reviewAssigned: true,
        reviewCompleted: true,
        reviewMessage: true,
        systemUpdates: true
      },
      inApp: {
        ecgUploaded: true,
        ecgAnalyzed: true,
        reviewRequested: true,
        reviewAssigned: true,
        reviewCompleted: true,
        reviewMessage: true,
        systemUpdates: true
      }
    };

    const preferences = user.notificationPreferences || defaultPreferences;

    res.json({
      success: true,
      data: { preferences }
    });
  } catch (error) {
    console.error('Get notification preferences error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get notification preferences'
    });
  }
});

// Update notification preferences
router.put('/preferences', authenticateToken, async (req, res) => {
  try {
    const { preferences } = req.body;
    
    if (!preferences) {
      return res.status(400).json({
        success: false,
        message: 'Preferences object is required'
      });
    }

    const user = await User.findByIdAndUpdate(
      req.user._id,
      { notificationPreferences: preferences },
      { new: true, runValidators: true }
    ).select('notificationPreferences');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'Notification preferences updated successfully',
      data: { preferences: user.notificationPreferences }
    });
  } catch (error) {
    console.error('Update notification preferences error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update notification preferences'
    });
  }
});

// Test notification endpoint (development only) - No auth required for testing
router.post('/test', async (req, res) => {
  try {
    if (process.env.NODE_ENV !== 'development') {
      return res.status(403).json({
        success: false,
        message: 'Test endpoint only available in development'
      });
    }

    const { type = 'test', title = 'Test Notification', message = 'This is a test notification' } = req.body;
    
    // Send test notification to all connected users
    notificationService.broadcastToAll({
      type,
      title,
      message,
      data: { test: true }
    });

    res.json({
      success: true,
      message: 'Test notification sent successfully to all connected users'
    });
  } catch (error) {
    console.error('Test notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send test notification'
    });
  }
});

// Simple health check endpoint for notifications
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Notification service is running',
    timestamp: new Date().toISOString(),
    connectedUsers: notificationService.getConnectedUsersCount()
  });
});

module.exports = router;