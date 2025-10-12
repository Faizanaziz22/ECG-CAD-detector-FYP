const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const ECGRecord = require('../models/ECGRecord');
const { authenticateToken, requireOwnership, logActivity } = require('../middleware/auth');
const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../uploads/ecg');
    try {
      await fs.mkdir(uploadDir, { recursive: true });
      cb(null, uploadDir);
    } catch (error) {
      cb(error);
    }
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = path.extname(file.originalname);
    cb(null, `ecg-${uniqueSuffix}${extension}`);
  }
});

const fileFilter = (req, file, cb) => {
  // Accept common ECG file formats
  const allowedTypes = [
    'text/plain', // .txt
    'text/csv', // .csv
    'application/json', // .json
    'application/xml', // .xml
    'text/xml', // .xml
    'application/octet-stream' // Binary ECG formats
  ];
  
  const allowedExtensions = ['.txt', '.csv', '.json', '.xml', '.ecg', '.dat'];
  const fileExtension = path.extname(file.originalname).toLowerCase();
  
  if (allowedTypes.includes(file.mimetype) || allowedExtensions.includes(fileExtension)) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only ECG data files are allowed.'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  }
});

// Upload ECG file
router.post('/upload', authenticateToken, upload.single('ecgFile'), logActivity('ECG_UPLOAD'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'ECG file is required'
      });
    }

    const {
      recordingDate,
      symptoms,
      notes,
      deviceInfo,
      recordingDuration,
      sampleRate,
      leads
    } = req.body;

    // Parse device info if it's a string
    let parsedDeviceInfo = {};
    if (deviceInfo) {
      try {
        parsedDeviceInfo = typeof deviceInfo === 'string' ? JSON.parse(deviceInfo) : deviceInfo;
      } catch (error) {
        console.warn('Invalid device info format:', error);
      }
    }

    // Create ECG record
    const ecgRecord = new ECGRecord({
      userId: req.user._id,
      fileName: req.file.originalname,
      filePath: req.file.path,
      fileSize: req.file.size,
      mimeType: req.file.mimetype,
      recordingDate: recordingDate ? new Date(recordingDate) : new Date(),
      symptoms: symptoms ? symptoms.split(',').map(s => s.trim()) : [],
      notes,
      deviceInfo: parsedDeviceInfo,
      recordingMetrics: {
        duration: recordingDuration ? parseInt(recordingDuration) : null,
        sampleRate: sampleRate ? parseInt(sampleRate) : null,
        leads: leads ? parseInt(leads) : 12
      }
    });

    await ecgRecord.save();

    // Start analysis (in a real app, this would be async)
    try {
      const analysisResult = await analyzeECG(req.file.path, ecgRecord._id);
      ecgRecord.analysis = analysisResult;
      ecgRecord.status = 'analyzed';
      await ecgRecord.save();
    } catch (analysisError) {
      console.error('ECG analysis failed:', analysisError);
      ecgRecord.status = 'analysis_failed';
      ecgRecord.analysis.error = analysisError.message;
      await ecgRecord.save();
    }

    res.status(201).json({
      success: true,
      message: 'ECG file uploaded successfully',
      data: {
        ecgRecord: {
          id: ecgRecord._id,
          fileName: ecgRecord.fileName,
          uploadTime: ecgRecord.uploadTime,
          status: ecgRecord.status,
          analysis: ecgRecord.analysis
        }
      }
    });
  } catch (error) {
    console.error('ECG upload error:', error);
    
    // Clean up uploaded file if record creation failed
    if (req.file) {
      try {
        await fs.unlink(req.file.path);
      } catch (unlinkError) {
        console.error('Failed to clean up uploaded file:', unlinkError);
      }
    }

    if (error.name === 'ValidationError') {
      const errors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors
      });
    }

    res.status(500).json({
      success: false,
      message: 'ECG upload failed'
    });
  }
});

// Get user's ECG records
router.get('/records', authenticateToken, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      startDate,
      endDate,
      sortBy = 'uploadTime',
      sortOrder = 'desc'
    } = req.query;

    // Build query
    const query = { userId: req.user._id, isDeleted: false };

    if (status) {
      query.status = status;
    }

    if (startDate || endDate) {
      query.uploadTime = {};
      if (startDate) query.uploadTime.$gte = new Date(startDate);
      if (endDate) query.uploadTime.$lte = new Date(endDate);
    }

    // Build sort object
    const sort = {};
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1;

    // Execute query with pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    const [records, total] = await Promise.all([
      ECGRecord.find(query)
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit))
        .select('-filePath'), // Don't expose file paths
      ECGRecord.countDocuments(query)
    ]);

    res.json({
      success: true,
      data: {
        records,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
          totalRecords: total,
          hasNext: skip + records.length < total,
          hasPrev: parseInt(page) > 1
        }
      }
    });
  } catch (error) {
    console.error('Get ECG records error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get ECG records'
    });
  }
});

// Get specific ECG record
router.get('/records/:recordId', authenticateToken, async (req, res) => {
  try {
    const record = await ECGRecord.findOne({
      _id: req.params.recordId,
      userId: req.user._id,
      isDeleted: false
    }).select('-filePath');

    if (!record) {
      return res.status(404).json({
        success: false,
        message: 'ECG record not found'
      });
    }

    res.json({
      success: true,
      data: { record }
    });
  } catch (error) {
    console.error('Get ECG record error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get ECG record'
    });
  }
});

// Update ECG record
router.put('/records/:recordId', authenticateToken, async (req, res) => {
  try {
    const allowedUpdates = ['symptoms', 'notes', 'tags'];
    const updates = {};

    Object.keys(req.body).forEach(key => {
      if (allowedUpdates.includes(key)) {
        if (key === 'symptoms' && typeof req.body[key] === 'string') {
          updates[key] = req.body[key].split(',').map(s => s.trim());
        } else {
          updates[key] = req.body[key];
        }
      }
    });

    const record = await ECGRecord.findOneAndUpdate(
      {
        _id: req.params.recordId,
        userId: req.user._id,
        isDeleted: false
      },
      { $set: updates },
      { new: true, runValidators: true }
    ).select('-filePath');

    if (!record) {
      return res.status(404).json({
        success: false,
        message: 'ECG record not found'
      });
    }

    res.json({
      success: true,
      message: 'ECG record updated successfully',
      data: { record }
    });
  } catch (error) {
    console.error('Update ECG record error:', error);
    
    if (error.name === 'ValidationError') {
      const errors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors
      });
    }

    res.status(500).json({
      success: false,
      message: 'ECG record update failed'
    });
  }
});

// Delete ECG record (soft delete)
router.delete('/records/:recordId', authenticateToken, logActivity('ECG_DELETE'), async (req, res) => {
  try {
    const record = await ECGRecord.findOneAndUpdate(
      {
        _id: req.params.recordId,
        userId: req.user._id,
        isDeleted: false
      },
      { isDeleted: true },
      { new: true }
    );

    if (!record) {
      return res.status(404).json({
        success: false,
        message: 'ECG record not found'
      });
    }

    res.json({
      success: true,
      message: 'ECG record deleted successfully'
    });
  } catch (error) {
    console.error('Delete ECG record error:', error);
    res.status(500).json({
      success: false,
      message: 'ECG record deletion failed'
    });
  }
});

// Get ECG analysis statistics
router.get('/stats', authenticateToken, async (req, res) => {
  try {
    const { timeframe = 30 } = req.query;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(timeframe));

    const stats = await ECGRecord.aggregate([
      {
        $match: {
          userId: req.user._id,
          uploadTime: { $gte: startDate },
          isDeleted: false
        }
      },
      {
        $group: {
          _id: null,
          totalRecords: { $sum: 1 },
          normalRecords: {
            $sum: {
              $cond: [{ $eq: ['$analysis.riskLevel', 'low'] }, 1, 0]
            }
          },
          abnormalRecords: {
            $sum: {
              $cond: [{ $ne: ['$analysis.riskLevel', 'low'] }, 1, 0]
            }
          },
          avgHeartRate: { $avg: '$analysis.heartRate' },
          recordsByStatus: {
            $push: '$status'
          }
        }
      }
    ]);

    const result = stats[0] || {
      totalRecords: 0,
      normalRecords: 0,
      abnormalRecords: 0,
      avgHeartRate: 0
    };

    res.json({
      success: true,
      data: {
        timeframe: parseInt(timeframe),
        stats: result
      }
    });
  } catch (error) {
    console.error('Get ECG stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get ECG statistics'
    });
  }
});

// Reanalyze ECG record
router.post('/records/:recordId/reanalyze', authenticateToken, async (req, res) => {
  try {
    const record = await ECGRecord.findOne({
      _id: req.params.recordId,
      userId: req.user._id,
      isDeleted: false
    });

    if (!record) {
      return res.status(404).json({
        success: false,
        message: 'ECG record not found'
      });
    }

    // Check if file still exists
    try {
      await fs.access(record.filePath);
    } catch (error) {
      return res.status(400).json({
        success: false,
        message: 'ECG file no longer available for analysis'
      });
    }

    // Reanalyze
    record.status = 'processing';
    await record.save();

    try {
      const analysisResult = await analyzeECG(record.filePath, record._id);
      record.analysis = analysisResult;
      record.status = 'analyzed';
      await record.save();

      res.json({
        success: true,
        message: 'ECG reanalysis completed',
        data: {
          analysis: record.analysis
        }
      });
    } catch (analysisError) {
      console.error('ECG reanalysis failed:', analysisError);
      record.status = 'analysis_failed';
      record.analysis.error = analysisError.message;
      await record.save();

      res.status(500).json({
        success: false,
        message: 'ECG reanalysis failed',
        error: analysisError.message
      });
    }
  } catch (error) {
    console.error('Reanalyze ECG error:', error);
    res.status(500).json({
      success: false,
      message: 'ECG reanalysis request failed'
    });
  }
});

// Mock ECG analysis function (replace with actual analysis logic)
async function analyzeECG(filePath, recordId) {
  // Simulate analysis delay
  await new Promise(resolve => setTimeout(resolve, 2000));

  // Mock analysis results
  const mockResults = [
    {
      heartRate: 72,
      rhythm: 'Normal Sinus Rhythm',
      riskLevel: 'low',
      findings: ['Normal P waves', 'Normal QRS complex', 'Normal T waves'],
      recommendations: ['Continue regular monitoring', 'Maintain healthy lifestyle']
    },
    {
      heartRate: 95,
      rhythm: 'Sinus Tachycardia',
      riskLevel: 'medium',
      findings: ['Elevated heart rate', 'Regular rhythm', 'Normal morphology'],
      recommendations: ['Monitor stress levels', 'Consider lifestyle modifications', 'Follow up if symptoms persist']
    },
    {
      heartRate: 45,
      rhythm: 'Sinus Bradycardia',
      riskLevel: 'medium',
      findings: ['Low heart rate', 'Regular rhythm', 'Normal morphology'],
      recommendations: ['Monitor for symptoms', 'Check medications', 'Consider cardiology consultation']
    }
  ];

  const randomResult = mockResults[Math.floor(Math.random() * mockResults.length)];

  return {
    ...randomResult,
    analysisDate: new Date(),
    confidence: Math.floor(Math.random() * 20) + 80, // 80-99%
    processingTime: Math.floor(Math.random() * 3000) + 1000, // 1-4 seconds
    version: '1.0.0'
  };
}

module.exports = router;