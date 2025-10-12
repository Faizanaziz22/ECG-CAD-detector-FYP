const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');

const router = express.Router();

// Signup route
router.post('/signup', [
  body('name')
    .trim()
    .isLength({ min: 2 })
    .withMessage('Name must be at least 2 characters long'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please enter a valid email'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long'),
  body('role')
    .isIn(['patient', 'doctor'])
    .withMessage('Role must be either patient or doctor'),
  // Age validation for patients
  body('age')
    .optional()
    .isInt({ min: 1, max: 120 })
    .withMessage('Age must be a number between 1 and 120'),
  // Specialization validation for doctors
  body('specialization')
    .optional()
    .isIn([
      'Cardiologist',
      'Interventional Cardiologist',
      'Cardiac Surgeon',
      'Preventive Cardiologist',
      'Cardiac Rehabilitation Specialist',
      'Cardiac Imaging Specialist',
      'Internal Medicine Specialist'
    ])
    .withMessage('Invalid specialization')
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { name, email, password, role, age, specialization } = req.body;

    // Role-specific validation
    if (role === 'patient' && !age) {
      return res.status(400).json({
        message: 'Age is required for patients'
      });
    }

    if (role === 'doctor' && !specialization) {
      return res.status(400).json({
        message: 'Specialization is required for doctors'
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        message: 'User with this email already exists'
      });
    }

    // Hash password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create user data object
    const userData = {
      name,
      email,
      passwordHash,
      role
    };

    // Add role-specific fields
    if (role === 'patient') {
      userData.age = age;
    } else if (role === 'doctor') {
      userData.specialization = specialization;
    }

    // Create new user
    const user = new User(userData);

    await user.save();

    // Return success response (exclude password)
    const responseUser = {
      id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt
    };

    // Add role-specific fields to response
    if (role === 'patient') {
      responseUser.age = user.age;
    } else if (role === 'doctor') {
      responseUser.specialization = user.specialization;
    }

    res.status(201).json({
      message: 'User registered successfully',
      user: responseUser
    });

  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({
      message: 'Server error during registration'
    });
  }
});

// Login route
router.post('/login', [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please enter a valid email'),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { email, password } = req.body;

    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({
        message: 'Invalid email or password'
      });
    }

    // Compare password
    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      return res.status(401).json({
        message: 'Invalid email or password'
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        id: user._id,
        email: user.email,
        role: user.role 
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    // Return success response with token and user info
    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      message: 'Server error during login'
    });
  }
});

module.exports = router;