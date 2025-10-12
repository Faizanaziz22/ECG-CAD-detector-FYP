const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    minlength: [2, 'Name must be at least 2 characters long']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  passwordHash: {
    type: String,
    required: [true, 'Password is required']
  },
  role: {
    type: String,
    required: [true, 'Role is required'],
    enum: ['patient', 'doctor'],
    default: 'patient'
  },
  // Age field for patients
  age: {
    type: Number,
    required: function() {
      return this.role === 'patient';
    },
    min: [1, 'Age must be at least 1'],
    max: [120, 'Age must be at most 120']
  },
  // Specialization field for doctors
  specialization: {
    type: String,
    required: function() {
      return this.role === 'doctor';
    },
    enum: [
      'Cardiologist',
      'Interventional Cardiologist',
      'Cardiac Surgeon',
      'Preventive Cardiologist',
      'Cardiac Rehabilitation Specialist',
      'Cardiac Imaging Specialist',
      'Internal Medicine Specialist'
    ]
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Index for faster email lookups
userSchema.index({ email: 1 });

module.exports = mongoose.model('User', userSchema);