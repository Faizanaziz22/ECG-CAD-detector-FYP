import 'package:flutter/material.dart';

class ReviewCaseDialog extends StatefulWidget {
  final Map<String, dynamic> request;
  final Function(Map<String, dynamic>) onReviewSubmitted;

  const ReviewCaseDialog({
    Key? key,
    required this.request,
    required this.onReviewSubmitted,
  }) : super(key: key);

  @override
  State<ReviewCaseDialog> createState() => _ReviewCaseDialogState();
}

class _ReviewCaseDialogState extends State<ReviewCaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String _selectedClassification = '';
  String _selectedSeverity = 'Low';
  bool _requiresFollowUp = false;
  final List<String> _selectedTags = [];

  final List<String> _availableClassifications = [
    'Normal',
    'Abnormal - Arrhythmia',
    'Abnormal - Ischemia',
    'Abnormal - Conduction Block',
    'Abnormal - Other',
    'Inconclusive',
  ];

  final List<String> _severityLevels = ['Low', 'Medium', 'High', 'Critical'];
  
  final List<String> _availableTags = [
    'Atrial Fibrillation',
    'Ventricular Tachycardia',
    'Bradycardia',
    'Tachycardia',
    'ST Elevation',
    'ST Depression',
    'T Wave Abnormality',
    'QRS Widening',
    'AV Block',
    'Bundle Branch Block',
  ];

  @override
  void initState() {
    super.initState();
    _selectedClassification = widget.request['aiAnalysis']['classification'];
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.rate_review,
                  color: Colors.blue[600],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Case Review',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Patient: ${widget.request['patientName']} • ${widget.request['uploadedAt']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // AI Analysis Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'AI Analysis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Classification: ${widget.request['aiAnalysis']['classification']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Confidence: ${(widget.request['aiAnalysis']['confidence'] * 100).toStringAsFixed(1)}%',
                  ),
                  if (widget.request['aiAnalysis']['summary'] != null)
                    Text(
                      'Summary: ${widget.request['aiAnalysis']['summary']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Review Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor's Classification
                      Text(
                        'Your Classification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedClassification,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _availableClassifications.map((classification) {
                          return DropdownMenuItem(
                            value: classification,
                            child: Text(classification),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedClassification = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a classification';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Severity Level
                      Text(
                        'Severity Level',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _severityLevels.map((severity) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(severity),
                                selected: _selectedSeverity == severity,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedSeverity = severity;
                                    });
                                  }
                                },
                                selectedColor: _getSeverityColor(severity),
                                labelStyle: TextStyle(
                                  color: _selectedSeverity == severity
                                      ? Colors.white
                                      : Colors.grey[700],
                                  fontWeight: _selectedSeverity == severity
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Clinical Tags
                      Text(
                        'Clinical Tags',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableTags.map((tag) {
                          return FilterChip(
                            label: Text(tag),
                            selected: _selectedTags.contains(tag),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTags.add(tag);
                                } else {
                                  _selectedTags.remove(tag);
                                }
                              });
                            },
                            selectedColor: Colors.blue[100],
                            checkmarkColor: Colors.blue[600],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Follow-up Required
                      CheckboxListTile(
                        title: const Text('Requires Follow-up'),
                        subtitle: const Text('Patient should schedule follow-up appointment'),
                        value: _requiresFollowUp,
                        onChanged: (value) {
                          setState(() {
                            _requiresFollowUp = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 20),

                      // Clinical Notes
                      Text(
                        'Clinical Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Enter your clinical observations, recommendations, or additional notes...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide clinical notes';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Submit Review',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Low':
        return const Color(0xFF36D1DC);
      case 'Medium':
        return const Color(0xFF5B86E5);
      case 'High':
        return const Color(0xFF5B86E5);
      case 'Critical':
        return const Color(0xFF36D1DC);
      default:
        return Colors.grey[400]!;
    }
  }

  void _submitReview() {
    if (_formKey.currentState!.validate()) {
      final reviewData = {
        'doctorClassification': _selectedClassification,
        'severity': _selectedSeverity,
        'clinicalTags': _selectedTags,
        'requiresFollowUp': _requiresFollowUp,
        'clinicalNotes': _notesController.text.trim(),
        'reviewedBy': 'Dr. Smith', // In real app, get from auth
        'reviewedAt': DateTime.now().toIso8601String(),
        'aiAgreement': _selectedClassification == widget.request['aiAnalysis']['classification'],
      };

      widget.onReviewSubmitted(reviewData);
      Navigator.of(context).pop();
    }
  }
}