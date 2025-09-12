import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../../services/notification_service.dart';

class DoctorReviewScreen extends StatefulWidget {
  final String? reportId;
  
  const DoctorReviewScreen({super.key, this.reportId});

  @override
  State<DoctorReviewScreen> createState() => _DoctorReviewScreenState();
}

class _DoctorReviewScreenState extends State<DoctorReviewScreen> {
  List<Map<String, dynamic>> _reviewRequests = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Pending', 'In Review', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadReviewRequests();
  }

  Future<void> _loadReviewRequests() async {
    await Future.delayed(const Duration(seconds: 1));
    
    _reviewRequests = _generateMockReviews();
    
    setState(() {
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _generateMockReviews() {
    final classifications = [
      'Normal Sinus Rhythm',
      'Atrial Fibrillation',
      'Premature Ventricular Contractions',
      'Sinus Bradycardia',
      'Sinus Tachycardia',
    ];
    
    final statuses = ['Pending', 'In Review', 'Completed'];
    final doctors = [
      'Dr. Sarah Johnson',
      'Dr. Michael Chen',
      'Dr. Emily Rodriguez',
      'Dr. David Kim',
      'Dr. Lisa Thompson',
    ];
    
    return List.generate(12, (index) {
      final status = statuses[Random().nextInt(statuses.length)];
      final isCompleted = status == 'Completed';
      
      return {
        'id': 'REV_${DateTime.now().millisecondsSinceEpoch - index * 86400000}',
        'reportId': 'ECG_${DateTime.now().millisecondsSinceEpoch - index * 86400000}',
        'requestDate': DateTime.now().subtract(Duration(days: index * 2)),
        'classification': classifications[Random().nextInt(classifications.length)],
        'confidence': (Random().nextDouble() * 0.3 + 0.7),
        'status': status,
        'priority': _getPriority(classifications[Random().nextInt(classifications.length)]),
        'assignedDoctor': isCompleted || status == 'In Review' 
            ? doctors[Random().nextInt(doctors.length)] 
            : null,
        'reviewDate': isCompleted 
            ? DateTime.now().subtract(Duration(days: Random().nextInt(5))) 
            : null,
        'doctorNotes': isCompleted ? _generateDoctorNotes() : null,
        'recommendation': isCompleted ? _generateRecommendation() : null,
        'urgency': _getUrgency(classifications[Random().nextInt(classifications.length)]),
        'patientSymptoms': _generateSymptoms(),
      };
    });
  }

  String _getPriority(String classification) {
    switch (classification) {
      case 'Atrial Fibrillation':
        return 'High';
      case 'Premature Ventricular Contractions':
        return 'Medium';
      case 'Sinus Tachycardia':
      case 'Sinus Bradycardia':
        return 'Medium';
      default:
        return 'Low';
    }
  }

  String _getUrgency(String classification) {
    switch (classification) {
      case 'Atrial Fibrillation':
        return 'Urgent';
      case 'Premature Ventricular Contractions':
        return 'Moderate';
      default:
        return 'Routine';
    }
  }

  String _generateDoctorNotes() {
    final notes = [
      'ECG shows normal sinus rhythm with no significant abnormalities. Patient can continue current activities.',
      'Mild irregularities noted. Recommend lifestyle modifications and follow-up in 3 months.',
      'Abnormal rhythm detected. Immediate cardiology consultation recommended.',
      'Borderline findings. Suggest 24-hour Holter monitoring for better assessment.',
      'Normal variant observed. No immediate intervention required, routine monitoring advised.',
    ];
    return notes[Random().nextInt(notes.length)];
  }

  String _generateRecommendation() {
    final recommendations = [
      'Continue current medication regimen. Follow-up in 6 months.',
      'Start beta-blocker therapy. Cardiology referral within 2 weeks.',
      'Immediate emergency department evaluation recommended.',
      'Lifestyle modifications: reduce caffeine, increase exercise. Recheck in 3 months.',
      'No immediate treatment needed. Annual ECG monitoring sufficient.',
    ];
    return recommendations[Random().nextInt(recommendations.length)];
  }

  String _generateSymptoms() {
    final symptoms = [
      'Chest pain, shortness of breath',
      'Palpitations, dizziness',
      'Fatigue, irregular heartbeat',
      'No symptoms reported',
      'Mild chest discomfort during exercise',
    ];
    return symptoms[Random().nextInt(symptoms.length)];
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_selectedFilter == 'All') return _reviewRequests;
    return _reviewRequests.where((item) => item['status'] == _selectedFilter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Review':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.pending;
      case 'In Review':
        return Icons.visibility;
      case 'Completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Future<void> _requestReview(String reportId) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      final newRequest = {
        'id': 'REV_${DateTime.now().millisecondsSinceEpoch}',
        'reportId': reportId,
        'requestDate': DateTime.now(),
        'classification': 'Pending Analysis',
        'confidence': 0.0,
        'status': 'Pending',
        'priority': 'Medium',
        'assignedDoctor': null,
        'reviewDate': null,
        'doctorNotes': null,
        'recommendation': null,
        'urgency': 'Routine',
        'patientSymptoms': 'To be assessed',
      };
      
      setState(() {
        _reviewRequests.insert(0, newRequest);
      });
      
      // Show notification for request acceptance
      await NotificationService().showReviewRequestAccepted(
        reviewId: newRequest['id']!,
        doctorName: 'Dr. Smith', // Mock doctor name
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Review Request'),
          content: const Text('Are you sure you want to cancel this review request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _reviewRequests.removeWhere((request) => request['id'] == reviewId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review request cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Reviews'),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (BuildContext context) => _filterOptions
                .map((option) => PopupMenuItem<String>(
                      value: option,
                      child: Text(option),
                    ))
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_list, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _selectedFilter,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.medical_services, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No review requests found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Request a doctor review from your ECG results',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showRequestReviewDialog();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Request Review'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary Cards
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Requests',
                              _reviewRequests.length.toString(),
                              Icons.assignment,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Pending',
                              _reviewRequests.where((item) => item['status'] == 'Pending').length.toString(),
                              Icons.pending,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Completed',
                              _reviewRequests.where((item) => item['status'] == 'Completed').length.toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Review Requests List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredRequests.length,
                        itemBuilder: (context, index) {
                          final request = _filteredRequests[index];
                          return _buildReviewCard(request);
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showRequestReviewDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(request['status']),
                  color: _getStatusColor(request['status']),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Review Request #${request['id'].toString().substring(4, 10)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(request['priority']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request['priority'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Requested: ${_formatDate(request['requestDate'])}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Classification:',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        request['classification'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status:',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        request['status'],
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(request['status']),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (request['assignedDoctor'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned to: ${request['assignedDoctor']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
            
            if (request['doctorNotes'] != null) ..[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Doctor\'s Notes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request['doctorNotes'],
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (request['recommendation'] != null) ..[
                      const SizedBox(height: 8),
                      const Text(
                        'Recommendation:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request['recommendation'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showRequestDetails(request);
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (request['status'] == 'Pending')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _cancelReview(request['id']);
                      },
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestReviewDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Request Doctor Review'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Request a professional medical review of your ECG results.'),
              SizedBox(height: 12),
              Text(
                'What happens next:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Your request will be assigned to a qualified cardiologist'),
              Text('• Review typically completed within 24-48 hours'),
              Text('• You\'ll receive detailed notes and recommendations'),
              Text('• Follow-up instructions will be provided if needed'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestReview('ECG_${DateTime.now().millisecondsSinceEpoch}');
              },
              child: const Text('Submit Request'),
            ),
          ],
        );
      },
    );
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Review Request Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Request ID', request['id']),
                _buildDetailRow('Report ID', request['reportId']),
                _buildDetailRow('Request Date', _formatDate(request['requestDate'])),
                _buildDetailRow('Status', request['status']),
                _buildDetailRow('Priority', request['priority']),
                _buildDetailRow('Urgency', request['urgency']),
                if (request['assignedDoctor'] != null)
                  _buildDetailRow('Assigned Doctor', request['assignedDoctor']),
                if (request['reviewDate'] != null)
                  _buildDetailRow('Review Date', _formatDate(request['reviewDate'])),
                _buildDetailRow('Patient Symptoms', request['patientSymptoms']),
                if (request['doctorNotes'] != null) ..[
                  const SizedBox(height: 12),
                  const Text(
                    'Doctor\'s Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(request['doctorNotes']),
                ],
                if (request['recommendation'] != null) ..[
                  const SizedBox(height: 12),
                  const Text(
                    'Recommendation:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(request['recommendation']),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}