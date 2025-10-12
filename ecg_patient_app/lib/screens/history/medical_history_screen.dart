import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:math';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  List<Map<String, dynamic>> _historyData = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Normal', 'Abnormal', 'Pending Review'];

  @override
  void initState() {
    super.initState();
    _loadMedicalHistory();
  }

  Future<void> _loadMedicalHistory() async {
    // Simulate loading medical history
    await Future.delayed(const Duration(seconds: 1));
    
    _historyData = _generateMockHistory();
    
    setState(() {
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _generateMockHistory() {
    final classifications = [
      'Normal Sinus Rhythm',
      'Atrial Fibrillation',
      'Premature Ventricular Contractions',
      'Sinus Bradycardia',
      'Sinus Tachycardia',
    ];
    
    final statuses = ['Normal', 'Abnormal', 'Pending Review'];
    
    return List.generate(15, (index) {
      final classification = classifications[Random().nextInt(classifications.length)];
      final isNormal = classification == 'Normal Sinus Rhythm';
      
      return {
        'id': 'ECG_${DateTime.now().millisecondsSinceEpoch - index * 86400000}',
        'date': DateTime.now().subtract(Duration(days: index * 2)),
        'classification': classification,
        'confidence': (Random().nextDouble() * 0.3 + 0.7),
        'heartRate': Random().nextInt(40) + 60,
        'status': isNormal ? 'Normal' : (Random().nextBool() ? 'Abnormal' : 'Pending Review'),
        'doctorReviewed': false,
        'notes': _generateNotes(classification),
      };
    });
  }

  String _generateNotes(String classification) {
    switch (classification) {
      case 'Normal Sinus Rhythm':
        return 'Regular heart rhythm within normal parameters. Continue regular monitoring.';
      case 'Atrial Fibrillation':
        return 'Irregular rhythm detected. Recommend follow-up with cardiologist.';
      case 'Premature Ventricular Contractions':
        return 'Extra heartbeats observed. Monitor for frequency and symptoms.';
      case 'Sinus Bradycardia':
        return 'Slower heart rate detected. Assess for underlying causes.';
      case 'Sinus Tachycardia':
        return 'Elevated heart rate. Consider stress, medication, or other factors.';
      default:
        return 'ECG analysis completed. Consult healthcare provider for interpretation.';
    }
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_selectedFilter == 'All') return _historyData;
    return _historyData.where((item) => item['status'] == _selectedFilter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Normal':
        return Colors.green;
      case 'Abnormal':
        return Colors.red;
      case 'Pending Review':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Normal':
        return Icons.check_circle;
      case 'Abnormal':
        return Icons.warning;
      case 'Pending Review':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }

  Future<void> _generateAndDownloadPDF(Map<String, dynamic> record) async {
    try {
      final pdf = pw.Document();
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Patient';
      final userEmail = prefs.getString('current_user_email') ?? 'patient@example.com';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ECG Analysis Report',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Report ID: ${record['id']}',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Patient Information
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Patient Information',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text('Name: $userName'),
                          ),
                          pw.Expanded(
                            child: pw.Text('Email: $userEmail'),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('Report Date: ${_formatDate(record['date'])}'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Analysis Results
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Analysis Results',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 15),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Classification:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                pw.Text(record['classification']),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Status:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                pw.Text(record['status']),
                              ],
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Confidence:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                pw.Text('${(record['confidence'] * 100).toStringAsFixed(1)}%'),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Heart Rate:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                pw.Text('${record['heartRate']} BPM'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Clinical Notes
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Clinical Notes',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(record['notes']),
                    ],
                  ),
                ),
                
                pw.Spacer(),
                
                // Footer
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'This report is generated by ECG Patient App',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        'Generated on: ${DateTime.now().toString()}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Share or save the PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'ECG_Report_${record['id']}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF report generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
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
        title: const Text('Medical History'),
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
          : _filteredHistory.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No medical history found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Upload your first ECG to get started',
                        style: TextStyle(color: Colors.grey),
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
                              'Total Reports',
                              _historyData.length.toString(),
                              Icons.description,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Normal',
                              _historyData.where((item) => item['status'] == 'Normal').length.toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Abnormal',
                              _historyData.where((item) => item['status'] == 'Abnormal').length.toString(),
                              Icons.warning,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // History List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredHistory.length,
                        itemBuilder: (context, index) {
                          final record = _filteredHistory[index];
                          return _buildHistoryCard(record);
                        },
                      ),
                    ),
                  ],
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

  Widget _buildHistoryCard(Map<String, dynamic> record) {
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
                  _getStatusIcon(record['status']),
                  color: _getStatusColor(record['status']),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record['classification'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(record['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record['status'],
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
              _formatDate(record['date']),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Confidence: ${(record['confidence'] * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  'HR: ${record['heartRate']} BPM',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showRecordDetails(record);
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _generateAndDownloadPDF(record);
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download PDF'),
                    style: ElevatedButton.styleFrom(
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

  void _showRecordDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ECG Report Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Report ID', record['id']),
                _buildDetailRow('Date', _formatDate(record['date'])),
                _buildDetailRow('Classification', record['classification']),
                _buildDetailRow('Status', record['status']),
                _buildDetailRow('Confidence', '${(record['confidence'] * 100).toStringAsFixed(1)}%'),
                _buildDetailRow('Heart Rate', '${record['heartRate']} BPM'),
                const SizedBox(height: 12),
                const Text(
                  'Clinical Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(record['notes']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _generateAndDownloadPDF(record);
              },
              child: const Text('Download PDF'),
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
            width: 100,
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