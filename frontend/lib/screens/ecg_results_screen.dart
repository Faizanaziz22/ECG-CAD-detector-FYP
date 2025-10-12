import 'package:flutter/material.dart';
import '../models/ecg_record.dart';
import '../services/ecg_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class ECGResultsScreen extends StatefulWidget {
  final ECGRecord ecgRecord;

  const ECGResultsScreen({
    Key? key,
    required this.ecgRecord,
  }) : super(key: key);

  @override
  State<ECGResultsScreen> createState() => _ECGResultsScreenState();
}

class _ECGResultsScreenState extends State<ECGResultsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _reviewMessageController = TextEditingController();
  
  bool _isRequestingReview = false;
  bool _isGeneratingPDF = false;
  bool _isDownloadingPDF = false;
  bool _showReviewForm = false;
  
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _reviewMessageController.dispose();
    super.dispose();
  }

  Future<void> _generatePDFReport() async {
    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      final result = await ECGService.generatePDFReport(widget.ecgRecord.id.toString());
      
      if (result['success'] == true) {
        final pdfInfo = result['pdf'];
        _showSuccessDialog('PDF Report Generated', 
          'Your ECG report has been generated successfully. You can now download it.');
        
        // Optionally auto-download the PDF
        await _downloadPDFReport(pdfInfo['fileName']);
      } else {
        _showErrorDialog('Failed to generate PDF report: ${result['error']}');
      }
    } catch (e) {
      _showErrorDialog('Error generating PDF report: $e');
    } finally {
      setState(() {
        _isGeneratingPDF = false;
      });
    }
  }

  Future<void> _downloadPDFReport(String fileName) async {
    setState(() {
      _isDownloadingPDF = true;
    });

    try {
      final pdfBytes = await ECGService.downloadPDFReport(fileName);
      await _savePDFToDevice(pdfBytes, fileName);
      
      _showSuccessDialog('Download Complete', 
        'PDF report has been saved to your device successfully.');
    } catch (e) {
      _showErrorDialog('Error downloading PDF report: $e');
    } finally {
      setState(() {
        _isDownloadingPDF = false;
      });
    }
  }

  Future<void> _savePDFToDevice(List<int> pdfBytes, String fileName) async {
    try {
      // For web platform, trigger download using browser APIs
      if (kIsWeb) {
        // For web, we'll use a different approach to download files
        // This would typically involve using dart:html or similar web APIs
        // For now, we'll show a message that PDF download is not supported on web
        throw Exception('PDF download not yet implemented for web platform');
      } else {
        // For mobile platforms
        final directory = await getApplicationDocumentsDirectory();
        // Note: File operations would need to be handled differently for web
        throw Exception('File operations need web-compatible implementation');
      }
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  Future<void> _requestDoctorReview() async {
    if (_reviewMessageController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a message for the doctor');
      return;
    }

    setState(() {
      _isRequestingReview = true;
    });

    try {
      await ECGService.requestDoctorReview(
        widget.ecgRecord.id,
        message: _reviewMessageController.text.trim(),
      );

      if (mounted) {
         _showSuccessDialog('Review Request Sent', 'Review request sent successfully!');
         setState(() {
           _showReviewForm = false;
           _reviewMessageController.clear();
         });
       }
    } catch (e) {
      _showErrorDialog('Error requesting review: $e');
    } finally {
      setState(() {
        _isRequestingReview = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
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

  void _showSuccessDialog(String title, String message) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(title),
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

  Color _getClassificationColor() {
    switch (widget.ecgRecord.aiAnalysis.classification.toLowerCase()) {
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

  IconData _getClassificationIcon() {
    switch (widget.ecgRecord.aiAnalysis.classification.toLowerCase()) {
      case 'normal':
        return Icons.check_circle;
      case 'abnormal':
        return Icons.warning;
      case 'borderline':
        return Icons.help;
      default:
        return Icons.info;
    }
  }

  String _getConfidenceLevel() {
    final confidence = widget.ecgRecord.aiAnalysis.confidence;
    if (confidence >= 90) return 'Very High';
    if (confidence >= 80) return 'High';
    if (confidence >= 70) return 'Medium';
    if (confidence >= 60) return 'Moderate';
    return 'Low';
  }

  Color _getConfidenceColor() {
    final confidence = widget.ecgRecord.aiAnalysis.confidence;
    if (confidence >= 80) return const Color(0xFF36D1DC);
    if (confidence >= 60) return const Color(0xFF5B86E5);
    return const Color(0xFF5B86E5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'ECG Analysis Results',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
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
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _isGeneratingPDF || _isDownloadingPDF ? null : _generatePDFReport,
            icon: _isGeneratingPDF 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.download),
            tooltip: 'Generate & Download PDF Report',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics,
                        size: 48,
                        color: _getClassificationColor(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Analysis Complete',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getClassificationColor(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.ecgRecord.fileName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Analyzed on ${widget.ecgRecord.aiAnalysis.analysisDate.day}/${widget.ecgRecord.aiAnalysis.analysisDate.month}/${widget.ecgRecord.aiAnalysis.analysisDate.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Classification Result
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getClassificationIcon(),
                            color: _getClassificationColor(),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Classification',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _getClassificationColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getClassificationColor().withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.ecgRecord.aiAnalysis.classification.toUpperCase(),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _getClassificationColor(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.ecgRecord.aiAnalysis.severityLevel,
                              style: TextStyle(
                                fontSize: 16,
                                color: _getClassificationColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Confidence Score
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.speed,
                            color: _getConfidenceColor(),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Confidence Score',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.ecgRecord.aiAnalysis.confidence}%',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: _getConfidenceColor(),
                                  ),
                                ),
                                Text(
                                  _getConfidenceLevel(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _getConfidenceColor(),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: widget.ecgRecord.aiAnalysis.confidence / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getConfidenceColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // AI Summary
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: Color(0xFF2E7D32),
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'AI Analysis Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          widget.ecgRecord.aiAnalysis.summary,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Doctor Review Section
                if (widget.ecgRecord.hasReview) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.medical_services,
                              color: Color(0xFF5B86E5),
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Doctor Review',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5B86E5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dr. ${widget.ecgRecord.doctorReview!.doctorName}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Reviewed on ${widget.ecgRecord.doctorReview!.reviewDate.day}/${widget.ecgRecord.doctorReview!.reviewDate.month}/${widget.ecgRecord.doctorReview!.reviewDate.year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Diagnosis:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.ecgRecord.doctorReview!.diagnosis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                              if (widget.ecgRecord.doctorReview!.recommendations.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Recommendations:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.ecgRecord.doctorReview!.recommendations,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Request Review Section
                if (!widget.ecgRecord.hasReview && !widget.ecgRecord.isReviewRequested) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.medical_services,
                              color: Color(0xFF5B86E5),
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Doctor Review',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5B86E5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Want a second opinion? Request a manual review from our medical professionals.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!_showReviewForm)
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showReviewForm = true;
                              });
                            },
                            icon: const Icon(Icons.request_quote),
                            label: const Text('Request Doctor Review'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B86E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        if (_showReviewForm) ...[
                          TextField(
                            controller: _reviewMessageController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Describe your symptoms or concerns...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF5B86E5)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isRequestingReview ? null : _requestDoctorReview,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5B86E5),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isRequestingReview
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text('Send Request'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showReviewForm = false;
                                    _reviewMessageController.clear();
                                  });
                                },
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Review Requested Status
                if (widget.ecgRecord.isReviewRequested) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          color: Colors.orange[700],
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Review Requested',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your request has been sent to our medical team. You will be notified when the review is complete.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.orange[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingPDF ? null : _generatePDFReport,
                        icon: _isGeneratingPDF
                             ? const SizedBox(
                                 width: 20,
                                 height: 20,
                                 child: CircularProgressIndicator(
                                   strokeWidth: 2,
                                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                 ),
                               )
                             : const Icon(Icons.picture_as_pdf),
                        label: Text(_isGeneratingPDF ? 'Generating...' : 'Download PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B86E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to Dashboard'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5B86E5),
                          side: const BorderSide(color: Color(0xFF5B86E5)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}