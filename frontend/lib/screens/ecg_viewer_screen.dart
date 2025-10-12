import 'package:flutter/material.dart';
import '../widgets/ecg_waveform_viewer.dart';
import '../services/doctor_service.dart';

class ECGViewerScreen extends StatefulWidget {
  final String ecgId;
  final String patientName;
  final Map<String, dynamic>? initialData;

  const ECGViewerScreen({
    Key? key,
    required this.ecgId,
    required this.patientName,
    this.initialData,
  }) : super(key: key);

  @override
  State<ECGViewerScreen> createState() => _ECGViewerScreenState();
}

class _ECGViewerScreenState extends State<ECGViewerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _ecgData;
  bool _isLoading = true;
  String? _error;
  
  // Annotation state
  bool _isAnnotating = false;
  final TextEditingController _annotationController = TextEditingController();
  String? _selectedClassification;
  double? _selectedTimePoint;
  
  // Analysis state
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _recommendationsController = TextEditingController();
  String _selectedPriority = 'normal';
  bool _overrideAI = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadECGData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _annotationController.dispose();
    _diagnosisController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  Future<void> _loadECGData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await DoctorService.viewECGData(widget.ecgId);
      
      if (result['success']) {
        setState(() {
          _ecgData = result['ecgData'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load ECG data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAnnotation() async {
    if (_annotationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an annotation')),
      );
      return;
    }

    try {
      final result = await DoctorService.annotateECG(
        ecgId: widget.ecgId,
        annotation: _annotationController.text,
        overrideClassification: _selectedClassification,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        _annotationController.clear();
        setState(() {
          _isAnnotating = false;
          _selectedClassification = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save annotation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ECG Viewer'),
            Text(
              widget.patientName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isAnnotating ? Icons.save : Icons.edit),
            onPressed: _isAnnotating ? _saveAnnotation : () {
              setState(() {
                _isAnnotating = !_isAnnotating;
              });
            },
            tooltip: _isAnnotating ? 'Save Annotation' : 'Add Annotation',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadECGData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.monitor_heart), text: 'Waveform'),
            Tab(icon: Icon(Icons.analytics), text: 'Analysis'),
            Tab(icon: Icon(Icons.assignment), text: 'Review'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading ECG Data',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadECGData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWaveformTab(),
                    _buildAnalysisTab(),
                    _buildReviewTab(),
                  ],
                ),
    );
  }

  Widget _buildWaveformTab() {
    if (_ecgData == null) return const SizedBox();

    final waveformData = _ecgData!['waveformData']['lead_II'] as List<dynamic>?;
    final leadData = waveformData?.map((e) => (e as num).toDouble()).toList() ?? 
        ECGDataGenerator.generateSampleECG();

    return Column(
      children: [
        // Annotation input (if annotating)
        if (_isAnnotating) _buildAnnotationInput(),
        
        // ECG Waveform Display
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Main waveform viewer
                ECGWaveformViewer(
                  waveformData: leadData,
                  leadName: 'Lead II',
                  height: 300,
                  interactive: true,
                  onTimeSelected: (time) {
                    setState(() {
                      _selectedTimePoint = time;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Additional leads (if available)
                if (_ecgData!['leads'] != null) ...[
                  for (String lead in _ecgData!['leads'])
                    if (lead != 'II') ...[
                      const SizedBox(height: 8),
                      ECGWaveformViewer(
                        waveformData: ECGDataGenerator.generateSampleECG(
                          heartRate: 75,
                          pattern: ECGPattern.normal,
                        ),
                        leadName: 'Lead $lead',
                        height: 150,
                        interactive: false,
                      ),
                    ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnotationInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Annotation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          
          // Classification override
          Row(
            children: [
              const Text('Override Classification:'),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedClassification,
                hint: const Text('Select'),
                items: ['Normal', 'Abnormal', 'Borderline'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedClassification = newValue;
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Annotation text
          TextField(
            controller: _annotationController,
            decoration: const InputDecoration(
              hintText: 'Enter your annotation or clinical notes...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          
          if (_selectedTimePoint != null) ...[
            const SizedBox(height: 8),
            Text(
              'Selected time: ${_selectedTimePoint!.toStringAsFixed(2)}s',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    if (_ecgData == null) return const SizedBox();

    final aiAnalysis = _ecgData!['aiAnalysis'] as Map<String, dynamic>?;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Analysis Results
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Analysis Results',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Classification
                  _buildAnalysisItem(
                    'Classification',
                    aiAnalysis?['classification'] ?? 'Unknown',
                    _getClassificationColor(aiAnalysis?['classification']),
                  ),
                  
                  // Confidence
                  _buildAnalysisItem(
                    'Confidence',
                    '${((aiAnalysis?['confidence'] ?? 0) * 100).toStringAsFixed(1)}%',
                    Colors.blue,
                  ),
                  
                  // Heart Rate
                  _buildAnalysisItem(
                    'Heart Rate',
                    '${aiAnalysis?['heartRate'] ?? 'N/A'} bpm',
                    Colors.red,
                  ),
                  
                  // Rhythm
                  _buildAnalysisItem(
                    'Rhythm',
                    aiAnalysis?['rhythm'] ?? 'Unknown',
                    Colors.green,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          aiAnalysis?['summary'] ?? 'No summary available',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  
                  // Abnormalities (if any)
                  if (aiAnalysis?['abnormalities'] != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Detected Abnormalities',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...((aiAnalysis!['abnormalities'] as List).map((abnormality) =>
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Text(abnormality.toString()),
                            ],
                          ),
                        ),
                    )),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Technical Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Technical Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildAnalysisItem(
                    'Recording Date',
                    _ecgData!['recordingDate'] ?? 'Unknown',
                    Colors.grey,
                  ),
                  
                  _buildAnalysisItem(
                    'Duration',
                    '${_ecgData!['duration'] ?? 'Unknown'} seconds',
                    Colors.grey,
                  ),
                  
                  _buildAnalysisItem(
                    'Sample Rate',
                    '${_ecgData!['sampleRate'] ?? 'Unknown'} Hz',
                    Colors.grey,
                  ),
                  
                  _buildAnalysisItem(
                    'Leads',
                    (_ecgData!['leads'] as List?)?.join(', ') ?? 'Unknown',
                    Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Doctor Review',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          // Override AI Analysis
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _overrideAI,
                        onChanged: (bool? value) {
                          setState(() {
                            _overrideAI = value ?? false;
                          });
                        },
                      ),
                      const Text('Override AI Analysis'),
                    ],
                  ),
                  
                  if (_overrideAI) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedClassification,
                      decoration: const InputDecoration(
                        labelText: 'New Classification',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Normal', 'Abnormal', 'Borderline'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedClassification = newValue;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Diagnosis
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clinical Diagnosis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _diagnosisController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your clinical diagnosis...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recommendations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommendations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _recommendationsController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your recommendations...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Priority
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Priority Level',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPriority,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low Priority')),
                      DropdownMenuItem(value: 'normal', child: Text('Normal Priority')),
                      DropdownMenuItem(value: 'high', child: Text('High Priority')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedPriority = newValue ?? 'normal';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Submit Review Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitReview,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Submit Review',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getClassificationColor(String? classification) {
    switch (classification?.toLowerCase()) {
      case 'normal':
        return const Color(0xFF36D1DC);
      case 'abnormal':
        return const Color(0xFF5B86E5);
      case 'borderline':
        return const Color(0xFF36D1DC);
      default:
        return Colors.grey;
    }
  }

  Future<void> _submitReview() async {
    if (_diagnosisController.text.isEmpty || _recommendationsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      final result = await DoctorService.submitReview(
        requestId: widget.ecgId,
        diagnosis: _diagnosisController.text,
        recommendations: _recommendationsController.text,
        priority: _selectedPriority,
        overrideAI: _overrideAI,
        newClassification: _selectedClassification,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        Navigator.of(context).pop(true); // Return true to indicate review was submitted
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    }
  }
}