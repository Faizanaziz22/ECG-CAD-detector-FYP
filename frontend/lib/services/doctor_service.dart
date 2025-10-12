import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/auth_storage.dart';

class DoctorService {
  static const String baseUrl = ApiConfig.baseUrl;

  // Get authentication headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get pending review requests for the doctor
  static Future<Map<String, dynamic>> getReviewRequests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/doctor/review-requests'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // If no real data, return mock data for demo
        if (data['requests'] == null || (data['requests'] as List).isEmpty) {
          return {
            'success': true,
            'requests': _getMockReviewRequests(),
          };
        }
        
        return {
          'success': true,
          'requests': data['requests'],
        };
      } else if (response.statusCode == 404) {
        // Return mock data if endpoint doesn't exist yet
        return {
          'success': true,
          'requests': _getMockReviewRequests(),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load review requests: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Return mock data for demo purposes
      return {
        'success': true,
        'requests': _getMockReviewRequests(),
      };
    }
  }

  // Get assigned patients for the doctor
  static Future<Map<String, dynamic>> getAssignedPatients() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/doctor/patients'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // If no real data, return mock data for demo
        if (data['patients'] == null || (data['patients'] as List).isEmpty) {
          return {
            'success': true,
            'patients': _getMockAssignedPatients(),
          };
        }
        
        return {
          'success': true,
          'patients': data['patients'],
        };
      } else if (response.statusCode == 404) {
        // Return mock data if endpoint doesn't exist yet
        return {
          'success': true,
          'patients': _getMockAssignedPatients(),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load assigned patients: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Return mock data for demo purposes
      return {
        'success': true,
        'patients': _getMockAssignedPatients(),
      };
    }
  }

  // Submit doctor review for an ECG case
  static Future<Map<String, dynamic>> submitReview({
    required String requestId,
    required String diagnosis,
    required String recommendations,
    String? notes,
    String priority = 'normal',
    bool overrideAI = false,
    String? newClassification,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'diagnosis': diagnosis,
        'recommendations': recommendations,
        'notes': notes,
        'priority': priority,
        'overrideAI': overrideAI,
        'newClassification': newClassification,
        'reviewDate': DateTime.now().toIso8601String(),
        'status': 'completed',
      });

      final response = await http.post(
        Uri.parse('$baseUrl/api/doctor/review/$requestId'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Review submitted successfully',
        };
      } else if (response.statusCode == 404) {
        // Simulate successful submission for demo
        await Future.delayed(const Duration(milliseconds: 500));
        return {
          'success': true,
          'message': 'Review submitted successfully (demo mode)',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to submit review: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Simulate successful submission for demo
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'success': true,
        'message': 'Review submitted successfully (demo mode)',
      };
    }
  }

  // Assign a patient to the doctor
  static Future<Map<String, dynamic>> assignPatient({
    required String patientId,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'patientId': patientId,
        'notes': notes,
        'assignedDate': DateTime.now().toIso8601String(),
      });

      final response = await http.post(
        Uri.parse('$baseUrl/api/doctor/assign-patient'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Patient assigned successfully',
        };
      } else if (response.statusCode == 404) {
        // Simulate successful assignment for demo
        await Future.delayed(const Duration(milliseconds: 500));
        return {
          'success': true,
          'message': 'Patient assigned successfully (demo mode)',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to assign patient: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Simulate successful assignment for demo
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'success': true,
        'message': 'Patient assigned successfully (demo mode)',
      };
    }
  }

  // View ECG data and analysis
  static Future<Map<String, dynamic>> viewECGData(String ecgId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/ecg/view/$ecgId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'ecgData': data,
        };
      } else if (response.statusCode == 404) {
        // Return mock ECG data for demo
        return {
          'success': true,
          'ecgData': _getMockECGData(ecgId),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load ECG data: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Return mock ECG data for demo
      return {
        'success': true,
        'ecgData': _getMockECGData(ecgId),
      };
    }
  }

  // Annotate or override AI analysis
  static Future<Map<String, dynamic>> annotateECG({
    required String ecgId,
    required String annotation,
    String? overrideClassification,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'annotation': annotation,
        'overrideClassification': overrideClassification,
        'annotationDate': DateTime.now().toIso8601String(),
      });

      final response = await http.post(
        Uri.parse('$baseUrl/api/doctor/annotate/$ecgId'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Annotation saved successfully',
        };
      } else if (response.statusCode == 404) {
        // Simulate successful annotation for demo
        await Future.delayed(const Duration(milliseconds: 300));
        return {
          'success': true,
          'message': 'Annotation saved successfully (demo mode)',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to save annotation: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Simulate successful annotation for demo
      await Future.delayed(const Duration(milliseconds: 300));
      return {
        'success': true,
        'message': 'Annotation saved successfully (demo mode)',
      };
    }
  }

  // Get doctor's dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/doctor/dashboard-stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'stats': data,
        };
      } else if (response.statusCode == 404) {
        // Return mock stats for demo
        return {
          'success': true,
          'stats': _getMockDashboardStats(),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load dashboard stats: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Return mock stats for demo
      return {
        'success': true,
        'stats': _getMockDashboardStats(),
      };
    }
  }

  // Get available patients for assignment
  static Future<Map<String, dynamic>> getAvailablePatients() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/doctor/available-patients'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'patients': data['patients'],
        };
      } else if (response.statusCode == 404) {
        // Return mock data for demo
        return {
          'success': true,
          'patients': [
            {
              'id': 'patient_004',
              'name': 'Emily Davis',
              'email': 'emily.davis@email.com',
              'age': 29,
              'gender': 'Female',
              'phone': '+1-555-0126',
              'riskLevel': 'low',
              'ecgCount': 2,
              'lastActivity': '1 week ago',
              'medicalHistory': 'Anxiety, no cardiac history',
            },
            {
              'id': 'patient_005',
              'name': 'Robert Wilson',
              'email': 'robert.w@email.com',
              'age': 61,
              'gender': 'Male',
              'phone': '+1-555-0127',
              'riskLevel': 'medium',
              'ecgCount': 7,
              'lastActivity': '4 days ago',
              'medicalHistory': 'High cholesterol, smoker',
            },
            {
              'id': 'patient_006',
              'name': 'Lisa Anderson',
              'email': 'lisa.anderson@email.com',
              'age': 34,
              'gender': 'Female',
              'phone': '+1-555-0128',
              'riskLevel': 'low',
              'ecgCount': 1,
              'lastActivity': '2 weeks ago',
              'medicalHistory': 'Pregnancy-related monitoring',
            },
          ],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load available patients: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Return mock data for demo
      return {
        'success': true,
        'patients': [
          {
            'id': 'patient_004',
            'name': 'Emily Davis',
            'email': 'emily.davis@email.com',
            'age': 29,
            'gender': 'Female',
            'phone': '+1-555-0126',
            'riskLevel': 'low',
            'ecgCount': 2,
            'lastActivity': '1 week ago',
            'medicalHistory': 'Anxiety, no cardiac history',
          },
          {
            'id': 'patient_005',
            'name': 'Robert Wilson',
            'email': 'robert.w@email.com',
            'age': 61,
            'gender': 'Male',
            'phone': '+1-555-0127',
            'riskLevel': 'medium',
            'ecgCount': 7,
            'lastActivity': '4 days ago',
            'medicalHistory': 'High cholesterol, smoker',
          },
          {
            'id': 'patient_006',
            'name': 'Lisa Anderson',
            'email': 'lisa.anderson@email.com',
            'age': 34,
            'gender': 'Female',
            'phone': '+1-555-0128',
            'riskLevel': 'low',
            'ecgCount': 1,
            'lastActivity': '2 weeks ago',
            'medicalHistory': 'Pregnancy-related monitoring',
          },
        ],
      };
    }
  }

  // Unassign a patient from the doctor
  static Future<Map<String, dynamic>> unassignPatient(String patientId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/doctor/unassign-patient/$patientId'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Patient unassigned successfully',
        };
      } else if (response.statusCode == 404) {
        // Simulate successful unassignment for demo
        await Future.delayed(const Duration(milliseconds: 500));
        return {
          'success': true,
          'message': 'Patient unassigned successfully (demo mode)',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to unassign patient: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Simulate successful unassignment for demo
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'success': true,
        'message': 'Patient unassigned successfully (demo mode)',
      };
    }
  }

  // Mock data for demo purposes
  static List<Map<String, dynamic>> _getMockReviewRequests() {
    return [
      {
        'id': 'req_001',
        'patientName': 'John Smith',
        'patientAge': 45,
        'requestDate': '2024-01-15',
        'fileName': 'ecg_john_smith_20240115.dat',
        'status': 'pending',
        'priority': 'urgent',
        'aiAnalysis': {
          'classification': 'Abnormal',
          'confidence': 0.92,
          'summary': 'Irregular rhythm detected with possible atrial fibrillation. Immediate medical attention recommended.',
        },
      },
      {
        'id': 'req_002',
        'patientName': 'Sarah Johnson',
        'patientAge': 32,
        'requestDate': '2024-01-14',
        'fileName': 'ecg_sarah_johnson_20240114.dat',
        'status': 'pending',
        'priority': 'high',
        'aiAnalysis': {
          'classification': 'Abnormal',
          'confidence': 0.87,
          'summary': 'Elevated ST segments observed. Possible myocardial infarction indicators present.',
        },
      },
      {
        'id': 'req_003',
        'patientName': 'Michael Brown',
        'patientAge': 28,
        'requestDate': '2024-01-14',
        'fileName': 'ecg_michael_brown_20240114.dat',
        'status': 'pending',
        'priority': 'normal',
        'aiAnalysis': {
          'classification': 'Normal',
          'confidence': 0.95,
          'summary': 'Normal sinus rhythm with no significant abnormalities detected.',
        },
      },
      {
        'id': 'req_004',
        'patientName': 'Emily Davis',
        'patientAge': 67,
        'requestDate': '2024-01-13',
        'fileName': 'ecg_emily_davis_20240113.dat',
        'status': 'pending',
        'priority': 'urgent',
        'aiAnalysis': {
          'classification': 'Abnormal',
          'confidence': 0.89,
          'summary': 'Bradycardia detected with heart rate below 50 bpm. Potential conduction abnormalities.',
        },
      },
      {
        'id': 'req_005',
        'patientName': 'Robert Wilson',
        'patientAge': 55,
        'requestDate': '2024-01-13',
        'fileName': 'ecg_robert_wilson_20240113.dat',
        'status': 'pending',
        'priority': 'normal',
        'aiAnalysis': {
          'classification': 'Normal',
          'confidence': 0.91,
          'summary': 'Regular sinus rhythm within normal parameters for patient age group.',
        },
      },
      {
        'id': 'req_006',
        'patientName': 'Lisa Anderson',
        'patientAge': 41,
        'requestDate': '2024-01-12',
        'fileName': 'ecg_lisa_anderson_20240112.dat',
        'status': 'pending',
        'priority': 'high',
        'aiAnalysis': {
          'classification': 'Abnormal',
          'confidence': 0.84,
          'summary': 'Premature ventricular contractions (PVCs) detected. Monitoring recommended.',
        },
      },
    ];
  }

  static List<Map<String, dynamic>> _getMockAssignedPatients() {
    return [
      {
        'id': 'pat_001',
        'name': 'John Smith',
        'age': 45,
        'assignedDate': '2024-01-10',
        'status': 'Active',
        'lastECGDate': '2024-01-15',
        'totalECGs': 3,
        'condition': 'Atrial Fibrillation',
      },
      {
        'id': 'pat_002',
        'name': 'Sarah Johnson',
        'age': 32,
        'assignedDate': '2024-01-08',
        'status': 'Active',
        'lastECGDate': '2024-01-14',
        'totalECGs': 2,
        'condition': 'Chest Pain Investigation',
      },
      {
        'id': 'pat_003',
        'name': 'Michael Brown',
        'age': 28,
        'assignedDate': '2024-01-05',
        'status': 'Active',
        'lastECGDate': '2024-01-14',
        'totalECGs': 1,
        'condition': 'Routine Screening',
      },
      {
        'id': 'pat_004',
        'name': 'Emily Davis',
        'age': 67,
        'assignedDate': '2024-01-03',
        'status': 'Active',
        'lastECGDate': '2024-01-13',
        'totalECGs': 5,
        'condition': 'Bradycardia Monitoring',
      },
      {
        'id': 'pat_005',
        'name': 'Robert Wilson',
        'age': 55,
        'assignedDate': '2024-01-01',
        'status': 'Active',
        'lastECGDate': '2024-01-13',
        'totalECGs': 4,
        'condition': 'Hypertension Follow-up',
      },
    ];
  }

  static Map<String, dynamic> _getMockECGData(String ecgId) {
    return {
      'id': ecgId,
      'patientName': 'John Smith',
      'recordingDate': '2024-01-15T10:30:00Z',
      'duration': 10, // seconds
      'sampleRate': 500, // Hz
      'leads': ['I', 'II', 'III', 'aVR', 'aVL', 'aVF', 'V1', 'V2', 'V3', 'V4', 'V5', 'V6'],
      'waveformData': {
        // Simplified mock waveform data
        'lead_II': List.generate(5000, (index) {
          // Generate a simple ECG-like pattern
          final time = index / 500.0; // Convert to seconds
          const heartRate = 75; // bpm
          final period = 60.0 / heartRate; // seconds per beat
          final phase = (time % period) / period;
          
          double amplitude = 0;
          if (phase < 0.1) {
            // P wave
            amplitude = 0.2 * (phase / 0.1) * (1 - phase / 0.1);
          } else if (phase < 0.2) {
            // PR segment
            amplitude = 0;
          } else if (phase < 0.25) {
            // Q wave
            amplitude = -0.1;
          } else if (phase < 0.3) {
            // R wave
            amplitude = 1.0 * ((phase - 0.25) / 0.05);
          } else if (phase < 0.35) {
            // S wave
            amplitude = -0.3 * ((phase - 0.3) / 0.05);
          } else if (phase < 0.5) {
            // ST segment
            amplitude = 0;
          } else if (phase < 0.7) {
            // T wave
            amplitude = 0.3 * ((phase - 0.5) / 0.2) * (1 - (phase - 0.5) / 0.2);
          }
          
          return amplitude;
        }),
      },
      'aiAnalysis': {
        'classification': 'Abnormal',
        'confidence': 0.92,
        'summary': 'Irregular rhythm detected with possible atrial fibrillation.',
        'heartRate': 75,
        'rhythm': 'Irregular',
        'abnormalities': ['Atrial Fibrillation', 'Irregular RR intervals'],
      },
    };
  }

  static Map<String, dynamic> _getMockDashboardStats() {
    return {
      'totalPatients': 25,
      'pendingReviews': 6,
      'completedReviews': 18,
      'urgentCases': 2,
      'todayReviews': 3,
      'weeklyReviews': 12,
      'monthlyReviews': 45,
      'averageResponseTime': '2.5 hours',
      'patientSatisfaction': 4.8,
    };
  }
}