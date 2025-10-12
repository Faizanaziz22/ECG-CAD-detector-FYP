import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import '../providers/auth_provider.dart';
import '../services/ecg_service.dart';
import '../services/offline_storage_service.dart';
import '../services/sync_service.dart';
import '../services/enhanced_notification_service.dart';
import '../widgets/notification_badge.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  List<Map<String, dynamic>> _ecgHistory = [];
  bool _isLoadingHistory = true;
  bool _isUploading = false;
  bool _isRecording = false;
  Map<String, dynamic>? _latestAnalysis;
  int _totalUploads = 0;
  int _pendingReviews = 0;
  int _completedReviews = 0;
  String _lastUploadDate = 'Never';

  // Offline support variables
  bool _isOnline = true;
  bool _isSyncing = false;
  String _syncStatus = 'All data is up to date';
  int _pendingSyncItems = 0;
  
  // Services
  late SyncService _syncService;
  late EnhancedNotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    
    // Verify user is authenticated and has correct role
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated || authProvider.user?.role != 'patient') {
        context.go('/login');
      } else {
        _loadDashboardData();
      }
    });
  }

  Future<void> _initializeServices() async {
    // Initialize services
    _syncService = SyncService();
    _notificationService = EnhancedNotificationService();
    
    // Initialize notification service
    await _notificationService.initialize();
    
    // Set up sync service callbacks
    _syncService.onConnectivityChanged = (isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    };
    
    _syncService.onSyncStatusChanged = (status) {
      if (mounted) {
        setState(() {
          _syncStatus = status;
        });
      }
    };
    
    _syncService.onSyncProgress = (total, synced) {
      if (mounted) {
        setState(() {
          _isSyncing = synced < total;
          _pendingSyncItems = total - synced;
        });
      }
    };
    
    // Initialize sync service
    await _syncService.initialize();
    
    // Get initial sync status
    final syncStatus = await _syncService.getSyncStatus();
    if (mounted) {
      setState(() {
        _isOnline = syncStatus['isOnline'] ?? true;
        _isSyncing = syncStatus['isSyncing'] ?? false;
        _pendingSyncItems = syncStatus['totalPending'] ?? 0;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoadingHistory = true);
    
    await Future.wait([
      _loadECGHistory(),
      _loadDashboardStats(),
    ]);
    
    setState(() => _isLoadingHistory = false);
  }

  Future<void> _loadECGHistory() async {
    try {
      if (_isOnline) {
        // Try to load from server when online
        final result = await ECGService.getECGHistory();
        if (mounted && result['success'] == true) {
          final serverRecords = List<Map<String, dynamic>>.from(result['records'] ?? []);
          
          // Save to offline storage
          for (final record in serverRecords) {
            await OfflineStorageService.saveECGRecord(record);
          }
          
          setState(() {
            _ecgHistory = serverRecords;
            if (_ecgHistory.isNotEmpty) {
              _latestAnalysis = _ecgHistory.first;
            }
          });
        }
      } else {
        // Load from offline storage when offline
        final offlineRecords = await OfflineStorageService.getECGRecords();
        if (mounted) {
          setState(() {
            _ecgHistory = offlineRecords;
            if (_ecgHistory.isNotEmpty) {
              _latestAnalysis = _ecgHistory.first;
            }
          });
        }
      }
    } catch (e) {
      // Fallback to offline storage on error
      try {
        final offlineRecords = await OfflineStorageService.getECGRecords();
        if (mounted) {
          setState(() {
            _ecgHistory = offlineRecords;
            if (_ecgHistory.isNotEmpty) {
              _latestAnalysis = _ecgHistory.first;
            }
          });
        }
      } catch (offlineError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading ECG history: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      // Simulate loading dashboard statistics
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _totalUploads = _ecgHistory.length;
          _pendingReviews = _ecgHistory.where((record) => 
            record['doctorReview']?['status'] == 'pending').length;
          _completedReviews = _ecgHistory.where((record) => 
            record['doctorReview']?['status'] == 'completed').length;
          _lastUploadDate = _ecgHistory.isNotEmpty 
              ? _ecgHistory.first['uploadDate'] ?? 'Unknown'
              : 'Never';
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _uploadECGFile() async {
    try {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = '.txt,.csv,.dat,.ecg';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          
          reader.onLoadEnd.listen((e) async {
            setState(() => _isUploading = true);

            final fileBytes = Uint8List.fromList(reader.result as List<int>);
             final filename = file.name;
             
             // Create ECG record
             final recordId = 'ecg_${DateTime.now().millisecondsSinceEpoch}';
             final ecgRecord = {
               'id': recordId,
               'filename': filename,
               'uploadDate': DateTime.now().toIso8601String(),
               'type': 'upload',
               'status': 'processing',
               'aiAnalysis': {
                 'classification': 'Processing...',
                 'confidence': 0.0,
                 'summary': 'AI analysis in progress...',
                 'heartRate': 0,
                 'rhythm': 'Unknown',
               },
               'isSynced': false,
             };

             // Save to offline storage immediately
             await OfflineStorageService.saveECGRecord(ecgRecord);
             
             if (_isOnline) {
               try {
                 // Try to upload to server
                 final uploadResult = await ECGService.uploadECGFile(fileBytes, filename);
                 
                 if (uploadResult['success'] == true) {
                   // Update record with server response
                   final serverRecord = uploadResult['data'] ?? uploadResult;
                   await OfflineStorageService.saveECGRecord({
                     ...ecgRecord,
                     ...serverRecord,
                     'isSynced': true,
                   });
                   
                   // Show success notification
                   await _notificationService.showReportReadyNotification(recordId, filename);
                   
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(
                       content: Text('ECG file uploaded successfully! AI analysis complete.'),
                       backgroundColor: Colors.green,
                       duration: Duration(seconds: 3),
                     ),
                   );
                 } else {
                   throw Exception(uploadResult['error'] ?? 'Upload failed');
                 }
               } catch (e) {
                 // Queue for sync when online
                 await _syncService.queueECGUpload(ecgRecord);
                 
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(
                     content: Text('ECG saved offline. Will sync when connection is restored.'),
                     backgroundColor: Colors.orange,
                     duration: Duration(seconds: 3),
                   ),
                 );
               }
             } else {
               // Queue for sync when online
               await _syncService.queueECGUpload(ecgRecord);
               
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                   content: Text('ECG saved offline. Will sync when connection is restored.'),
                   backgroundColor: Colors.orange,
                   duration: Duration(seconds: 3),
                 ),
               );
             }
             
             // Refresh the dashboard to show new data
             await _loadDashboardData();
           });
         }
       });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _simulateECGRecording() async {
    setState(() => _isRecording = true);
    
    try {
      // Simulate recording process
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recording ECG... ${i * 10}%'),
              duration: const Duration(milliseconds: 400),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }

      // Simulate successful recording with a delay
      await Future.delayed(const Duration(seconds: 2));
      final recordResult = {'success': true, 'message': 'Recording completed'};
      
      if (recordResult['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ECG recording completed! AI analysis in progress...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Refresh the dashboard to show new data
        await _loadDashboardData();
      } else {
        throw Exception(recordResult['error'] ?? 'Recording failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _requestDoctorReview(Map<String, dynamic> record) async {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.medical_services, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text('Request Doctor Review'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send this ECG report to your assigned doctor for professional review.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message to Doctor (Optional)',
                  hintText: 'Describe any symptoms or concerns...',
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
                try {
                  final reviewData = {
                    'recordId': record['id'],
                    'message': messageController.text.trim(),
                    'requestDate': DateTime.now().toIso8601String(),
                  };

                  if (_isOnline) {
                    try {
                      final result = await ECGService.requestDoctorReview(
                        record['id'],
                        message: messageController.text.trim(),
                      );

                      if (result['success'] == true) {
                        // Update local record
                        await OfflineStorageService.updateECGRecord(record['id'], {
                          'doctorReview': {'status': 'pending'},
                          'isSynced': true,
                        });
                        
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Review request sent to doctor successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadDashboardData(); // Refresh data
                      } else {
                        throw Exception(result['error'] ?? 'Failed to send request');
                      }
                    } catch (e) {
                      // Queue for sync when online
                      await _syncService.queueForSync('review_request', 'ecg_records', record['id'], reviewData);
                      
                      // Update local record
                      await OfflineStorageService.updateECGRecord(record['id'], {
                        'doctorReview': {'status': 'pending'},
                        'isSynced': false,
                      });
                      
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Review request saved offline. Will sync when connection is restored.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      _loadDashboardData();
                    }
                  } else {
                    // Queue for sync when online
                    await _syncService.queueForSync('review_request', 'ecg_records', record['id'], reviewData);
                    
                    // Update local record
                    await OfflineStorageService.updateECGRecord(record['id'], {
                      'doctorReview': {'status': 'pending'},
                      'isSynced': false,
                    });
                    
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Review request saved offline. Will sync when connection is restored.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    _loadDashboardData();
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
              icon: const Icon(Icons.send),
              label: const Text('Send Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadReport(Map<String, dynamic> record) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF report...'),
          backgroundColor: Colors.blue,
        ),
      );

      final result = await ECGService.generatePDFReport(record['id'].toString());
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result['error'] ?? 'Download failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReportDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text('ECG Analysis Report'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Upload Information
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
                            Icon(Icons.upload_file, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Upload Information',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('File: ${record['fileName'] ?? 'Unknown'}'),
                        Text('Date: ${record['uploadDate'] ?? 'Unknown'}'),
                        Text('Size: ${record['fileSize'] ?? 'Unknown'}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AI Analysis Results
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: record['aiAnalysis']['classification'] == 'Abnormal' 
                          ? Colors.red[50] 
                          : Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: record['aiAnalysis']['classification'] == 'Abnormal' 
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
                              Icons.psychology,
                              color: record['aiAnalysis']['classification'] == 'Abnormal' 
                                  ? Colors.red[700] 
                                  : Colors.green[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI Analysis Results',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: record['aiAnalysis']['classification'] == 'Abnormal' 
                                    ? Colors.red[800] 
                                    : Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: record['aiAnalysis']['classification'] == 'Abnormal' 
                                    ? Colors.red[100] 
                                    : Colors.green[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                record['aiAnalysis']['classification'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: record['aiAnalysis']['classification'] == 'Abnormal' 
                                      ? Colors.red[800] 
                                      : Colors.green[800],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Confidence: ${(record['aiAnalysis']['confidence'] * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (record['aiAnalysis']['summary'] != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Summary:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record['aiAnalysis']['summary'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Doctor Review (if available)
                  if (record['doctorReview'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B86E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF5B86E5).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.medical_services, color: const Color(0xFF5B86E5), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Doctor Review',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF5B86E5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (record['doctorReview']['diagnosis'] != null) ...[
                            Text(
                              'Diagnosis:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              record['doctorReview']['diagnosis'],
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (record['doctorReview']['recommendations'] != null) ...[
                            Text(
                              'Recommendations:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              record['doctorReview']['recommendations'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _downloadReport(record);
              },
              icon: const Icon(Icons.download),
              label: const Text('Download PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
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

  Widget _buildSyncStatusIndicator() {
    if (!_isOnline || _pendingSyncItems == 0) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          if (_isSyncing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.sync, color: Colors.orange[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isSyncing 
                  ? 'Syncing data...' 
                  : '$_pendingSyncItems items pending sync',
              style: TextStyle(
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!_isSyncing)
            TextButton(
              onPressed: () => _syncService.syncPendingData(),
              child: const Text('Sync Now'),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectivityIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            size: 16,
            color: _isOnline ? Colors.green[700] : Colors.red[700],
          ),
          const SizedBox(width: 4),
          Text(
            _isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _isOnline ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FC),
          appBar: AppBar(
            title: Row(
              children: [
                const Text(
                  'Patient Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _buildConnectivityIndicator(),
              ],
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
            backgroundColor: Colors.transparent,
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
                    if (_pendingReviews > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$_pendingReviews',
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

                  // Sync Status Indicator
                  _buildSyncStatusIndicator(),

                  // Enhanced Statistics Overview
                  _buildStatisticsOverview(),
                  const SizedBox(height: 24),

                  // Latest Analysis Card (if available)
                  if (_latestAnalysis != null) ...[
                    _buildLatestAnalysisCard(),
                    const SizedBox(height: 24),
                  ],

                  // ECG Actions Section
                  _buildECGActionsSection(),
                  const SizedBox(height: 24),

                  // ECG History Section
                  _buildECGHistorySection(),
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
            color: const Color(0xFF5B86E5).withOpacity(0.3),
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
                  user?.name.substring(0, 1).toUpperCase() ?? 'P',
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
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    user?.name ?? 'Patient',
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
                      'Heart Health Monitoring',
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
          'Health Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF222831),
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total ECGs',
                value: '$_totalUploads',
                subtitle: 'Uploaded',
                icon: Icons.favorite,
                color: const Color(0xFF5B86E5),
                trend: 'Last: $_lastUploadDate',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Pending Reviews',
                value: '$_pendingReviews',
                subtitle: 'Doctor review',
                icon: Icons.pending_actions,
                color: const Color(0xFF36D1DC),
                trend: 'Awaiting response',
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
                color: const Color(0xFF5B86E5),
                trend: 'Professional reviewed',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Health Score',
                value: _latestAnalysis != null 
                    ? '${(_latestAnalysis!['aiAnalysis']['confidence'] * 100).toInt()}%'
                    : 'N/A',
                subtitle: 'AI confidence',
                icon: Icons.analytics,
                color: const Color(0xFF36D1DC),
                trend: _latestAnalysis?['aiAnalysis']['classification'] ?? 'No data',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLatestAnalysisCard() {
    final analysis = _latestAnalysis!;
    final isAbnormal = analysis['aiAnalysis']['classification'] == 'Abnormal';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAbnormal ? const Color(0xFF5B86E5) : const Color(0xFF36D1DC),
          width: 2,
        ),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAbnormal ? const Color(0xFF5B86E5).withOpacity(0.1) : const Color(0xFF36D1DC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isAbnormal ? Icons.warning : Icons.check_circle,
                  color: isAbnormal ? const Color(0xFF5B86E5) : const Color(0xFF36D1DC),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Latest ECG Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222831),
                      ),
                    ),
                    Text(
                      'Uploaded: ${analysis['uploadDate'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isAbnormal ? const Color(0xFF5B86E5) : const Color(0xFF36D1DC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  analysis['aiAnalysis']['classification'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF36D1DC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Confidence',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(analysis['aiAnalysis']['confidence'] * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
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
                    color: const Color(0xFF5B86E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        analysis['doctorReview']?['status']?.toString().toUpperCase() ?? 'PENDING',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5B86E5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          if (analysis['aiAnalysis']['summary'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Summary:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    analysis['aiAnalysis']['summary'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showReportDetails(analysis),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B86E5),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: analysis['doctorReview']?['status'] == 'pending' 
                      ? null 
                      : () => _requestDoctorReview(analysis),
                  icon: const Icon(Icons.medical_services),
                  label: const Text('Request Review'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF36D1DC),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildECGActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ECG Management',
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
                icon: Icons.upload_file,
                title: 'Upload ECG',
                subtitle: 'From device file',
                color: const Color(0xFF3B82F6),
                isLoading: _isUploading,
                onTap: _isUploading ? null : _uploadECGFile,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.radio_button_checked,
                title: 'Record ECG',
                subtitle: 'Simulate recording',
                color: const Color(0xFFEF4444),
                isLoading: _isRecording,
                onTap: _isRecording ? null : _simulateECGRecording,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildECGHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ECG History',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            if (_ecgHistory.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_ecgHistory.length} records',
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

        if (_isLoadingHistory)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_ecgHistory.isEmpty)
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
                  Icons.favorite_border,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ECG Records Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload your first ECG file or record one to get started with AI analysis.',
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
          ..._ecgHistory.take(5).map((record) => _buildHistoryCard(record)).toList(),
          
        if (_ecgHistory.length > 5) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                // Show all history - could navigate to a separate page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Full history view coming soon!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: Text('View All ${_ecgHistory.length} Records'),
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
            const SizedBox(width: 16),
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
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
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
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Icon(icon, color: color, size: 24),
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

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    final isAbnormal = record['aiAnalysis']['classification'] == 'Abnormal';
    final confidence = (record['aiAnalysis']['confidence'] * 100).toStringAsFixed(1);
    final reviewStatus = record['doctorReview']?['status'] ?? 'pending';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAbnormal ? Colors.red[200]! : Colors.grey[200]!,
          width: isAbnormal ? 2 : 1,
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
                    color: isAbnormal ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isAbnormal ? Icons.warning : Icons.check_circle,
                    color: isAbnormal ? Colors.red[700] : Colors.green[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['fileName'] ?? 'ECG Record',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Uploaded: ${record['uploadDate'] ?? 'Unknown'}',
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
                    color: _getStatusColor(reviewStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reviewStatus.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(reviewStatus),
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
                      color: isAbnormal ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Classification',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          record['aiAnalysis']['classification'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isAbnormal ? Colors.red[700] : Colors.green[700],
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
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confidence',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$confidence%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
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
                    onPressed: () => _showReportDetails(record),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadReport(record),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: reviewStatus == 'pending' 
                        ? null 
                        : () => _requestDoctorReview(record),
                    icon: const Icon(Icons.medical_services, size: 16),
                    label: const Text('Review', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B86E5),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF36D1DC);
      case 'pending':
        return const Color(0xFF5B86E5);
      case 'reviewed':
        return const Color(0xFF36D1DC);
      default:
        return Colors.grey;
    }
  }

  void _onStatusUpdate(Map<String, dynamic> status) {
    if (mounted) {
      setState(() {
        _isOnline = status['isOnline'];
        _isSyncing = status['isSyncing'];
        _pendingSyncItems = status['totalPending'];
      });
    }
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }
}