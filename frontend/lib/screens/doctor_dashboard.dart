import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/doctor_service.dart';
import '../services/notification_manager.dart';
import '../widgets/notification_badge.dart';
import '../widgets/ecg_waveform_viewer.dart';
import '../widgets/review_case_dialog.dart';
import '../screens/ecg_viewer_screen.dart';
import 'patient_management_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  List<Map<String, dynamic>> _reviewRequests = [];
  List<Map<String, dynamic>> _assignedPatients = [];
  bool _isLoadingRequests = true;
  bool _isLoadingPatients = true;
  int _totalPatients = 0;
  int _pendingReviews = 0;
  int _completedReviews = 0;
  int _urgentCases = 0;
  String _lastReviewDate = 'Never';

  @override
  void initState() {
    super.initState();
    // Verify user is authenticated and has correct role
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated || authProvider.user?.role != 'doctor') {
        context.go('/login');
      } else {
        _loadDashboardData();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoadingRequests = true;
      _isLoadingPatients = true;
    });
    
    await Future.wait([
      _loadReviewRequests(),
      _loadAssignedPatients(),
      _loadDashboardStats(),
    ]);
    
    setState(() {
      _isLoadingRequests = false;
      _isLoadingPatients = false;
    });
  }

  Future<void> _loadReviewRequests() async {
    try {
      final result = await DoctorService.getReviewRequests();
      if (mounted && result['success'] == true) {
        setState(() {
          _reviewRequests = List<Map<String, dynamic>>.from(result['requests'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading review requests: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAssignedPatients() async {
    try {
      final result = await DoctorService.getAssignedPatients();
      if (mounted && result['success'] == true) {
        setState(() {
          _assignedPatients = List<Map<String, dynamic>>.from(result['patients'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading assigned patients: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      // Simulate loading dashboard statistics
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _totalPatients = _assignedPatients.length;
          _pendingReviews = _reviewRequests.where((request) => 
            request['status'] == 'pending').length;
          _completedReviews = _reviewRequests.where((request) => 
            request['status'] == 'completed').length;
          _urgentCases = _reviewRequests.where((request) => 
            request['priority'] == 'urgent' && request['status'] == 'pending').length;
          _lastReviewDate = _reviewRequests.isNotEmpty 
              ? _reviewRequests.first['requestDate'] ?? 'Unknown'
              : 'Never';
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Enhanced case review method with annotations
  void _reviewECGCase(Map<String, dynamic> request) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReviewCaseDialog(
        request: request,
        onReviewSubmitted: (reviewData) {
          setState(() {
            // Update the request with review data
            request['doctorReview'] = reviewData;
            request['status'] = 'Reviewed';
            request['reviewedAt'] = DateTime.now().toIso8601String();
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Case review submitted successfully'),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  Future<void> _viewECGWaveform(Map<String, dynamic> request) async {
    // Navigate to dedicated ECG viewer screen for better visualization
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ECGViewerScreen(
          ecgId: request['id'] ?? 'unknown',
          patientName: request['patientName'] ?? 'Unknown Patient',
          initialData: request,
        ),
      ),
    );
  }

  Future<void> _viewECGWaveformDialog(Map<String, dynamic> request) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.show_chart, color: Colors.blue[700], size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ECG Waveform Analysis',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Patient: ${request['patientName'] ?? 'Unknown'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Patient and File Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recording Details',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('File: ${request['fileName'] ?? 'ECG_Recording.dat'}'),
                            Text('Date: ${request['requestDate'] ?? 'Unknown'}'),
                            const Text('Duration: 10 seconds'),
                            const Text('Sample Rate: 500 Hz'),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Heart Rate',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[800],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${60 + (request['id'].hashCode % 40)} bpm',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lead II',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Enhanced ECG Waveform Display with real ECGWaveformViewer
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ECGWaveformViewer(
                        waveformData: ECGDataGenerator.generateSampleECG(
                          duration: 10,
                          heartRate: 60 + (request['id'].hashCode % 40),
                          pattern: request['aiAnalysis']['classification'] == 'Abnormal' 
                              ? ECGPattern.atrial_fibrillation 
                              : ECGPattern.normal,
                        ),
                        leadName: 'Lead II',
                        height: double.infinity,
                        interactive: true,
                        showGrid: true,
                        waveformColor: Colors.green[400]!,
                        onTimeSelected: (time) {
                          // Handle time selection for annotations
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Analysis Summary with enhanced layout
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: request['aiAnalysis']['classification'] == 'Abnormal' 
                        ? Colors.red[50] 
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: request['aiAnalysis']['classification'] == 'Abnormal' 
                          ? Colors.red[200]! 
                          : Colors.green[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            request['aiAnalysis']['classification'] == 'Abnormal' 
                                ? Icons.warning_rounded 
                                : Icons.check_circle_rounded,
                            color: request['aiAnalysis']['classification'] == 'Abnormal' 
                                ? Colors.red[700] 
                                : Colors.green[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Analysis Results',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: request['aiAnalysis']['classification'] == 'Abnormal' 
                                        ? Colors.red[800] 
                                        : Colors.green[800],
                                  ),
                                ),
                                Text(
                                  'Classification: ${request['aiAnalysis']['classification']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: request['aiAnalysis']['classification'] == 'Abnormal' 
                                  ? Colors.red[100] 
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(request['aiAnalysis']['confidence'] * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: request['aiAnalysis']['classification'] == 'Abnormal' 
                                    ? Colors.red[800] 
                                    : Colors.green[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (request['aiAnalysis']['summary'] != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            request['aiAnalysis']['summary'],
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _reviewECGCase(request);
                        },
                        icon: const Icon(Icons.rate_review),
                        label: const Text('Review Case'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _assignPatient() async {
    final patientIdController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person_add, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('Assign Patient'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: patientIdController,
                decoration: const InputDecoration(
                  labelText: 'Patient ID or Email',
                  hintText: 'Enter patient identifier...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Assignment Notes (Optional)',
                  hintText: 'Reason for assignment, monitoring instructions...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (patientIdController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a patient ID or email'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final result = await DoctorService.assignPatient(
                    patientId: patientIdController.text.trim(),
                    notes: notesController.text.trim(),
                  );

                  if (result['success'] == true) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Patient assigned successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadDashboardData(); // Refresh data
                  } else {
                    throw Exception(result['error'] ?? 'Failed to assign patient');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Assign Patient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF36D1DC),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      context.go('/login');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Doctor Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
                ),
              ),
            ),
            foregroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              NotificationIcon(
                onTap: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.refresh),
                    if (_urgentCases > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B86E5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$_urgentCases',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: _loadDashboardData,
                tooltip: 'Refresh Dashboard',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _showLogoutDialog,
                tooltip: 'Logout',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Welcome Card
                  _buildWelcomeCard(user),
                  const SizedBox(height: 24),

                  // Enhanced Statistics Overview
                  _buildStatisticsOverview(),
                  const SizedBox(height: 24),

                  // Urgent Cases Alert (if any)
                  if (_urgentCases > 0) ...[
                    _buildUrgentCasesAlert(),
                    const SizedBox(height: 24),
                  ],

                  // Review Requests Section
                  _buildReviewRequestsSection(),
                  const SizedBox(height: 24),

                  // Patient Management Section
                  _buildPatientManagementSection(),
                  const SizedBox(height: 24),

                  // Quick Actions Section
                  _buildQuickActionsSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF36D1DC).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(35),
              ),
              child: Center(
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'D',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Dr.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    user?.name ?? 'Doctor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Cardiology Specialist',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
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
    );
  }

  Widget _buildStatisticsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Practice Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Patients',
                value: '$_totalPatients',
                subtitle: 'Assigned',
                icon: Icons.people,
                color: const Color(0xFF36D1DC),
                trend: 'Active monitoring',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Pending Reviews',
                value: '$_pendingReviews',
                subtitle: 'Awaiting review',
                icon: Icons.pending_actions,
                color: const Color(0xFF5B86E5),
                trend: 'Requires attention',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Completed',
                value: '$_completedReviews',
                subtitle: 'Reviews done',
                icon: Icons.check_circle,
                color: const Color(0xFF36D1DC),
                trend: 'This month',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Urgent Cases',
                value: '$_urgentCases',
                subtitle: 'High priority',
                icon: Icons.warning,
                color: const Color(0xFF5B86E5),
                trend: 'Immediate attention',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUrgentCasesAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF5B86E5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5B86E5).withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B86E5).withOpacity(0.1),
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
              color: const Color(0xFF5B86E5).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning,
              color: Color(0xFF5B86E5),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Urgent Cases Alert',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B86E5),
                  ),
                ),
                Text(
                  'You have $_urgentCases urgent ECG cases requiring immediate attention.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF222831),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Scroll to review requests or filter urgent cases
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Showing urgent cases in review section'),
                  backgroundColor: Color(0xFF5B86E5),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B86E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Review Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Review Requests',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            if (_reviewRequests.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_reviewRequests.length} requests',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoadingRequests)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_reviewRequests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32.0),
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
                  Icons.inbox,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Review Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All caught up! No pending ECG reviews at the moment.',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._reviewRequests.take(5).map((request) => _buildReviewRequestCard(request)).toList(),
          
        if (_reviewRequests.length > 5) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Full review queue coming soon!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: Text('View All ${_reviewRequests.length} Requests'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPatientManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Patient Management',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _assignPatient,
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Assign Patient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoadingPatients)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_assignedPatients.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32.0),
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
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Assigned Patients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start by assigning patients to monitor their heart health.',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._assignedPatients.take(3).map((patient) => _buildPatientCard(patient)).toList(),
          
        if (_assignedPatients.length > 3) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Full patient list coming soon!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('View All ${_assignedPatients.length} Patients'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.people,
                title: 'Patient Management',
                subtitle: 'Assign & track patients',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientManagementScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'View alerts',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications feature coming soon!'),
                      backgroundColor: Color(0xFFF59E0B),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'App preferences',
                color: const Color(0xFF6B7280),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings page coming soon!'),
                      backgroundColor: Color(0xFF6B7280),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(), // Empty space for symmetry
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trend,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRequestCard(Map<String, dynamic> request) {
    final isUrgent = request['priority'] == 'urgent';
    final isAbnormal = request['aiAnalysis']['classification'] == 'Abnormal';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? Colors.red[300]! : Colors.grey[200]!,
          width: isUrgent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUrgent ? Colors.red[100] : Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isUrgent ? Icons.warning : Icons.person,
                    color: isUrgent ? Colors.red[700] : Colors.blue[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['patientName'] ?? 'Unknown Patient',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Requested: ${request['requestDate'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'URGENT',
                      style: TextStyle(
                        color: Colors.red[800],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAbnormal ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAbnormal ? Colors.red[200]! : Colors.green[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isAbnormal ? Icons.warning : Icons.check_circle,
                    color: isAbnormal ? Colors.red[700] : Colors.green[700],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Classification: ${request['aiAnalysis']['classification']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Confidence: ${(request['aiAnalysis']['confidence'] * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewECGWaveform(request),
                    icon: const Icon(Icons.show_chart, size: 16),
                    label: const Text('View ECG', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B86E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reviewECGCase(request),
                    icon: const Icon(Icons.rate_review, size: 16),
                    label: const Text('Review', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF36D1DC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 32),
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

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final lastECGDate = patient['lastECGDate'] ?? 'Never';
    final totalECGs = patient['totalECGs'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF36D1DC).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    color: const Color(0xFF36D1DC),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient['name'] ?? 'Unknown Patient',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Age: ${patient['age'] ?? 'Unknown'} • Assigned: ${patient['assignedDate'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B86E5).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalECGs ECGs',
                    style: TextStyle(
                      color: const Color(0xFF5B86E5),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last ECG',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lastECGDate,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          patient['status'] ?? 'Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF36D1DC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Patient history view coming soon!'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('History', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B86E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Patient communication coming soon!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Contact', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF36D1DC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 32),
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
}

// Custom painters for ECG visualization
class ECGGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..strokeWidth = 0.5;

    // Draw grid lines
    for (double i = 0; i < size.width; i += 10) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 10) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ECGWaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green[400]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerY = size.height / 2;
    
    // Generate a simple ECG-like waveform
    path.moveTo(0, centerY);
    
    for (double x = 0; x < size.width; x += 2) {
      double y = centerY;
      
      // Create ECG pattern (simplified)
      final cycle = (x % 200) / 200;
      if (cycle < 0.1) {
        // P wave
        y += 10 * (cycle / 0.1) * (1 - cycle / 0.1);
      } else if (cycle < 0.2) {
        // PR segment
        y += 0;
      } else if (cycle < 0.25) {
        // Q wave
        y -= 5;
      } else if (cycle < 0.3) {
        // R wave
        y += 40 * ((cycle - 0.25) / 0.05);
      } else if (cycle < 0.35) {
        // S wave
        y -= 20 * ((cycle - 0.3) / 0.05);
      } else if (cycle < 0.5) {
        // ST segment
        y += 0;
      } else if (cycle < 0.7) {
        // T wave
        y += 15 * ((cycle - 0.5) / 0.2) * (1 - (cycle - 0.5) / 0.2);
      }
      
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}