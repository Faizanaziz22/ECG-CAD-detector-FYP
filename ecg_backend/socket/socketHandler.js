const jwt = require('jsonwebtoken');
const User = require('../models/User');
const notificationService = require('../services/notificationService');

// Socket authentication middleware
const authenticateSocket = async (socket, next) => {
  try {
    const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return next(new Error('Authentication token required'));
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId).select('-password');
    
    if (!user || !user.isActive || user.isDeleted) {
      return next(new Error('Invalid or inactive user'));
    }

    socket.userId = user._id.toString();
    socket.user = user;
    next();
  } catch (error) {
    console.error('Socket authentication error:', error);
    next(new Error('Authentication failed'));
  }
};

// Socket connection handler
const handleConnection = (io) => {
  // Initialize notification service with Socket.IO instance
  notificationService.initialize(io);
  
  // Apply authentication middleware
  io.use(authenticateSocket);

  io.on('connection', (socket) => {
    console.log(`User ${socket.user.name} (${socket.userId}) connected via socket`);

    // Register user for notifications
    notificationService.registerUser(socket.userId, socket);

    // Handle notification acknowledgment
    socket.on('notification:ack', async (data) => {
      try {
        const { notificationIds } = data;
        if (notificationIds && Array.isArray(notificationIds)) {
          await notificationService.markAsRead(socket.userId, notificationIds);
          socket.emit('notification:ack:success', { notificationIds });
        }
      } catch (error) {
        console.error('Notification acknowledgment error:', error);
        socket.emit('notification:ack:error', { error: 'Failed to acknowledge notifications' });
      }
    });

    // Handle mark all notifications as read
    socket.on('notification:mark-all-read', async () => {
      try {
        await notificationService.markAsRead(socket.userId, []);
        socket.emit('notification:mark-all-read:success');
      } catch (error) {
        console.error('Mark all notifications as read error:', error);
        socket.emit('notification:mark-all-read:error', { error: 'Failed to mark all notifications as read' });
      }
    });

    // Handle notification preferences update
    socket.on('notification:preferences', async (data) => {
      try {
        const { preferences } = data;
        const user = await User.findByIdAndUpdate(
          socket.userId,
          { notificationPreferences: preferences },
          { new: true, runValidators: true }
        ).select('notificationPreferences');

        if (user) {
          socket.emit('notification:preferences:success', { preferences: user.notificationPreferences });
        } else {
          socket.emit('notification:preferences:error', { error: 'User not found' });
        }
      } catch (error) {
        console.error('Update notification preferences error:', error);
        socket.emit('notification:preferences:error', { error: 'Failed to update preferences' });
      }
    });

    // Handle join room for specific review
    socket.on('review:join', (data) => {
      const { reviewId } = data;
      if (reviewId) {
        socket.join(`review:${reviewId}`);
        console.log(`User ${socket.userId} joined review room: ${reviewId}`);
      }
    });

    // Handle leave room for specific review
    socket.on('review:leave', (data) => {
      const { reviewId } = data;
      if (reviewId) {
        socket.leave(`review:${reviewId}`);
        console.log(`User ${socket.userId} left review room: ${reviewId}`);
      }
    });

    // Handle typing indicator for review messages
    socket.on('review:typing', (data) => {
      const { reviewId, isTyping } = data;
      if (reviewId) {
        socket.to(`review:${reviewId}`).emit('review:typing', {
          userId: socket.userId,
          userName: socket.user.name,
          isTyping
        });
      }
    });

    // Handle user status updates
    socket.on('user:status', (data) => {
      const { status } = data; // online, away, busy, offline
      socket.broadcast.emit('user:status:update', {
        userId: socket.userId,
        userName: socket.user.name,
        status
      });
    });

    // Handle ping/pong for connection health
    socket.on('ping', () => {
      socket.emit('pong', { timestamp: Date.now() });
    });

    // Handle disconnection
    socket.on('disconnect', (reason) => {
      console.log(`User ${socket.user.name} (${socket.userId}) disconnected: ${reason}`);
      
      // Broadcast user offline status
      socket.broadcast.emit('user:status:update', {
        userId: socket.userId,
        userName: socket.user.name,
        status: 'offline'
      });
    });

    // Handle connection errors
    socket.on('error', (error) => {
      console.error(`Socket error for user ${socket.userId}:`, error);
    });

    // Send initial connection success
    socket.emit('connection:success', {
      message: 'Connected successfully',
      userId: socket.userId,
      userName: socket.user.name,
      timestamp: new Date()
    });
  });

  // Handle connection errors
  io.on('connect_error', (error) => {
    console.error('Socket.IO connection error:', error);
  });
};

// Utility functions for emitting to specific rooms/users

const emitToReview = (io, reviewId, event, data) => {
  io.to(`review:${reviewId}`).emit(event, data);
};

const emitToUser = (io, userId, event, data) => {
  const userSockets = io.sockets.sockets;
  for (const [socketId, socket] of userSockets) {
    if (socket.userId === userId.toString()) {
      socket.emit(event, data);
      break;
    }
  }
};

const emitToRole = (io, role, event, data) => {
  const userSockets = io.sockets.sockets;
  for (const [socketId, socket] of userSockets) {
    if (socket.user && socket.user.role === role) {
      socket.emit(event, data);
    }
  }
};

const broadcastToAll = (io, event, data) => {
  io.emit(event, data);
};

module.exports = {
  handleConnection,
  emitToReview,
  emitToUser,
  emitToRole,
  broadcastToAll
};