import 'dart:convert';

class ECGRecord {
  final int id;
  final String fileName;
  final String recordingType;
  final DateTime uploadDate;
  final int? fileSize;
  final String? notes;
  final AIAnalysis aiAnalysis;
  final DoctorReview? doctorReview;
  final String status;
  final ReviewRequest? reviewRequest;

  ECGRecord({
    required this.id,
    required this.fileName,
    required this.recordingType,
    required this.uploadDate,
    this.fileSize,
    this.notes,
    required this.aiAnalysis,
    this.doctorReview,
    required this.status,
    this.reviewRequest,
  });

  factory ECGRecord.fromJson(Map<String, dynamic> json) {
    return ECGRecord(
      id: json['id'],
      fileName: json['fileName'],
      recordingType: json['recordingType'],
      uploadDate: DateTime.parse(json['uploadDate']),
      fileSize: json['fileSize'],
      notes: json['notes'],
      aiAnalysis: AIAnalysis.fromJson(json['aiAnalysis']),
      doctorReview: json['doctorReview'] != null 
          ? DoctorReview.fromJson(json['doctorReview'])
          : null,
      status: json['status'],
      reviewRequest: json['reviewRequest'] != null
          ? ReviewRequest.fromJson(json['reviewRequest'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'recordingType': recordingType,
      'uploadDate': uploadDate.toIso8601String(),
      'fileSize': fileSize,
      'notes': notes,
      'aiAnalysis': aiAnalysis.toJson(),
      'doctorReview': doctorReview?.toJson(),
      'status': status,
      'reviewRequest': reviewRequest?.toJson(),
    };
  }

  String toJsonString() => json.encode(toJson());

  factory ECGRecord.fromJsonString(String jsonString) =>
      ECGRecord.fromJson(json.decode(jsonString));

  bool get hasReview => doctorReview != null;
  bool get isReviewRequested => reviewRequest != null;
  bool get isNormal => aiAnalysis.classification.toLowerCase() == 'normal';
}

class AIAnalysis {
  final String classification;
  final int confidence;
  final String summary;
  final DateTime analysisDate;

  AIAnalysis({
    required this.classification,
    required this.confidence,
    required this.summary,
    required this.analysisDate,
  });

  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    return AIAnalysis(
      classification: json['classification'],
      confidence: json['confidence'],
      summary: json['summary'],
      analysisDate: DateTime.parse(json['analysisDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classification': classification,
      'confidence': confidence,
      'summary': summary,
      'analysisDate': analysisDate.toIso8601String(),
    };
  }

  String get confidenceText => '$confidence%';
  
  String get severityLevel {
    if (classification.toLowerCase() == 'normal') return 'Normal';
    if (confidence >= 90) return 'High Confidence';
    if (confidence >= 70) return 'Medium Confidence';
    return 'Low Confidence';
  }
}

class DoctorReview {
  final int doctorId;
  final String doctorName;
  final DateTime reviewDate;
  final String diagnosis;
  final String recommendations;
  final String severity;
  final String status;

  DoctorReview({
    required this.doctorId,
    required this.doctorName,
    required this.reviewDate,
    required this.diagnosis,
    required this.recommendations,
    required this.severity,
    required this.status,
  });

  factory DoctorReview.fromJson(Map<String, dynamic> json) {
    return DoctorReview(
      doctorId: json['doctorId'],
      doctorName: json['doctorName'],
      reviewDate: DateTime.parse(json['reviewDate']),
      diagnosis: json['diagnosis'],
      recommendations: json['recommendations'] ?? '',
      severity: json['severity'] ?? 'normal',
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'doctorName': doctorName,
      'reviewDate': reviewDate.toIso8601String(),
      'diagnosis': diagnosis,
      'recommendations': recommendations,
      'severity': severity,
      'status': status,
    };
  }

  String get severityDisplay {
    switch (severity.toLowerCase()) {
      case 'normal':
        return 'Normal';
      case 'mild':
        return 'Mild';
      case 'moderate':
        return 'Moderate';
      case 'severe':
        return 'Severe';
      default:
        return 'Unknown';
    }
  }
}

class ReviewRequest {
  final DateTime requestDate;
  final String message;
  final String status;

  ReviewRequest({
    required this.requestDate,
    required this.message,
    required this.status,
  });

  factory ReviewRequest.fromJson(Map<String, dynamic> json) {
    return ReviewRequest(
      requestDate: DateTime.parse(json['requestDate']),
      message: json['message'] ?? '',
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestDate': requestDate.toIso8601String(),
      'message': message,
      'status': status,
    };
  }

  bool get isPending => status == 'pending';
  bool get isInReview => status == 'in_review';
  bool get isCompleted => status == 'completed';
}

// Simplified ECG record for history list
class ECGHistoryItem {
  final int id;
  final String fileName;
  final String recordingType;
  final DateTime uploadDate;
  final String classification;
  final int confidence;
  final String status;
  final bool hasReview;

  ECGHistoryItem({
    required this.id,
    required this.fileName,
    required this.recordingType,
    required this.uploadDate,
    required this.classification,
    required this.confidence,
    required this.status,
    required this.hasReview,
  });

  factory ECGHistoryItem.fromJson(Map<String, dynamic> json) {
    return ECGHistoryItem(
      id: json['id'],
      fileName: json['fileName'],
      recordingType: json['recordingType'],
      uploadDate: DateTime.parse(json['uploadDate']),
      classification: json['aiAnalysis']['classification'],
      confidence: json['aiAnalysis']['confidence'],
      status: json['status'],
      hasReview: json['hasReview'] ?? false,
    );
  }

  String get confidenceText => '$confidence%';
  bool get isNormal => classification.toLowerCase() == 'normal';
}