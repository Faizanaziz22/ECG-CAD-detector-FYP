import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:async';
import '../analysis/analysis_results_screen.dart';
import '../../services/notification_service.dart';

class ECGUploadScreen extends StatefulWidget {
  const ECGUploadScreen({super.key});

  @override
  State<ECGUploadScreen> createState() => _ECGUploadScreenState();
}

class _ECGUploadScreenState extends State<ECGUploadScreen>
    with TickerProviderStateMixin {
  String? _selectedFileName;
  bool _isUploading = false;
  bool _isRecording = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final List<double> _ecgData = [];
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv', 'dat', 'ecg'],
      );

      if (result != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected: $_selectedFileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error selecting file'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    // Simulate upload process
    await Future.delayed(const Duration(seconds: 3));

    // Save upload record
    final prefs = await SharedPreferences.getInstance();
    final currentReports = prefs.getInt('total_reports') ?? 0;
    await prefs.setInt('total_reports', currentReports + 1);
    
    // Generate mock analysis data
    final analysisData = {
      'fileName': _selectedFileName,
      'uploadTime': DateTime.now().toIso8601String(),
      'classification': _generateRandomClassification(),
      'confidence': (Random().nextDouble() * 0.3 + 0.7), // 70-100%
      'heartRate': Random().nextInt(40) + 60, // 60-100 BPM
      'status': 'completed',
    };
    
    await prefs.setString('latest_analysis', analysisData.toString());

    // Show notification for analysis completion
    await NotificationService().showECGAnalysisComplete(
      reportId: DateTime.now().millisecondsSinceEpoch.toString(),
      classification: analysisData['classification'] as String,
      confidence: analysisData['confidence'] as double,
    );

    // Show abnormal ECG alert if needed
    if (analysisData['classification'] != 'Normal Sinus Rhythm') {
      await NotificationService().showAbnormalECGAlert(
        reportId: DateTime.now().millisecondsSinceEpoch.toString(),
        classification: analysisData['classification'] as String,
      );
    }

    setState(() {
      _isUploading = false;
      _selectedFileName = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ECG uploaded and analyzed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to results
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AnalysisResultsScreen(),
        ),
      );
    }
  }

  String _generateRandomClassification() {
    final classifications = [
      'Normal Sinus Rhythm',
      'Atrial Fibrillation',
      'Premature Ventricular Contractions',
      'Sinus Bradycardia',
      'Sinus Tachycardia',
    ];
    return classifications[Random().nextInt(classifications.length)];
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
      _ecgData.clear();
    });
    
    _pulseController.repeat(reverse: true);
    
    // Simulate ECG recording
    _simulateECGRecording();
  }

  void _simulateECGRecording() {
    const duration = Duration(milliseconds: 100);
    Timer.periodic(duration, (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _recordingDuration += 100;
        // Generate simulated ECG data
        _ecgData.add(Random().nextDouble() * 2 - 1);
      });
      
      if (_recordingDuration >= 10000) { // 10 seconds
        _stopRecording();
        timer.cancel();
      }
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    
    _pulseController.stop();
    
    if (_ecgData.isNotEmpty) {
      _processRecordedData();
    }
  }

  Future<void> _processRecordedData() async {
    setState(() {
      _isUploading = true;
    });

    // Simulate processing
    await Future.delayed(const Duration(seconds: 2));

    // Save recorded data
    final prefs = await SharedPreferences.getInstance();
    final currentReports = prefs.getInt('total_reports') ?? 0;
    await prefs.setInt('total_reports', currentReports + 1);
    
    final analysisData = {
      'fileName': 'Recorded_ECG_${DateTime.now().millisecondsSinceEpoch}',
      'uploadTime': DateTime.now().toIso8601String(),
      'classification': _generateRandomClassification(),
      'confidence': (Random().nextDouble() * 0.3 + 0.7),
      'heartRate': Random().nextInt(40) + 60,
      'status': 'completed',
      'recordingDuration': _recordingDuration,
    };
    
    await prefs.setString('latest_analysis', analysisData.toString());

    // Show notification for analysis completion
    await NotificationService().showECGAnalysisComplete(
      reportId: DateTime.now().millisecondsSinceEpoch.toString(),
      classification: analysisData['classification'] as String,
      confidence: analysisData['confidence'] as double,
    );

    // Show abnormal ECG alert if needed
    if (analysisData['classification'] != 'Normal Sinus Rhythm') {
      await NotificationService().showAbnormalECGAlert(
        reportId: DateTime.now().millisecondsSinceEpoch.toString(),
        classification: analysisData['classification'] as String,
      );
    }

    setState(() {
      _isUploading = false;
      _ecgData.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ECG recorded and analyzed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AnalysisResultsScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ECG Upload'),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload from File Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.upload_file, color: Colors.blue, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Upload ECG File',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select an ECG file from your device (.txt, .csv, .dat, .ecg)',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    if (_selectedFileName != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Selected: $_selectedFileName',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUploading ? null : _pickFile,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Select File'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : _uploadFile,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload),
                            label: Text(_isUploading ? 'Uploading...' : 'Upload'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Record ECG Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.monitor_heart, color: Colors.red, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Record ECG',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Record your ECG using a connected device or simulate recording',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    
                    // Recording Status
                    if (_isRecording) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Recording in progress...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            Text(
                              '${(_recordingDuration / 1000).toStringAsFixed(1)}s / 10.0s',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // ECG Waveform Visualization (simplified)
                    if (_ecgData.isNotEmpty)
                      Container(
                        height: 100,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomPaint(
                          painter: ECGPainter(_ecgData),
                          size: const Size(double.infinity, 100),
                        ),
                      ),
                    
                    if (_ecgData.isNotEmpty) const SizedBox(height: 16),
                    
                    // Recording Controls
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUploading
                                ? null
                                : _isRecording
                                    ? _stopRecording
                                    : _startRecording,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRecording ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
                            label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Instructions Card
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• Ensure you are in a quiet environment'),
                    Text('• Keep still during recording'),
                    Text('• Follow device-specific instructions'),
                    Text('• Recording will automatically stop after 10 seconds'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ECGPainter extends CustomPainter {
  final List<double> data;
  
  ECGPainter(this.data);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    if (data.isEmpty) return;
    
    final path = Path();
    final stepX = size.width / data.length;
    
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height / 2 + (data[i] * size.height / 4);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}