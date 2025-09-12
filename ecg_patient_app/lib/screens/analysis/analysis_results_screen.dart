import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class AnalysisResultsScreen extends StatefulWidget {
  const AnalysisResultsScreen({super.key});

  @override
  State<AnalysisResultsScreen> createState() => _AnalysisResultsScreenState();
}

class _AnalysisResultsScreenState extends State<AnalysisResultsScreen> {
  Map<String, dynamic>? _latestAnalysis;
  List<Map<String, dynamic>> _allResults = [];
  bool _isLoading = true;
  bool _requestingReview = false;

  @override
  void initState() {
    super.initState();
    _loadAnalysisResults();
  }

  Future<void> _loadAnalysisResults() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load latest analysis
    final latestAnalysisStr = prefs.getString('latest_analysis');
    if (latestAnalysisStr != null) {
      try {
        _latestAnalysis = _parseAnalysisString(latestAnalysisStr);
      } catch (e) {
        // Handle parsing error
      }
    }
    
    // Load all results (simulate multiple results)
    _allResults = _generateMockResults();
    
    setState(() {
      _isLoading = false;
    });
  }

  Map<String, dynamic> _parseAnalysisString(String analysisStr) {
    // Simple parsing since we stored it as string representation
    final cleanStr = analysisStr.replaceAll('{', '').replaceAll('}', '');
    final pairs = cleanStr.split(', ');
    final Map<String, dynamic> result = {};
    
    for (final pair in pairs) {
      final keyValue = pair.split(': ');
      if (keyValue.length == 2) {
        final key = keyValue[0].trim();
        final value = keyValue[1].trim();
        
        if (key == 'confidence') {
          result[key] = double.tryParse(value) ?? 0.0;
        } else if (key == 'heartRate') {
          result[key] = int.tryParse(value) ?? 0;
        } else {
          result[key] = value;
        }
      }
    }
    
    return result;
  }

  List<Map<String, dynamic>> _generateMockResults() {
    final classifications = [
      'Normal Sinus Rhythm',
      'Atrial Fibrillation',
      'Premature Ventricular Contractions',
      'Sinus Bradycardia',
      'Sinus Tachycardia',
    ];
    
    return List.generate(5, (index) => {
      'fileName': 'ECG_Report_${index + 1}',
      'uploadTime': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
      'classification': classifications[Random().nextInt(classifications.length)],
      'confidence': (Random().nextDouble() * 0.3 + 0.7),
      'heartRate': Random().nextInt(40) + 60,
      'status': index == 0 ? 'completed' : (Random().nextBool() ? 'completed' : 'pending_review'),
      'doctorReviewed': index > 2,
    });
  }

  Future<void> _requestDoctorReview() async {
    setState(() {
      _requestingReview = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final currentPending = prefs.getInt('pending_reviews') ?? 0;
    await prefs.setInt('pending_reviews', currentPending + 1);

    setState(() {
      _requestingReview = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor review requested successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.orange;
    return Colors.red;
  }

  String _getConfidenceText(double confidence) {
    if (confidence >= 0.9) return 'High';
    if (confidence >= 0.7) return 'Medium';
    return 'Low';
  }

  String _getClassificationSummary(String classification) {
    switch (classification) {
      case 'Normal Sinus Rhythm':
        return 'Your heart rhythm appears normal. The electrical activity shows regular patterns within expected ranges.';
      case 'Atrial Fibrillation':
        return 'Irregular heart rhythm detected. The upper chambers of your heart are beating irregularly. Consult your doctor.';
      case 'Premature Ventricular Contractions':
        return 'Extra heartbeats detected. These are usually harmless but should be monitored by a healthcare professional.';
      case 'Sinus Bradycardia':
        return 'Slower than normal heart rate detected. This may be normal for athletes or may require medical attention.';
      case 'Sinus Tachycardia':
        return 'Faster than normal heart rate detected. This could be due to exercise, stress, or other factors.';
      default:
        return 'ECG analysis completed. Please consult with a healthcare professional for detailed interpretation.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Latest Result Card
                  if (_latestAnalysis != null) ...[
                    const Text(
                      'Latest Analysis',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLatestResultCard(),
                    const SizedBox(height: 24),
                  ],
                  
                  // All Results
                  const Text(
                    'Previous Results',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ..._allResults.map((result) => _buildResultCard(result)),
                ],
              ),
            ),
    );
  }

  Widget _buildLatestResultCard() {
    final analysis = _latestAnalysis!;
    final confidence = analysis['confidence'] ?? 0.0;
    final classification = analysis['classification'] ?? 'Unknown';
    final heartRate = analysis['heartRate'] ?? 0;
    
    return Card(
      elevation: 6,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    analysis['fileName'] ?? 'ECG Analysis',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Classification
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Classification',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    classification,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Confidence',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getConfidenceColor(confidence),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(confidence * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${_getConfidenceText(confidence)})',
                              style: TextStyle(
                                color: _getConfidenceColor(confidence),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Heart Rate',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.favorite, color: Colors.red, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$heartRate BPM',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getClassificationSummary(classification),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _requestingReview ? null : _requestDoctorReview,
                    icon: _requestingReview
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.medical_services),
                    label: Text(_requestingReview ? 'Requesting...' : 'Request Doctor Review'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PDF download feature coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download PDF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final confidence = result['confidence'] ?? 0.0;
    final classification = result['classification'] ?? 'Unknown';
    final heartRate = result['heartRate'] ?? 0;
    final status = result['status'] ?? 'pending';
    final doctorReviewed = result['doctorReviewed'] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    result['fileName'] ?? 'ECG Report',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'completed' ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
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
              classification,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _getConfidenceColor(confidence),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'HR: $heartRate BPM',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                if (doctorReviewed)
                  const Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Doctor Reviewed',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}