const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../models/User');
const { authenticateToken, requireEmailVerification } = require('../middleware/auth');
const router = express.Router();

// In-memory storage for development when MongoDB is not available
let inMemoryUsers = [];
let userIdCounter = 1;

// Helper function to find user in memory
const findUserInMemory = (email) => {
  return inMemoryUsers.find(user => user.email === email.toLowerCase());
};

// Helper function to check if MongoDB is connected
const isMongoConnected = () => {
  const mongoose = require('mongoose');
  return mongoose.connection.readyState === 1;
};

// Register new user
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, phone, dateOfBirth, gender, role = 'patient' } = req.body;

    // Validation
    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Name, email, and password are required'
      });
    }

    let existingUser;
    
    if (isMongoConnected()) {
      // Use MongoDB
      existingUser = await User.findOne({ email: email.toLowerCase() });
    } else {
      // Use in-memory storage
      existingUser = findUserInMemory(email);
    }

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);

    if (isMongoConnected()) {
      // Create new user in MongoDB
      const user = new User({
        name,
        email: email.toLowerCase(),
        password,
        phone,
        dateOfBirth,
        gender,
        role: 'patient'
      });

      await user.save();

      // Generate tokens
      const accessToken = user.generateAccessToken();
      const refreshToken = user.generateRefreshToken();

      // Save refresh token
      user.refreshTokens.push({
        token: refreshToken,
        createdAt: new Date(),
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
      });
      await user.save();

      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        data: {
          user: {
            id: user._id,
            name: user.name,
            email: user.email,
            phone: user.phone,
            role: user.role,
            isEmailVerified: user.isEmailVerified
          },
          tokens: {
            accessToken,
            refreshToken
          }
        }
      });
    } else {
      // Create new user in memory
      const newUser = {
        id: userIdCounter++,
        name,
        email: email.toLowerCase(),
        password: hashedPassword,
        phone,
        dateOfBirth,
        gender,
        role: 'patient',
        isEmailVerified: false,
        createdAt: new Date(),
        settings: {
          notifications: true,
          biometric: false,
          language: 'en',
          theme: 'light'
        }
      };

      inMemoryUsers.push(newUser);

      // Generate simple tokens for development
      const accessToken = jwt.sign(
        { userId: newUser.id, email: newUser.email, role: newUser.role },
        process.env.JWT_SECRET || 'dev-secret',
        { expiresIn: '24h' }
      );

      res.status(201).json({
        success: true,
        message: 'User registered successfully (development mode)',
        data: {
          user: {
            id: newUser.id,
            name: newUser.name,
            email: newUser.email,
            phone: newUser.phone,
            role: newUser.role,
            isEmailVerified: newUser.isEmailVerified
          },
          tokens: {
            accessToken,
            refreshToken: accessToken // Use same token for simplicity in dev
          }
        }
      });
    }

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error during registration'
    });
  }
});

// Login user
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    let user;

    if (isMongoConnected()) {
      // Use MongoDB
      user = await User.findOne({ email: email.toLowerCase() }).select('+password');
      
      if (!user || !(await user.comparePassword(password))) {
        return res.status(401).json({
          success: false,
          message: 'Invalid email or password'
        });
      }

      // Generate tokens
      const accessToken = user.generateAccessToken();
      const refreshToken = user.generateRefreshToken();

      // Save refresh token
      user.refreshTokens.push({
        token: refreshToken,
        createdAt: new Date(),
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      });
      await user.save();

      res.json({
        success: true,
        message: 'Login successful',
        data: {
          user: {
            id: user._id,
            name: user.name,
            email: user.email,
            phone: user.phone,
            role: user.role,
            isEmailVerified: user.isEmailVerified
          },
          tokens: {
            accessToken,
            refreshToken
          }
        }
      });
    } else {
      // Use in-memory storage
      user = findUserInMemory(email);
      
      if (!user || !(await bcrypt.compare(password, user.password))) {
        return res.status(401).json({
          success: false,
          message: 'Invalid email or password'
        });
      }

      // Generate simple token for development
      const accessToken = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET || 'dev-secret',
        { expiresIn: '24h' }
      );

      res.json({
        success: true,
        message: 'Login successful (development mode)',
        data: {
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            phone: user.phone,
            role: user.role,
            isEmailVerified: user.isEmailVerified
          },
          tokens: {
            accessToken,
            refreshToken: accessToken
          }
        }
      });
    }

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error during login'
    });
  }
});

// Get user profile
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    let user;

    if (isMongoConnected()) {
      user = await User.findById(req.user.userId);
    } else {
      user = inMemoryUsers.find(u => u.id === req.user.userId);
    }

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: {
        user: {
          id: user._id || user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          dateOfBirth: user.dateOfBirth,
          gender: user.gender,
          role: user.role,
          isEmailVerified: user.isEmailVerified,
          settings: user.settings || {
            notifications: true,
            biometric: false,
            language: 'en',
            theme: 'light'
          }
        }
      }
    });
  } catch (error) {
    console.error('Profile fetch error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Update user profile
router.put('/profile', authenticateToken, async (req, res) => {
  try {
    const { name, phone, dateOfBirth, gender, settings } = req.body;
    let user;

    if (isMongoConnected()) {
      user = await User.findById(req.user.userId);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      // Update fields
      if (name) user.name = name;
      if (phone) user.phone = phone;
      if (dateOfBirth) user.dateOfBirth = dateOfBirth;
      if (gender) user.gender = gender;
      if (settings) user.settings = { ...user.settings, ...settings };

      await user.save();
    } else {
      user = inMemoryUsers.find(u => u.id === req.user.userId);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      // Update fields
      if (name) user.name = name;
      if (phone) user.phone = phone;
      if (dateOfBirth) user.dateOfBirth = dateOfBirth;
      if (gender) user.gender = gender;
      if (settings) user.settings = { ...user.settings, ...settings };
    }

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: {
          id: user._id || user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          dateOfBirth: user.dateOfBirth,
          gender: user.gender,
          role: user.role,
          isEmailVerified: user.isEmailVerified,
          settings: user.settings
        }
      }
    });
  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Logout user
router.post('/logout', authenticateToken, async (req, res) => {
  try {
    res.json({
      success: true,
      message: 'Logout successful'
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;