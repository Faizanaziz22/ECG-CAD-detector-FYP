// Simple test script to verify API endpoints without MongoDB
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 5001;

// Middleware
app.use(cors());
app.use(express.json());

// In-memory storage for testing (replace MongoDB)
let users = [];

// JWT secret for testing
const JWT_SECRET = 'test_secret_key';

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'Medical App Backend (Test Mode)'
  });
});

// Signup endpoint
app.post('/api/auth/signup', async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    // Basic validation
    if (!name || !email || !password || !role) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    if (!['patient', 'doctor'].includes(role)) {
      return res.status(400).json({ message: 'Role must be either patient or doctor' });
    }

    // Check if user already exists
    const existingUser = users.find(user => user.email === email);
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists with this email' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const newUser = {
      id: users.length + 1,
      name,
      email,
      password: hashedPassword,
      role,
      createdAt: new Date()
    };

    users.push(newUser);

    res.status(201).json({
      message: 'User registered successfully',
      user: {
        id: newUser.id,
        name: newUser.name,
        email: newUser.email,
        role: newUser.role
      }
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ message: 'Server error during registration' });
  }
});

// Login endpoint
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Basic validation
    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    // Find user
    const user = users.find(u => u.email === email);
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Server error during login' });
  }
});

// Protected route middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ message: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Patient dashboard
app.get('/api/patient/dashboard', authenticateToken, (req, res) => {
  if (req.user.role !== 'patient') {
    return res.status(403).json({ message: 'Access denied. Patient role required.' });
  }

  res.json({
    message: 'Welcome to Patient Dashboard',
    user: req.user,
    data: {
      appointments: [],
      medicalRecords: [],
      notifications: []
    }
  });
});

// Doctor dashboard
app.get('/api/doctor/dashboard', authenticateToken, (req, res) => {
  if (req.user.role !== 'doctor') {
    return res.status(403).json({ message: 'Access denied. Doctor role required.' });
  }

  res.json({
    message: 'Welcome to Doctor Dashboard',
    user: {
      id: req.user.id,
      name: req.user.name,
      email: req.user.email,
      role: req.user.role
    }
  });
});

// ECG Routes
const ecgRoutes = require('./routes/ecg');
app.use('/api/ecg', ecgRoutes);

// Notifications routes
const notificationsRoutes = require('./routes/notifications');
app.use('/api/notifications', notificationsRoutes);

// Inject notification service into ECG routes
ecgRoutes.setNotificationService(notificationsRoutes.notificationService);

app.listen(PORT, () => {
  console.log(`Test server is running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log('This is a test server with in-memory storage (no MongoDB required)');
});