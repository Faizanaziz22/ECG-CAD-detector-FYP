const mongoose = require('mongoose');
require('dotenv').config();

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      maxPoolSize: 10, // Maintain up to 10 socket connections
      serverSelectionTimeoutMS: 5000, // Keep trying to send operations for 5 seconds
      socketTimeoutMS: 45000, // Close sockets after 45 seconds of inactivity
      family: 4 // Use IPv4, skip trying IPv6
    });

    console.log(`MongoDB Connected: ${conn.connection.host}`);
    
    // Handle connection events
    mongoose.connection.on('connected', () => {
      console.log('Mongoose connected to MongoDB');
    });

    mongoose.connection.on('error', (err) => {
      console.error('Mongoose connection error:', err);
    });

    mongoose.connection.on('disconnected', () => {
      console.log('Mongoose disconnected from MongoDB');
    });

    // Handle application termination
    process.on('SIGINT', async () => {
      try {
        await mongoose.connection.close();
        console.log('MongoDB connection closed through app termination');
        process.exit(0);
      } catch (err) {
        console.error('Error closing MongoDB connection:', err);
        process.exit(1);
      }
    });

  } catch (error) {
    console.error('Database connection failed:', error.message);
    throw error; // Don't retry, let the server start without database
  }
};

// Health check function
const checkDBHealth = async () => {
  try {
    const state = mongoose.connection.readyState;
    const states = {
      0: 'disconnected',
      1: 'connected',
      2: 'connecting',
      3: 'disconnecting'
    };
    
    return {
      status: states[state] || 'unknown',
      host: mongoose.connection.host,
      name: mongoose.connection.name,
      collections: Object.keys(mongoose.connection.collections).length
    };
  } catch (error) {
    return {
      status: 'error',
      error: error.message
    };
  }
};

// Initialize database indexes
const initializeIndexes = async () => {
  try {
    console.log('Initializing database indexes...');
    
    // Get all models and ensure indexes
    const models = mongoose.modelNames();
    
    for (const modelName of models) {
      const Model = mongoose.model(modelName);
      await Model.ensureIndexes();
      console.log(`Indexes ensured for ${modelName}`);
    }
    
    console.log('All database indexes initialized successfully');
  } catch (error) {
    console.error('Error initializing database indexes:', error);
  }
};

// Seed initial data (for development)
const seedInitialData = async () => {
  try {
    const User = mongoose.model('User');
    
    // Check if admin user exists
    const adminExists = await User.findOne({ email: 'admin@ecgapp.com' });
    
    if (!adminExists) {
      const adminUser = new User({
        name: 'System Administrator',
        email: 'admin@ecgapp.com',
        password: 'admin123', // Will be hashed by pre-save middleware
        phone: '+1234567890',
        role: 'admin',
        isEmailVerified: true,
        settings: {
          notifications: {
            email: true,
            push: true,
            sms: false
          },
          privacy: {
            shareDataForResearch: false,
            allowMarketing: false
          },
          preferences: {
            language: 'en',
            timezone: 'UTC',
            dateFormat: 'MM/DD/YYYY',
            theme: 'light'
          }
        }
      });
      
      await adminUser.save();
      console.log('Admin user created successfully');
    }
    
    // Create default admin user if it doesn't exist
    const adminExists = await User.findOne({ email: 'admin@ecgapp.com' });
    
    if (!adminExists) {
      const adminUser = new User({
        name: 'Admin User',
        email: 'admin@ecgapp.com',
        password: 'admin123', // Will be hashed by pre-save middleware
        phone: '+1234567890',
        role: 'admin',
        settings: {
          notificationsEnabled: true,
          emailNotifications: true,
          smsNotifications: false,
          emergencyContacts: [],
          privacySettings: {
            shareDataForResearch: false,
            allowAnonymousAnalytics: true
          }
        },
        isEmailVerified: true,
        createdAt: new Date(),
        updatedAt: new Date()
      });

      await adminUser.save();
      console.log('Admin user created successfully');
    }
    
  } catch (error) {
    console.error('Error seeding initial data:', error);
  }
};

module.exports = {
  connectDB,
  checkDBHealth,
  initializeIndexes,
  seedInitialData
};