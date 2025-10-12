const express = require('express');
const { auth, authorize } = require('../middleware/auth');

const router = express.Router();

// Protected route for patient dashboard
router.get('/dashboard', auth, authorize(['patient']), async (req, res) => {
  try {
    res.json({
      message: 'Welcome to Patient Dashboard',
      user: {
        id: req.user.id,
        name: req.user.name,
        email: req.user.email,
        role: req.user.role
      },
      data: {
        appointments: [],
        prescriptions: [],
        medicalHistory: []
      }
    });
  } catch (error) {
    console.error('Patient dashboard error:', error);
    res.status(500).json({
      message: 'Server error accessing patient dashboard'
    });
  }
});

// Additional patient routes can be added here
router.get('/profile', auth, authorize(['patient']), async (req, res) => {
  try {
    res.json({
      message: 'Patient profile data',
      user: req.user
    });
  } catch (error) {
    console.error('Patient profile error:', error);
    res.status(500).json({
      message: 'Server error accessing patient profile'
    });
  }
});

module.exports = router;