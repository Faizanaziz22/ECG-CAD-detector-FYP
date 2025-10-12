const Notification = require('../models/Notification');

class NotificationService {
  constructor() {
    // In-memory storage for notifications (in production, use a database)
    this.notifications = new Map();
    this.notificationIdCounter = 1;
  }

  // Create a new notification
  createNotification({
    userId,
    type,
    title,
    message,
    data = {},
    expiresAt = null
  }) {
    const notification = new Notification({
      id: this.notificationIdCounter++,
      userId,
      type,
      title,
      message,
      data,
      expiresAt
    });

    if (!this.notifications.has(userId)) {
      this.notifications.set(userId, []);
    }

    this.notifications.get(userId).push(notification);
    return notification;
  }

  // Get all notifications for a user
  getUserNotifications(userId, includeRead = true) {
    const userNotifications = this.notifications.get(userId) || [];
    
    // Filter out expired notifications
    const validNotifications = userNotifications.filter(n => !n.isExpired());
    
    // Update the stored notifications to remove expired ones
    this.notifications.set(userId, validNotifications);
    
    if (!includeRead) {
      return validNotifications.filter(n => !n.isRead);
    }
    
    return validNotifications.sort((a, b) => b.createdAt - a.createdAt);
  }

  // Get unread notification count
  getUnreadCount(userId) {
    const notifications = this.getUserNotifications(userId, false);
    return notifications.length;
  }

  // Mark notification as read
  markAsRead(userId, notificationId) {
    const userNotifications = this.notifications.get(userId) || [];
    const notification = userNotifications.find(n => n.id === notificationId);
    
    if (notification) {
      notification.markAsRead();
      return true;
    }
    
    return false;
  }

  // Mark all notifications as read for a user
  markAllAsRead(userId) {
    const userNotifications = this.notifications.get(userId) || [];
    userNotifications.forEach(n => n.markAsRead());
    return userNotifications.length;
  }

  // Delete a notification
  deleteNotification(userId, notificationId) {
    const userNotifications = this.notifications.get(userId) || [];
    const index = userNotifications.findIndex(n => n.id === notificationId);
    
    if (index !== -1) {
      userNotifications.splice(index, 1);
      return true;
    }
    
    return false;
  }

  // Create ECG report ready notification
  createECGReportReadyNotification(userId, ecgRecordId, fileName) {
    return this.createNotification({
      userId,
      type: 'report_ready',
      title: 'ECG Analysis Complete',
      message: `Your ECG analysis for "${fileName}" is ready for review.`,
      data: {
        ecgRecordId,
        fileName,
        action: 'view_report'
      }
    });
  }

  // Create doctor feedback notification
  createDoctorFeedbackNotification(userId, ecgRecordId, doctorName, fileName) {
    return this.createNotification({
      userId,
      type: 'doctor_feedback',
      title: 'Doctor Review Available',
      message: `Dr. ${doctorName} has reviewed your ECG "${fileName}".`,
      data: {
        ecgRecordId,
        doctorName,
        fileName,
        action: 'view_review'
      }
    });
  }

  // Create system alert notification
  createSystemAlertNotification(userId, alertType, message, data = {}) {
    return this.createNotification({
      userId,
      type: 'system_alert',
      title: 'System Alert',
      message,
      data: {
        alertType,
        ...data
      }
    });
  }

  // Create appointment reminder notification
  createAppointmentReminderNotification(userId, appointmentId, doctorName, appointmentTime) {
    const reminderTime = new Date(appointmentTime);
    reminderTime.setHours(reminderTime.getHours() - 1); // Remind 1 hour before

    return this.createNotification({
      userId,
      type: 'appointment_reminder',
      title: 'Appointment Reminder',
      message: `You have an appointment with Dr. ${doctorName} in 1 hour.`,
      data: {
        appointmentId,
        doctorName,
        appointmentTime: appointmentTime.toISOString(),
        action: 'view_appointment'
      },
      expiresAt: new Date(appointmentTime.getTime() + 2 * 60 * 60 * 1000) // Expire 2 hours after appointment
    });
  }

  // Clean up expired notifications
  cleanupExpiredNotifications() {
    let cleanedCount = 0;
    
    for (const [userId, notifications] of this.notifications.entries()) {
      const validNotifications = notifications.filter(n => !n.isExpired());
      cleanedCount += notifications.length - validNotifications.length;
      this.notifications.set(userId, validNotifications);
    }
    
    return cleanedCount;
  }
}

module.exports = NotificationService;