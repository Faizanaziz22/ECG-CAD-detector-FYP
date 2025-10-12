class Notification {
  constructor({
    id,
    userId,
    type,
    title,
    message,
    data = {},
    isRead = false,
    createdAt = new Date(),
    expiresAt = null
  }) {
    this.id = id;
    this.userId = userId;
    this.type = type; // 'report_ready', 'doctor_feedback', 'system_alert', 'appointment_reminder'
    this.title = title;
    this.message = message;
    this.data = data; // Additional data specific to notification type
    this.isRead = isRead;
    this.createdAt = createdAt;
    this.expiresAt = expiresAt;
  }

  static fromJson(json) {
    return new Notification({
      id: json.id,
      userId: json.userId,
      type: json.type,
      title: json.title,
      message: json.message,
      data: json.data || {},
      isRead: json.isRead || false,
      createdAt: new Date(json.createdAt),
      expiresAt: json.expiresAt ? new Date(json.expiresAt) : null
    });
  }

  toJson() {
    return {
      id: this.id,
      userId: this.userId,
      type: this.type,
      title: this.title,
      message: this.message,
      data: this.data,
      isRead: this.isRead,
      createdAt: this.createdAt.toISOString(),
      expiresAt: this.expiresAt ? this.expiresAt.toISOString() : null
    };
  }

  // Check if notification is expired
  isExpired() {
    if (!this.expiresAt) return false;
    return new Date() > this.expiresAt;
  }

  // Mark notification as read
  markAsRead() {
    this.isRead = true;
  }
}

module.exports = Notification;