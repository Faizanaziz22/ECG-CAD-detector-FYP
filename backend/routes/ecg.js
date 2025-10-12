const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const jwt = require('jsonwebtoken');
const PDFGenerator = require('../services/pdf_generator');

const router = express.Router();
const JWT_SECRET = 'test_secret_key';
const pdfGenerator = new PDFGenerator();

// Import notification service - will be injected from main app
let notificationService = null;

// Authentication middleware
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

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../uploads/ecg');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, `ecg-${uniqueSuffix}${path.extname(file.originalname)}`);
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    // Accept common ECG file formats
    const allowedTypes = ['.txt', '.csv', '.dat', '.xml', '.json'];
    const fileExt = path.extname(file.originalname).toLowerCase();
    if (allowedTypes.includes(fileExt)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only ECG data files are allowed.'));
    }
  }
});

// In-memory storage for demo (replace with database in production)
let ecgRecords = [];
let recordIdCounter = 1;

// Simulate AI analysis function
function simulateAIAnalysis(filePath) {
  // Simulate processing delay
  const classifications = ['Normal', 'Abnormal', 'Atrial Fibrillation', 'Bradycardia', 'Tachycardia'];
  const randomClassification = classifications[Math.floor(Math.random() * classifications.length)];
  const confidence = Math.floor(Math.random() * 30) + 70; // 70-100%
  
  let summary = '';
  switch (randomClassification) {
    case 'Normal':
      summary = 'ECG shows normal sinus rhythm with regular intervals and normal wave morphology.';
      break;
    case 'Abnormal':
      summary = 'ECG shows irregular patterns that require further medical evaluation.';
      break;
    case 'Atrial Fibrillation':
      summary = 'ECG indicates atrial fibrillation with irregular R-R intervals and absent P waves.';
      break;
    case 'Bradycardia':
      summary = 'ECG shows bradycardia with heart rate below 60 beats per minute.';
      break;
    case 'Tachycardia':
      summary = 'ECG shows tachycardia with heart rate above 100 beats per minute.';
      break;
  }

  return {
    classification: randomClassification,
    confidence: confidence,
    summary: summary,
    analysisDate: new Date().toISOString()
  };
}

// Enhanced AI analysis function with more sophisticated classification
function simulateAdvancedAIAnalysis(filePath, ecgData = null) {
  // Simulate processing delay for realistic AI analysis
  const processingDelay = Math.random() * 2000 + 1000; // 1-3 seconds
  
  // Enhanced classification categories with subcategories
  const classificationCategories = {
    'Normal': {
      subcategories: ['Normal Sinus Rhythm', 'Sinus Arrhythmia'],
      confidence: [85, 98],
      heartRateRange: [60, 100],
      riskLevel: 'low'
    },
    'Arrhythmia': {
      subcategories: ['Atrial Fibrillation', 'Atrial Flutter', 'Premature Ventricular Contractions', 'Supraventricular Tachycardia'],
      confidence: [75, 95],
      heartRateRange: [40, 180],
      riskLevel: 'medium'
    },
    'Bradycardia': {
      subcategories: ['Sinus Bradycardia', 'AV Block', 'Junctional Bradycardia'],
      confidence: [80, 96],
      heartRateRange: [30, 59],
      riskLevel: 'medium'
    },
    'Tachycardia': {
      subcategories: ['Sinus Tachycardia', 'Ventricular Tachycardia', 'Atrial Tachycardia'],
      confidence: [78, 94],
      heartRateRange: [101, 200],
      riskLevel: 'high'
    },
    'Ischemia': {
      subcategories: ['ST Elevation', 'ST Depression', 'T Wave Inversion', 'Q Wave Abnormalities'],
      confidence: [70, 92],
      heartRateRange: [50, 120],
      riskLevel: 'high'
    },
    'Conduction Abnormalities': {
      subcategories: ['Bundle Branch Block', 'AV Block', 'Prolonged QT', 'WPW Syndrome'],
      confidence: [72, 89],
      heartRateRange: [45, 110],
      riskLevel: 'medium'
    }
  };

  // Select random primary classification
  const primaryCategories = Object.keys(classificationCategories);
  const primaryClassification = primaryCategories[Math.floor(Math.random() * primaryCategories.length)];
  const categoryData = classificationCategories[primaryClassification];
  
  // Select subcategory
  const subcategory = categoryData.subcategories[Math.floor(Math.random() * categoryData.subcategories.length)];
  
  // Generate confidence score within category range
  const confidence = Math.floor(Math.random() * (categoryData.confidence[1] - categoryData.confidence[0] + 1)) + categoryData.confidence[0];
  
  // Generate heart rate within category range
  const heartRate = Math.floor(Math.random() * (categoryData.heartRateRange[1] - categoryData.heartRateRange[0] + 1)) + categoryData.heartRateRange[0];
  
  // Generate detailed intervals and measurements
  const intervals = {
    PR: Math.floor(Math.random() * 80 + 120), // 120-200ms normal
    QRS: Math.floor(Math.random() * 40 + 80), // 80-120ms normal
    QT: Math.floor(Math.random() * 100 + 350), // 350-450ms normal
    QTc: Math.floor(Math.random() * 100 + 380), // Corrected QT
    RR: Math.floor(60000 / heartRate) // R-R interval in ms
  };

  // Generate axis deviation
  const axisDeviations = ['Normal', 'Left Axis Deviation', 'Right Axis Deviation', 'Extreme Axis Deviation'];
  const axis = axisDeviations[Math.floor(Math.random() * axisDeviations.length)];

  // Generate rhythm characteristics
  const rhythmTypes = ['Regular', 'Irregular', 'Regularly Irregular', 'Irregularly Irregular'];
  const rhythm = rhythmTypes[Math.floor(Math.random() * rhythmTypes.length)];

  // Generate detailed summary based on classification
  let summary = '';
  let recommendations = [];
  let urgencyLevel = 'routine';

  switch (primaryClassification) {
    case 'Normal':
      summary = `ECG demonstrates ${subcategory.toLowerCase()} with heart rate of ${heartRate} bpm. All intervals are within normal limits. No acute abnormalities detected.`;
      recommendations = [
        'Continue routine cardiac monitoring',
        'Maintain healthy lifestyle',
        'Regular follow-up as clinically indicated'
      ];
      urgencyLevel = 'routine';
      break;
      
    case 'Arrhythmia':
      summary = `ECG shows evidence of ${subcategory.toLowerCase()} with ventricular rate of ${heartRate} bpm. ${rhythm} rhythm pattern observed. Consider anticoagulation assessment if atrial fibrillation confirmed.`;
      recommendations = [
        'Cardiology consultation recommended',
        'Consider Holter monitoring',
        'Evaluate for anticoagulation therapy',
        'Monitor symptoms and vital signs'
      ];
      urgencyLevel = subcategory.includes('Ventricular') ? 'urgent' : 'priority';
      break;
      
    case 'Bradycardia':
      summary = `ECG demonstrates ${subcategory.toLowerCase()} with heart rate of ${heartRate} bpm. Assess for hemodynamic compromise and underlying causes.`;
      recommendations = [
        'Evaluate for symptomatic bradycardia',
        'Consider pacemaker evaluation if symptomatic',
        'Review medications affecting heart rate',
        'Monitor for signs of hemodynamic instability'
      ];
      urgencyLevel = heartRate < 40 ? 'urgent' : 'priority';
      break;
      
    case 'Tachycardia':
      summary = `ECG shows ${subcategory.toLowerCase()} with heart rate of ${heartRate} bpm. Evaluate for underlying triggers and hemodynamic stability.`;
      recommendations = [
        'Assess hemodynamic stability',
        'Identify and treat underlying causes',
        'Consider rate control measures',
        'Monitor for signs of cardiac compromise'
      ];
      urgencyLevel = heartRate > 150 || subcategory.includes('Ventricular') ? 'urgent' : 'priority';
      break;
      
    case 'Ischemia':
      summary = `ECG findings suggestive of ${subcategory.toLowerCase()}. Immediate cardiology evaluation recommended to rule out acute coronary syndrome.`;
      recommendations = [
        'URGENT: Cardiology consultation',
        'Serial cardiac enzymes',
        'Continuous cardiac monitoring',
        'Consider emergency catheterization'
      ];
      urgencyLevel = 'urgent';
      break;
      
    case 'Conduction Abnormalities':
      summary = `ECG demonstrates ${subcategory.toLowerCase()}. QRS duration ${intervals.QRS}ms, PR interval ${intervals.PR}ms. Clinical correlation recommended.`;
      recommendations = [
        'Cardiology consultation for conduction system evaluation',
        'Consider electrophysiology referral if symptomatic',
        'Monitor for progression of conduction abnormalities',
        'Evaluate need for pacemaker therapy'
      ];
      urgencyLevel = subcategory.includes('AV Block') ? 'priority' : 'routine';
      break;
  }

  // Generate additional findings
  const additionalFindings = [];
  if (Math.random() > 0.7) {
    const findings = [
      'Left ventricular hypertrophy criteria met',
      'Right atrial enlargement suggested',
      'Non-specific ST-T wave changes',
      'Early repolarization pattern',
      'Low voltage in limb leads',
      'Incomplete right bundle branch block'
    ];
    additionalFindings.push(findings[Math.floor(Math.random() * findings.length)]);
  }

  // Calculate risk stratification
  const riskFactors = {
    age: Math.random() > 0.5,
    diabetes: Math.random() > 0.8,
    hypertension: Math.random() > 0.6,
    smoking: Math.random() > 0.7,
    familyHistory: Math.random() > 0.8
  };

  const riskScore = Object.values(riskFactors).filter(Boolean).length;
  let overallRisk = 'Low';
  if (riskScore >= 3 || categoryData.riskLevel === 'high') overallRisk = 'High';
  else if (riskScore >= 2 || categoryData.riskLevel === 'medium') overallRisk = 'Moderate';

  return {
    classification: primaryClassification,
    subcategory: subcategory,
    confidence: confidence,
    summary: summary,
    heartRate: heartRate,
    rhythm: rhythm,
    axis: axis,
    intervals: {
      PR: `${intervals.PR} ms`,
      QRS: `${intervals.QRS} ms`,
      QT: `${intervals.QT} ms`,
      QTc: `${intervals.QTc} ms`,
      RR: `${intervals.RR} ms`
    },
    measurements: {
      heartRate: `${heartRate} bpm`,
      rhythm: rhythm,
      axis: axis,
      intervals: intervals
    },
    findings: {
      primary: `${primaryClassification}: ${subcategory}`,
      additional: additionalFindings,
      riskLevel: categoryData.riskLevel,
      overallRisk: overallRisk,
      urgencyLevel: urgencyLevel
    },
    recommendations: recommendations,
    technicalQuality: {
      signalQuality: Math.random() > 0.2 ? 'Good' : 'Fair',
      artifactLevel: Math.random() > 0.8 ? 'Minimal' : 'None',
      interpretability: Math.random() > 0.1 ? 'Excellent' : 'Good'
    },
    analysisMetadata: {
      modelVersion: '2.1.0',
      analysisDate: new Date().toISOString(),
      processingTime: `${(Math.random() * 2 + 1).toFixed(2)}s`,
      algorithmConfidence: confidence,
      reviewRequired: urgencyLevel !== 'routine' || confidence < 85
    }
  };
}

// POST /api/ecg/upload - Upload ECG file
router.post('/upload', authenticateToken, upload.single('ecgFile'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No ECG file uploaded' });
    }

    const { recordingType = 'upload', notes = '' } = req.body;
    
    // Use enhanced AI analysis
    const aiAnalysis = simulateAdvancedAIAnalysis(req.file.path);
    
    // Create ECG record
    const ecgRecord = {
      id: recordIdCounter++,
      userId: req.user.id,
      fileName: req.file.originalname,
      filePath: req.file.path,
      fileSize: req.file.size,
      recordingType: recordingType, // 'upload' or 'recorded'
      uploadDate: new Date().toISOString(),
      notes: notes,
      aiAnalysis: aiAnalysis,
      doctorReview: null,
      status: 'analyzed' // 'pending', 'analyzed', 'reviewed'
    };

    ecgRecords.push(ecgRecord);

    // Create notification for ECG analysis completion
    if (notificationService) {
      notificationService.createECGReportReadyNotification(req.user.id, ecgRecord.id, ecgRecord.fileName);
    }

    res.status(201).json({
      message: 'ECG file uploaded and analyzed successfully',
      record: {
        id: ecgRecord.id,
        fileName: ecgRecord.fileName,
        uploadDate: ecgRecord.uploadDate,
        aiAnalysis: ecgRecord.aiAnalysis,
        status: ecgRecord.status
      }
    });

  } catch (error) {
    console.error('ECG upload error:', error);
    res.status(500).json({ error: 'Failed to upload and analyze ECG file' });
  }
});

// POST /api/ecg/record - Simulate ECG recording
router.post('/record', authenticateToken, async (req, res) => {
  try {
    const { duration = 30, notes = '' } = req.body;
    
    // Simulate recording process
    const simulatedData = {
      duration: duration,
      sampleRate: 500,
      channels: 12,
      dataPoints: duration * 500 * 12
    };

    // Use enhanced AI analysis
    const aiAnalysis = simulateAdvancedAIAnalysis(null, simulatedData);
    
    // Create ECG record
    const ecgRecord = {
      id: recordIdCounter++,
      userId: req.user.id,
      fileName: `recorded-ecg-${Date.now()}.json`,
      filePath: null, // No actual file for simulated recording
      fileSize: JSON.stringify(simulatedData).length,
      recordingType: 'recorded',
      uploadDate: new Date().toISOString(),
      notes: notes,
      simulatedData: simulatedData,
      aiAnalysis: aiAnalysis,
      doctorReview: null,
      status: 'analyzed'
    };

    ecgRecords.push(ecgRecord);

    // Create notification for ECG recording completion
    if (notificationService) {
      notificationService.createECGReportReadyNotification(req.user.id, ecgRecord.id, ecgRecord.fileName);
    }

    res.status(201).json({
      message: 'ECG recording completed and analyzed successfully',
      record: {
        id: ecgRecord.id,
        fileName: ecgRecord.fileName,
        uploadDate: ecgRecord.uploadDate,
        duration: duration,
        aiAnalysis: ecgRecord.aiAnalysis,
        status: ecgRecord.status
      }
    });

  } catch (error) {
    console.error('ECG recording error:', error);
    res.status(500).json({ error: 'Failed to record and analyze ECG' });
  }
});

// GET /api/ecg/history - Get user's ECG history
router.get('/history', authenticateToken, (req, res) => {
  try {
    const userRecords = ecgRecords
      .filter(record => record.userId === req.user.id)
      .map(record => ({
        id: record.id,
        fileName: record.fileName,
        recordingType: record.recordingType,
        uploadDate: record.uploadDate,
        aiAnalysis: {
          classification: record.aiAnalysis.classification,
          confidence: record.aiAnalysis.confidence
        },
        status: record.status,
        hasReview: !!record.doctorReview
      }))
      .sort((a, b) => new Date(b.uploadDate) - new Date(a.uploadDate));

    res.json({
      message: 'ECG history retrieved successfully',
      records: userRecords,
      total: userRecords.length
    });

  } catch (error) {
    console.error('ECG history error:', error);
    res.status(500).json({ error: 'Failed to retrieve ECG history' });
  }
});

// GET /api/ecg/report/:id - Get detailed ECG report
router.get('/report/:id', authenticateToken, (req, res) => {
  try {
    const recordId = parseInt(req.params.id);
    const record = ecgRecords.find(r => r.id === recordId && r.userId === req.user.id);

    if (!record) {
      return res.status(404).json({ error: 'ECG record not found' });
    }

    const detailedReport = {
      id: record.id,
      fileName: record.fileName,
      recordingType: record.recordingType,
      uploadDate: record.uploadDate,
      fileSize: record.fileSize,
      notes: record.notes,
      aiAnalysis: record.aiAnalysis,
      doctorReview: record.doctorReview,
      status: record.status
    };

    if (record.simulatedData) {
      detailedReport.recordingDetails = record.simulatedData;
    }

    res.json({
      message: 'ECG report retrieved successfully',
      report: detailedReport
    });

  } catch (error) {
    console.error('ECG report error:', error);
    res.status(500).json({ error: 'Failed to retrieve ECG report' });
  }
});

// POST /api/ecg/report/:id/pdf - Generate PDF report
router.post('/report/:id/pdf', authenticateToken, async (req, res) => {
  try {
    const recordId = parseInt(req.params.id);
    const record = ecgRecords.find(r => r.id === recordId && r.userId === req.user.id);
    
    if (!record) {
      return res.status(404).json({ error: 'ECG record not found' });
    }
    
    // Generate PDF report
    const pdfResult = await pdfGenerator.generateECGReport(record);
    
    res.json({
      success: true,
      pdf: {
        fileName: pdfResult.fileName,
        size: pdfResult.size,
        downloadUrl: `/api/ecg/download/${pdfResult.fileName}`
      }
    });
  } catch (error) {
    console.error('Error generating PDF report:', error);
    res.status(500).json({ error: 'Failed to generate PDF report' });
  }
});

// GET /api/ecg/download/:fileName - Download PDF report
router.get('/download/:fileName', authenticateToken, async (req, res) => {
  try {
    const { fileName } = req.params;
    const filePath = await pdfGenerator.getReportPath(fileName);
    
    // Check if file exists
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: 'Report file not found' });
    }
    
    // Set headers for PDF download
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
    
    // Stream the file
    const fileStream = fs.createReadStream(filePath);
    fileStream.pipe(res);
    
  } catch (error) {
    console.error('Error downloading PDF report:', error);
    res.status(500).json({ error: 'Failed to download PDF report' });
  }
});

// POST /api/ecg/request-review - Request doctor review
router.post('/request-review', authenticateToken, (req, res) => {
  try {
    const { recordId, message = '' } = req.body;

    if (!recordId) {
      return res.status(400).json({ error: 'Record ID is required' });
    }

    const record = ecgRecords.find(r => r.id === recordId && r.userId === req.user.id);

    if (!record) {
      return res.status(404).json({ error: 'ECG record not found' });
    }

    // Update record with review request
    record.reviewRequest = {
      requestDate: new Date().toISOString(),
      message: message,
      status: 'pending' // 'pending', 'in_review', 'completed'
    };

    record.status = 'review_requested';

    res.json({
      message: 'Doctor review requested successfully',
      recordId: recordId,
      requestDate: record.reviewRequest.requestDate
    });

  } catch (error) {
    console.error('Review request error:', error);
    res.status(500).json({ error: 'Failed to request doctor review' });
  }
});

// GET /api/ecg/pending-reviews - Get pending reviews (for doctors)
router.get('/pending-reviews', authenticateToken, (req, res) => {
  try {
    // Only allow doctors to access this endpoint
    if (req.user.role !== 'doctor') {
      return res.status(403).json({ error: 'Access denied. Doctor role required.' });
    }

    const pendingReviews = ecgRecords
      .filter(record => record.reviewRequest && record.reviewRequest.status === 'pending')
      .map(record => ({
        id: record.id,
        patientId: record.userId,
        fileName: record.fileName,
        recordingType: record.recordingType,
        uploadDate: record.uploadDate,
        aiAnalysis: record.aiAnalysis,
        reviewRequest: record.reviewRequest
      }))
      .sort((a, b) => new Date(a.reviewRequest.requestDate) - new Date(b.reviewRequest.requestDate));

    res.json({
      message: 'Pending reviews retrieved successfully',
      reviews: pendingReviews,
      total: pendingReviews.length
    });

  } catch (error) {
    console.error('Pending reviews error:', error);
    res.status(500).json({ error: 'Failed to retrieve pending reviews' });
  }
});

// POST /api/ecg/submit-review - Submit doctor review
router.post('/submit-review', authenticateToken, (req, res) => {
  try {
    // Only allow doctors to submit reviews
    if (req.user.role !== 'doctor') {
      return res.status(403).json({ error: 'Access denied. Doctor role required.' });
    }

    const { recordId, diagnosis, recommendations, severity } = req.body;

    if (!recordId || !diagnosis) {
      return res.status(400).json({ error: 'Record ID and diagnosis are required' });
    }

    const record = ecgRecords.find(r => r.id === recordId);

    if (!record) {
      return res.status(404).json({ error: 'ECG record not found' });
    }

    // Add doctor review
    record.doctorReview = {
      doctorId: req.user.id,
      doctorName: req.user.name,
      reviewDate: new Date().toISOString(),
      diagnosis: diagnosis,
      recommendations: recommendations || '',
      severity: severity || 'normal', // 'normal', 'mild', 'moderate', 'severe'
      status: 'completed'
    };

    // Update review request status
    if (record.reviewRequest) {
      record.reviewRequest.status = 'completed';
    }

    record.status = 'reviewed';

    // Create notification for doctor feedback
    if (notificationService) {
      notificationService.createDoctorFeedbackNotification(
        record.userId, 
        recordId, 
        record.fileName, 
        req.user.name
      );
    }

    res.json({
      message: 'Doctor review submitted successfully',
      recordId: recordId,
      reviewDate: record.doctorReview.reviewDate
    });

  } catch (error) {
    console.error('Submit review error:', error);
    res.status(500).json({ error: 'Failed to submit doctor review' });
  }
});

// Function to inject notification service
router.setNotificationService = (service) => {
  notificationService = service;
};

// Function to get ECG records for other modules
router.getECGRecords = () => {
  return ecgRecords;
};

module.exports = router;