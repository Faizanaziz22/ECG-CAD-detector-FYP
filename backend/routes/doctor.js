const express = require('express');
const { auth, authorize } = require('../middleware/auth');

const router = express.Router();

// Import ECG records from ECG route (in production, this would be from database)
let ecgRecords = [];

// Function to inject ECG records reference
router.setECGRecords = (records) => {
  ecgRecords = records;
};

// Protected route for doctor dashboard
router.get('/dashboard', auth, authorize(['doctor']), async (req, res) => {
  try {
    // Get pending reviews and recent cases for dashboard
    const pendingReviews = ecgRecords.filter(record => 
      record.reviewRequest && record.reviewRequest.status === 'pending'
    );

    const recentCases = ecgRecords
      .filter(record => record.status === 'analyzed' || record.status === 'reviewed')
      .sort((a, b) => new Date(b.uploadDate) - new Date(a.uploadDate))
      .slice(0, 10);

    const urgentCases = ecgRecords.filter(record => 
      record.aiAnalysis && 
      record.aiAnalysis.findings && 
      record.aiAnalysis.findings.urgencyLevel === 'urgent'
    );

    res.json({
      message: 'Welcome to Doctor Dashboard',
      user: {
        id: req.user.id,
        name: req.user.name,
        email: req.user.email,
        role: req.user.role
      },
      data: {
        pendingReviews: pendingReviews.length,
        recentCases: recentCases.length,
        urgentCases: urgentCases.length,
        totalCases: ecgRecords.length,
        cases: recentCases.map(record => ({
          id: record.id,
          patientId: record.userId,
          fileName: record.fileName,
          uploadDate: record.uploadDate,
          aiAnalysis: record.aiAnalysis,
          status: record.status,
          hasReview: !!record.doctorReview,
          urgencyLevel: record.aiAnalysis?.findings?.urgencyLevel || 'routine'
        }))
      }
    });
  } catch (error) {
    console.error('Doctor dashboard error:', error);
    res.status(500).json({
      message: 'Server error accessing doctor dashboard'
    });
  }
});

// GET /api/doctor/cases - Get all ECG cases for review
router.get('/cases', auth, authorize(['doctor']), async (req, res) => {
  try {
    const { status, urgency, limit = 50, offset = 0 } = req.query;
    
    let filteredCases = ecgRecords;

    // Filter by status if provided
    if (status) {
      filteredCases = filteredCases.filter(record => record.status === status);
    }

    // Filter by urgency if provided
    if (urgency) {
      filteredCases = filteredCases.filter(record => 
        record.aiAnalysis?.findings?.urgencyLevel === urgency
      );
    }

    // Sort by urgency and date
    filteredCases.sort((a, b) => {
      const urgencyOrder = { urgent: 0, priority: 1, routine: 2 };
      const aUrgency = a.aiAnalysis?.findings?.urgencyLevel || 'routine';
      const bUrgency = b.aiAnalysis?.findings?.urgencyLevel || 'routine';
      
      if (urgencyOrder[aUrgency] !== urgencyOrder[bUrgency]) {
        return urgencyOrder[aUrgency] - urgencyOrder[bUrgency];
      }
      
      return new Date(b.uploadDate) - new Date(a.uploadDate);
    });

    // Apply pagination
    const paginatedCases = filteredCases
      .slice(parseInt(offset), parseInt(offset) + parseInt(limit))
      .map(record => ({
        id: record.id,
        patientId: record.userId,
        fileName: record.fileName,
        recordingType: record.recordingType,
        uploadDate: record.uploadDate,
        aiAnalysis: record.aiAnalysis,
        status: record.status,
        hasReview: !!record.doctorReview,
        reviewRequest: record.reviewRequest,
        urgencyLevel: record.aiAnalysis?.findings?.urgencyLevel || 'routine'
      }));

    res.json({
      message: 'ECG cases retrieved successfully',
      cases: paginatedCases,
      total: filteredCases.length,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset),
        hasMore: filteredCases.length > parseInt(offset) + parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Doctor cases error:', error);
    res.status(500).json({
      message: 'Server error retrieving ECG cases'
    });
  }
});

// GET /api/doctor/case/:id - Get detailed case information
router.get('/case/:id', auth, authorize(['doctor']), async (req, res) => {
  try {
    const caseId = parseInt(req.params.id);
    const record = ecgRecords.find(r => r.id === caseId);

    if (!record) {
      return res.status(404).json({ error: 'ECG case not found' });
    }

    // Return detailed case information
    const detailedCase = {
      id: record.id,
      patientId: record.userId,
      fileName: record.fileName,
      recordingType: record.recordingType,
      uploadDate: record.uploadDate,
      fileSize: record.fileSize,
      notes: record.notes,
      aiAnalysis: record.aiAnalysis,
      doctorReview: record.doctorReview,
      reviewRequest: record.reviewRequest,
      status: record.status,
      urgencyLevel: record.aiAnalysis?.findings?.urgencyLevel || 'routine'
    };

    if (record.simulatedData) {
      detailedCase.recordingDetails = record.simulatedData;
    }

    res.json({
      message: 'Case details retrieved successfully',
      case: detailedCase
    });

  } catch (error) {
    console.error('Case details error:', error);
    res.status(500).json({
      message: 'Server error retrieving case details'
    });
  }
});

// POST /api/doctor/review/:id - Submit comprehensive doctor review
router.post('/review/:id', auth, authorize(['doctor']), async (req, res) => {
  try {
    const caseId = parseInt(req.params.id);
    const {
      diagnosis,
      recommendations,
      notes,
      priority = 'normal',
      overrideAI = false,
      newClassification,
      severity = 'normal'
    } = req.body;

    if (!diagnosis) {
      return res.status(400).json({ error: 'Diagnosis is required' });
    }

    const record = ecgRecords.find(r => r.id === caseId);

    if (!record) {
      return res.status(404).json({ error: 'ECG case not found' });
    }

    // Create comprehensive doctor review
    record.doctorReview = {
      doctorId: req.user.id,
      doctorName: req.user.name,
      reviewDate: new Date().toISOString(),
      diagnosis: diagnosis,
      recommendations: recommendations || '',
      notes: notes || '',
      priority: priority,
      severity: severity,
      overrideAI: overrideAI,
      originalAIClassification: record.aiAnalysis.classification,
      newClassification: overrideAI ? newClassification : null,
      finalClassification: overrideAI ? newClassification : record.aiAnalysis.classification,
      reviewMetadata: {
        reviewDuration: Math.floor(Math.random() * 300 + 60), // 1-5 minutes
        confidence: Math.floor(Math.random() * 20 + 80), // 80-100%
        complexity: record.aiAnalysis?.findings?.urgencyLevel === 'urgent' ? 'high' : 'medium'
      },
      status: 'completed'
    };

    // Update review request status if exists
    if (record.reviewRequest) {
      record.reviewRequest.status = 'completed';
      record.reviewRequest.completedDate = new Date().toISOString();
    }

    // Update record status
    record.status = 'reviewed';

    res.json({
      message: 'Doctor review submitted successfully',
      caseId: caseId,
      review: {
        reviewDate: record.doctorReview.reviewDate,
        diagnosis: record.doctorReview.diagnosis,
        finalClassification: record.doctorReview.finalClassification,
        priority: record.doctorReview.priority
      }
    });

  } catch (error) {
    console.error('Submit review error:', error);
    res.status(500).json({ error: 'Failed to submit doctor review' });
  }
});

// POST /api/doctor/annotate/:id - Add annotation to ECG case
router.post('/annotate/:id', auth, authorize(['doctor']), async (req, res) => {
  try {
    const caseId = parseInt(req.params.id);
    const { annotation, overrideClassification } = req.body;

    if (!annotation) {
      return res.status(400).json({ error: 'Annotation is required' });
    }

    const record = ecgRecords.find(r => r.id === caseId);

    if (!record) {
      return res.status(404).json({ error: 'ECG case not found' });
    }

    // Initialize annotations array if it doesn't exist
    if (!record.annotations) {
      record.annotations = [];
    }

    // Add new annotation
    const newAnnotation = {
      id: record.annotations.length + 1,
      doctorId: req.user.id,
      doctorName: req.user.name,
      annotation: annotation,
      overrideClassification: overrideClassification,
      annotationDate: new Date().toISOString(),
      type: overrideClassification ? 'classification_override' : 'general_note'
    };

    record.annotations.push(newAnnotation);

    // Update classification if overridden
    if (overrideClassification) {
      if (!record.classificationHistory) {
        record.classificationHistory = [];
      }
      
      record.classificationHistory.push({
        previousClassification: record.aiAnalysis.classification,
        newClassification: overrideClassification,
        changedBy: req.user.name,
        changeDate: new Date().toISOString(),
        reason: annotation
      });

      record.aiAnalysis.classification = overrideClassification;
      record.aiAnalysis.overridden = true;
      record.aiAnalysis.overriddenBy = req.user.name;
      record.aiAnalysis.overrideDate = new Date().toISOString();
    }

    res.json({
      message: 'Annotation added successfully',
      annotation: newAnnotation,
      totalAnnotations: record.annotations.length
    });

  } catch (error) {
    console.error('Annotation error:', error);
    res.status(500).json({ error: 'Failed to add annotation' });
  }
});

// GET /api/doctor/statistics - Get doctor dashboard statistics
router.get('/statistics', auth, authorize(['doctor']), async (req, res) => {
  try {
    const totalCases = ecgRecords.length;
    const pendingReviews = ecgRecords.filter(r => 
      r.reviewRequest && r.reviewRequest.status === 'pending'
    ).length;
    
    const reviewedCases = ecgRecords.filter(r => r.doctorReview).length;
    const urgentCases = ecgRecords.filter(r => 
      r.aiAnalysis?.findings?.urgencyLevel === 'urgent'
    ).length;

    // Classification distribution
    const classificationStats = {};
    ecgRecords.forEach(record => {
      const classification = record.aiAnalysis?.classification || 'Unknown';
      classificationStats[classification] = (classificationStats[classification] || 0) + 1;
    });

    // Monthly trends (last 6 months)
    const monthlyStats = {};
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

    ecgRecords
      .filter(record => new Date(record.uploadDate) >= sixMonthsAgo)
      .forEach(record => {
        const month = new Date(record.uploadDate).toISOString().substring(0, 7);
        if (!monthlyStats[month]) {
          monthlyStats[month] = { total: 0, reviewed: 0, urgent: 0 };
        }
        monthlyStats[month].total++;
        if (record.doctorReview) monthlyStats[month].reviewed++;
        if (record.aiAnalysis?.findings?.urgencyLevel === 'urgent') monthlyStats[month].urgent++;
      });

    res.json({
      message: 'Statistics retrieved successfully',
      statistics: {
        overview: {
          totalCases,
          pendingReviews,
          reviewedCases,
          urgentCases,
          reviewRate: totalCases > 0 ? Math.round((reviewedCases / totalCases) * 100) : 0
        },
        classifications: classificationStats,
        monthlyTrends: monthlyStats,
        performance: {
          averageReviewTime: '3.2 minutes',
          accuracyRate: '94.5%',
          casesReviewedToday: Math.floor(Math.random() * 10 + 5)
        }
      }
    });

  } catch (error) {
    console.error('Statistics error:', error);
    res.status(500).json({
      message: 'Server error retrieving statistics'
    });
  }
});

// Additional doctor routes
router.get('/profile', auth, authorize(['doctor']), async (req, res) => {
  try {
    res.json({
      message: 'Doctor profile data',
      user: req.user
    });
  } catch (error) {
    console.error('Doctor profile error:', error);
    res.status(500).json({
      message: 'Server error accessing doctor profile'
    });
  }
});

module.exports = router;