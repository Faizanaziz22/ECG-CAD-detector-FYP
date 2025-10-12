const EventEmitter = require('events');

class NotificationService extends EventEmitter {
  constructor() {
    super();
    this.connectedUsers = new Map(); // userId -> socket
    this.userNotifications = new Map(); // userId -> notifications array
    this.io = null;
  }

  // Initialize with Socket.IO instance
  initialize(io) {
    this.io = io;
    console.log('NotificationService initialized with Socket.IO');
  }

  // Register user connection
  registerUser(userId, socket) {
    this.connectedUsers.set(userId.toString(), socket);
    console.log(`User ${userId} connected for notifications`);
    
    // Send any pending notifications
    this.sendPendingNotifications(userId);
  }

  // Unregister user connection
  unregisterUser(userId) {
    this.connectedUsers.delete(userId.toString());
    console.log(`User ${userId} disconnected from notifications`);
  }

  // Get connected users count
  getConnectedUsersCount() {
    return this.connectedUsers.size;
  }

  // Broadcast notification to all connected users
  broadcastToAll(notification) {
    if (!this.io) {
      console.error('Socket.IO not initialized');
      return;
    }

    // Add timestamp if not present
    if (!notification.timestamp) {
      notification.timestamp = new Date();
    }

    // Broadcast to all connected sockets
    this.io.emit('notification', notification);
    console.log(`Broadcasted notification to all users: ${notification.title}`);
  }

  // Setup event handlers for different notification types
  setupEventHandlers() {
    // ECG Record notifications
    this.on('ecg:uploaded', this.handleECGUploaded.bind(this));
    this.on('ecg:analyzed', this.handleECGAnalyzed.bind(this));
    
    // System notifications
    this.on('system:maintenance', this.handleSystemMaintenance.bind(this));
    this.on('system:update', this.handleSystemUpdate.bind(this));
  }

  // Send notification to specific user
  async sendToUser(userId, notification) {
    const socket = this.connectedUsers.get(userId.toString());
    
    if (socket && socket.connected) {
      socket.emit('notification', notification);
      console.log(`Notification sent to user ${userId}:`, notification.type);
    } else {
      // Store notification for later delivery
      await this.storeNotification(userId, notification);
    }
  }

  // Send notification to multiple users
  async sendToUsers(userIds, notification) {
    const promises = userIds.map(userId => this.sendToUser(userId, notification));
    await Promise.all(promises);
  }

  // Store notification in database for offline users
  async storeNotification(userId, notification) {
    try {
      const user = await User.findById(userId);
      if (user) {
        if (!user.notifications) {
          user.notifications = [];
        }
        
        user.notifications.push({
          ...notification,
          createdAt: new Date(),
          read: false
        });

        // Keep only last 50 notifications
        if (user.notifications.length > 50) {
          user.notifications = user.notifications.slice(-50);
        }

        await user.save();
      }
    } catch (error) {
      console.error('Error storing notification:', error);
    }
  }

  // Send pending notifications to user
  async sendPendingNotifications(userId) {
    try {
      const user = await User.findById(userId);
      if (user && user.notifications) {
        const unreadNotifications = user.notifications.filter(n => !n.read);
        
        const socket = this.connectedUsers.get(userId.toString());
        if (socket && socket.connected) {
          unreadNotifications.forEach(notification => {
            socket.emit('notification', notification);
          });
        }
      }
    } catch (error) {
      console.error('Error sending pending notifications:', error);
    }
  }

  // Mark notifications as read
  async markAsRead(userId, notificationIds = []) {
    try {
      const user = await User.findById(userId);
      if (user && user.notifications) {
        if (notificationIds.length === 0) {
          // Mark all as read
          user.notifications.forEach(n => n.read = true);
        } else {
          // Mark specific notifications as read
          user.notifications.forEach(n => {
            if (notificationIds.includes(n._id.toString())) {
              n.read = true;
            }
          });
        }
        await user.save();
      }
    } catch (error) {
      console.error('Error marking notifications as read:', error);
    }
  }

  // Event Handlers

  async handleECGUploaded(data) {
    const { userId, ecgRecord } = data;
    
    const notification = {
      type: 'ecg_uploaded',
      title: 'ECG Record Uploaded',
      message: `Your ECG record "${ecgRecord.fileName}" has been uploaded successfully`,
      data: {
        ecgRecordId: ecgRecord._id,
        fileName: ecgRecord.fileName
      },
      priority: 'medium',
      timestamp: new Date()
    };

    await this.sendToUser(userId, notification);
  }

  async handleECGAnalyzed(data) {
    const { userId, ecgRecord, analysis } = data;
    
    const notification = {
      type: 'ecg_analyzed',
      title: 'ECG Analysis Complete',
      message: `Analysis complete for "${ecgRecord.fileName}". ${analysis.summary}`,
      data: {
        ecgRecordId: ecgRecord._id,
        fileName: ecgRecord.fileName,
        analysis: analysis
      },
      priority: analysis.severity === 'critical' ? 'high' : 'medium',
      timestamp: new Date()
    };

    await this.sendToUser(userId, notification);
  }

  async handleReviewRequested(data) {
    const { patientId, review } = data;
    
    // Notify patient
    const patientNotification = {
      type: 'review_requested',
      title: 'Doctor Review Requested',
      message: 'Your request for doctor review has been submitted and is pending assignment',
      data: {
        reviewId: review._id,
        priority: review.priority
      },
      priority: 'medium',
      timestamp: new Date()
    };

    await this.sendToUser(patientId, patientNotification);
  }

  // Remove all doctor-related handler methods
  async handleReviewRequested(data) {
    // This method is no longer needed as doctor reviews are removed
  }

  async handleSystemMaintenance(data) {
    const { message, scheduledTime, duration } = data;
    
    const notification = {
      type: 'system_maintenance',
      title: 'Scheduled Maintenance',
      message: message || 'System maintenance is scheduled',
      data: {
        scheduledTime: scheduledTime,
        duration: duration
      },
      priority: 'high',
      timestamp: new Date()
    };

    // Send to all active users
    const activeUsers = await User.find({ 
      isActive: true, 
      isDeleted: false 
    }).select('_id');
    
    const userIds = activeUsers.map(user => user._id);
    await this.sendToUsers(userIds, notification);
  }

  async handleSystemUpdate(data) {
    const { version, features, releaseNotes } = data;
    
    const notification = {
      type: 'system_update',
      title: 'System Update Available',
      message: `New version ${version} is available with exciting new features`,
      data: {
        version: version,
        features: features,
        releaseNotes: releaseNotes
      },
      priority: 'low',
      timestamp: new Date()
    };

    // Send to all active users
    const activeUsers = await User.find({ 
      isActive: true, 
      isDeleted: false 
    }).select('_id');
    
    const userIds = activeUsers.map(user => user._id);
    await this.sendToUsers(userIds, notification);
  }

  // Utility methods for triggering notifications

  notifyECGUploaded(userId, ecgRecord) {
    this.emit('ecg:uploaded', { userId, ecgRecord });
  }

  notifyECGAnalyzed(userId, ecgRecord, analysis) {
    this.emit('ecg:analyzed', { userId, ecgRecord, analysis });
  }

  notifySystemMaintenance(message, scheduledTime, duration) {
    this.emit('system:maintenance', { message, scheduledTime, duration });
  }

  notifySystemUpdate(version, features, releaseNotes) {
    this.emit('system:update', { version, features, releaseNotes });
  }
}

// Create singleton instance
const notificationService = new NotificationService();

module.exports = notificationService;