const mongoose = require('mongoose');

const ecgRecordSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User ID is required']
  },
  fileName: {
    type: String,
    required: [true, 'File name is required'],
    trim: true
  },
  originalFileName: {
    type: String,
    required: [true, 'Original file name is required'],
    trim: true
  },
  filePath: {
    type: String,
    required: [true, 'File path is required']
  },
  fileSize: {
    type: Number,
    required: [true, 'File size is required']
  },
  mimeType: {
    type: String,
    required: [true, 'MIME type is required']
  },
  uploadTime: {
    type: Date,
    default: Date.now
  },
  recordingDuration: {
    type: Number, // in seconds
    min: [0, 'Recording duration cannot be negative']
  },
  sampleRate: {
    type: Number, // Hz
    min: [0, 'Sample rate cannot be negative']
  },
  leads: [{
    name: {
      type: String,
      required: true
    },
    data: [Number] // ECG signal data points
  }],
  analysis: {
    classification: {
      type: String,
      enum: [
        'Normal Sinus Rhythm',
        'Atrial Fibrillation',
        'Premature Ventricular Contractions',
        'Sinus Bradycardia',
        'Sinus Tachycardia',
        'Ventricular Tachycardia',
        'Atrial Flutter',
        'Supraventricular Tachycardia',
        'Pending Analysis',
        'Analysis Failed'
      ],
      default: 'Pending Analysis'
    },
    confidence: {
      type: Number,
      min: [0, 'Confidence cannot be negative'],
      max: [1, 'Confidence cannot exceed 1'],
      default: 0
    },
    heartRate: {
      type: Number,
      min: [0, 'Heart rate cannot be negative'],
      max: [300, 'Heart rate seems too high']
    },
    rhythm: {
      type: String,
      enum: ['Regular', 'Irregular', 'Unknown'],
      default: 'Unknown'
    },
    pWave: {
      present: { type: Boolean, default: null },
      morphology: { type: String, default: '' }
    },
    qrsComplex: {
      duration: { type: Number, default: null }, // in ms
      morphology: { type: String, default: '' }
    },
    tWave: {
      present: { type: Boolean, default: null },
      morphology: { type: String, default: '' }
    },
    intervals: {
      pr: { type: Number, default: null }, // in ms
      qt: { type: Number, default: null }, // in ms
      qtc: { type: Number, default: null } // corrected QT
    },
    analysisDate: {
      type: Date,
      default: Date.now
    },
    aiModel: {
      name: { type: String, default: 'ECG-CAD-Detector' },
      version: { type: String, default: '1.0' }
    },
    rawOutput: mongoose.Schema.Types.Mixed // Store raw AI model output
  },
  status: {
    type: String,
    enum: ['uploaded', 'processing', 'analyzed', 'error'],
    default: 'uploaded'
  },
  tags: [String],
  notes: {
    type: String,
    maxlength: [1000, 'Notes cannot exceed 1000 characters']
  },
  isDeleted: {
    type: Boolean,
    default: false
  },
  metadata: {
    deviceInfo: {
      type: String,
      default: ''
    },
    recordingConditions: {
      type: String,
      default: ''
    },
    patientPosition: {
      type: String,
      enum: ['Supine', 'Sitting', 'Standing', 'Unknown'],
      default: 'Unknown'
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for formatted upload time
ecgRecordSchema.virtual('formattedUploadTime').get(function() {
  return this.uploadTime.toLocaleDateString() + ' ' + this.uploadTime.toLocaleTimeString();
});

// Virtual for analysis summary
ecgRecordSchema.virtual('analysisSummary').get(function() {
  if (!this.analysis || !this.analysis.classification) {
    return 'Analysis pending';
  }
  
  const confidence = this.analysis.confidence ? 
    `${(this.analysis.confidence * 100).toFixed(1)}%` : 'N/A';
  
  return `${this.analysis.classification} (${confidence} confidence)`;
});

// Indexes for better query performance
ecgRecordSchema.index({ userId: 1, uploadTime: -1 });
ecgRecordSchema.index({ 'analysis.classification': 1 });
ecgRecordSchema.index({ status: 1 });
ecgRecordSchema.index({ createdAt: -1 });

// Pre-save middleware
ecgRecordSchema.pre('save', function(next) {
  // Update status based on analysis
  if (this.analysis && this.analysis.classification && this.analysis.classification !== 'Pending Analysis') {
    if (this.status === 'uploaded' || this.status === 'processing') {
      this.status = 'analyzed';
    }
  }
  
  next();
});

// Static methods
ecgRecordSchema.statics.findByUser = function(userId, options = {}) {
  const query = { userId, isDeleted: false };
  
  if (options.status) {
    query.status = options.status;
  }
  
  if (options.classification) {
    query['analysis.classification'] = options.classification;
  }
  
  return this.find(query)
    .populate('userId', 'name email')
    .sort({ uploadTime: -1 });
};

ecgRecordSchema.statics.getAnalyticsForUser = function(userId) {
  return this.aggregate([
    { $match: { userId: mongoose.Types.ObjectId(userId), isDeleted: false } },
    {
      $group: {
        _id: '$analysis.classification',
        count: { $sum: 1 },
        avgConfidence: { $avg: '$analysis.confidence' },
        avgHeartRate: { $avg: '$analysis.heartRate' }
      }
    },
    { $sort: { count: -1 } }
  ]);
};

// Instance methods
ecgRecordSchema.methods.updateAnalysis = function(analysisData) {
  this.analysis = { ...this.analysis, ...analysisData };
  this.analysis.analysisDate = new Date();
  return this.save();
};

module.exports = mongoose.model('ECGRecord', ecgRecordSchema);