import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:math';
import 'dart:async';
import '../services/ecg_service.dart';
import '../models/ecg_record.dart';
import 'ecg_results_screen.dart';
import 'dart:html' as html;

class ECGUploadScreen extends StatefulWidget {
  const ECGUploadScreen({Key? key}) : super(key: key);

  @override
  State<ECGUploadScreen> createState() => _ECGUploadScreenState();
}

class _ECGUploadScreenState extends State<ECGUploadScreen>
    with TickerProviderStateMixin {
  Uint8List? _selectedFileBytes;
  String? _fileName;
  String _recordingType = 'upload'; // 'upload' or 'simulated'
  bool _isUploading = false;
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  Timer? _waveTimer;
  
  final TextEditingController _notesController = TextEditingController();
  
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _recordingAnimationController;
  late Animation<double> _recordingAnimation;
  late AnimationController _heartbeatAnimationController;
  late Animation<double> _heartbeatAnimation;
  late AnimationController _waveAnimationController;
  late Animation<double> _waveAnimation;
  
  // Enhanced ECG wave data for realistic simulation
  final List<double> _ecgWaveData = [];
  double _currentWavePosition = 0;
  final int _heartRate = 75; // BPM
  bool _showRealTimeData = false;

  @override
  void initState() {
    super.initState();
    
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _recordingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _recordingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _recordingAnimationController,
      curve: Curves.easeInOut,
    ));

    _heartbeatAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _heartbeatAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _heartbeatAnimationController,
      curve: Curves.elasticOut,
    ));

    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_waveAnimationController);

    _pulseAnimationController.repeat(reverse: true);
    _generateECGWaveData();
  }

  void _generateECGWaveData() {
    _ecgWaveData.clear();
    // Generate realistic ECG wave pattern
    for (int i = 0; i < 1000; i++) {
      double t = i / 100.0;
      double ecgValue = 0;
      
      // P wave
      if (t % 1.0 < 0.1) {
        ecgValue += 0.2 * sin(2 * pi * (t % 1.0) / 0.1);
      }
      // QRS complex
      else if (t % 1.0 >= 0.15 && t % 1.0 < 0.25) {
        double qrsT = (t % 1.0 - 0.15) / 0.1;
        if (qrsT < 0.3) {
          ecgValue += -0.3 * sin(pi * qrsT / 0.3);
        } else if (qrsT < 0.7) {
          ecgValue += 1.0 * sin(pi * (qrsT - 0.3) / 0.4);
        } else {
          ecgValue += -0.4 * sin(pi * (qrsT - 0.7) / 0.3);
        }
      }
      // T wave
      else if (t % 1.0 >= 0.4 && t % 1.0 < 0.7) {
        ecgValue += 0.3 * sin(2 * pi * (t % 1.0 - 0.4) / 0.3);
      }
      
      // Add some noise for realism
      ecgValue += (Random().nextDouble() - 0.5) * 0.05;
      
      _ecgWaveData.add(ecgValue);
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
      _showRealTimeData = true;
      _currentWavePosition = 0;
      _recordingType = 'simulated';
      _fileName = 'Simulated ECG Recording - ${DateTime.now().toString().substring(0, 19)}';
    });

    _recordingAnimationController.forward();
    _heartbeatAnimationController.repeat();
    
    // Start recording timer
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration++;
      });
      
      // Auto-stop after 30 seconds
      if (_recordingDuration >= 30) {
        _stopRecording();
      }
    });
    
    // Start wave animation timer
    _waveTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _currentWavePosition += 2;
        if (_currentWavePosition >= _ecgWaveData.length) {
          _currentWavePosition = 0;
        }
      });
      _waveAnimationController.forward(from: 0);
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    _waveTimer?.cancel();
    _recordingAnimationController.stop();
    _heartbeatAnimationController.stop();
    
    setState(() {
      _isRecording = false;
      _showRealTimeData = false;
    });
    
    // Process the simulated recording
    _processECG();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _waveTimer?.cancel();
    _recordingAnimationController.dispose();
    _pulseAnimationController.dispose();
    _heartbeatAnimationController.dispose();
    _waveAnimationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = '.txt,.csv,.dat,.ecg';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          
          reader.onLoadEnd.listen((e) {
            setState(() {
              _selectedFileBytes = Uint8List.fromList(reader.result as List<int>);
              _fileName = file.name;
              _recordingType = 'upload';
            });
          });
          
          reader.readAsArrayBuffer(file);
        }
      });
    } catch (e) {
      _showErrorDialog('Error selecting file: $e');
    }
  }

  Future<void> _simulateRecording() async {
    _startRecording();
  }

  Future<void> _processECG() async {
    if (_recordingType == 'upload' && _selectedFileBytes == null) {
      _showErrorDialog('Please select a file first');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      Map<String, dynamic>? result;
      
      if (_recordingType == 'upload' && _selectedFileBytes != null) {
        result = await ECGService.uploadECGFile(
          _selectedFileBytes!,
          _fileName!,
          notes: _notesController.text.trim(),
        );
      } else if (_recordingType == 'simulated') {
        result = await ECGService.recordECG(
          notes: _notesController.text.trim(),
        );
      }

      if (result != null && result['success'] == true && mounted) {
        final ecgRecord = ECGRecord.fromJson(result['data']);
        // Navigate to results screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ECGResultsScreen(ecgRecord: ecgRecord),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error processing ECG: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedFileBytes = null;
      _fileName = null;
      _recordingType = 'upload';
      _notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'ECG Analysis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with animated heart
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _heartbeatAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _heartbeatAnimation.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ECG Heart Monitor',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload your ECG file or simulate a recording for AI-powered analysis',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Upload Options with enhanced design
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.upload_file,
                          color: Color(0xFF1E3A8A),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Choose Input Method',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // File Upload Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B86E5).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isUploading || _isRecording ? null : _pickFile,
                      icon: const Icon(Icons.cloud_upload, size: 24),
                      label: const Text(
                        'Upload ECG File',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B86E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // OR Divider with enhanced styling
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.grey[300]!, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.grey[300]!, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Simulate Recording Button with enhanced animation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isRecording ? _pulseAnimation.value : 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording ? const Color(0xFF36D1DC) : const Color(0xFF36D1DC)).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _isUploading || _isRecording ? null : _simulateRecording,
                            icon: _isRecording
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.radio_button_checked, size: 24),
                            label: Text(
                              _isRecording ? 'Recording ECG...' : 'Simulate ECG Recording',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRecording ? const Color(0xFF36D1DC) : const Color(0xFF36D1DC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Supported formats info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF36D1DC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF36D1DC).withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF36D1DC), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Supported formats: .txt, .csv, .dat, .ecg',
                            style: TextStyle(
                              color: Color(0xFF222831),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Selected File Info with enhanced design
            if (_fileName != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF36D1DC).withOpacity(0.1), const Color(0xFF5B86E5).withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF36D1DC).withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF36D1DC).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF36D1DC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _recordingType == 'upload' ? Icons.file_present : Icons.monitor_heart,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _recordingType == 'upload' ? 'Selected File' : 'Simulated Recording',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF36D1DC),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _fileName!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _clearSelection,
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF36D1DC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Recording Animation with enhanced visuals
            if (_isRecording) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[50]!, Colors.red[100]!.withOpacity(0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedBuilder(
                        animation: _waveAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(double.infinity, 120),
                            painter: EnhancedECGWavePainter(
                              _ecgWaveData,
                              _currentWavePosition,
                              _heartRate,
                              _recordingDuration,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B86E5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Recording ECG Signal... ${_recordingDuration}s',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Heart Rate: $_heartRate BPM',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF5B86E5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isRecording)
                      ElevatedButton(
                        onPressed: _stopRecording,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B86E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Stop Recording'),
                      ),
                  ],
                ),
              ),
            ],

            // Notes Section with enhanced design
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B86E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.note_add,
                          color: Color(0xFF5B86E5),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Additional Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Add any symptoms, medications, or relevant information...\n\nExample:\n• Chest pain during exercise\n• Taking beta-blockers\n• Recent stress or anxiety',
                      hintStyle: TextStyle(color: Colors.grey[500], height: 1.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF5B86E5), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ],
              ),
            ),

            // Process Button with enhanced design
            if (_fileName != null && !_isRecording) ...[
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B86E5).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _processECG,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B86E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Analyzing ECG with AI...',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.psychology, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Analyze with AI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Enhanced Custom painter for ECG wave animation
class ECGWavePainter extends CustomPainter {
  final double progress;

  ECGWavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red[600]!
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    // Draw grid
    for (double x = 0; x <= width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (double y = 0; y <= height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Generate ECG-like wave pattern
    final path = Path();
    path.moveTo(0, centerY);
    
    for (double x = 0; x <= width * progress; x += 1) {
      double y = centerY;
      
      // Create realistic ECG pattern
      double normalizedX = (x / width) * 6 * 3.14159; // 6 cycles
      
      // P wave
      y += 8 * exp(-pow((normalizedX % (2 * 3.14159) - 0.5), 2) / 0.1);
      
      // QRS complex
      if ((normalizedX % (2 * 3.14159)) > 1.0 && (normalizedX % (2 * 3.14159)) < 1.4) {
        double qrsX = (normalizedX % (2 * 3.14159) - 1.2) * 20;
        y += 40 * exp(-qrsX * qrsX / 0.01) * (qrsX > 0 ? 1 : -0.3);
      }
      
      // T wave
      y += 12 * exp(-pow((normalizedX % (2 * 3.14159) - 1.8), 2) / 0.2);
      
      // Add some noise for realism
      y += 2 * (sin(normalizedX * 50) * 0.1);
      
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Draw progress indicator
    if (progress < 1.0) {
      final indicatorPaint = Paint()
        ..color = Colors.red[600]!
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(width * progress, centerY),
        4,
        indicatorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Enhanced ECG Wave Painter for real-time simulation
class EnhancedECGWavePainter extends CustomPainter {
  final List<double> ecgData;
  final double currentPosition;
  final int heartRate;
  final int duration;

  EnhancedECGWavePainter(this.ecgData, this.currentPosition, this.heartRate, this.duration);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red[600]!
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    // Draw grid
    for (double x = 0; x <= width; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (double y = 0; y <= height; y += 10) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Draw ECG wave
    if (ecgData.isNotEmpty) {
      final path = Path();
      bool firstPoint = true;
      
      for (int i = 0; i < width; i++) {
        int dataIndex = ((currentPosition + i) % ecgData.length).toInt();
        double ecgValue = ecgData[dataIndex];
        double y = centerY + (ecgValue * height * 0.3);
        
        if (firstPoint) {
          path.moveTo(i.toDouble(), y);
          firstPoint = false;
        } else {
          path.lineTo(i.toDouble(), y);
        }
      }
      
      canvas.drawPath(path, paint);
    }

    // Draw current position indicator
    final indicatorPaint = Paint()
      ..color = Colors.red[700]!
      ..strokeWidth = 2;
    
    canvas.drawLine(
      Offset(width * 0.8, 0),
      Offset(width * 0.8, height),
      indicatorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}