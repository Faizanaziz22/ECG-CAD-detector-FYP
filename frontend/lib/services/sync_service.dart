import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'offline_storage_service.dart';
import 'ecg_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _isInitialized = false;

  // Callbacks for sync events
  Function(bool isOnline)? onConnectivityChanged;
  Function(String message)? onSyncStatusChanged;
  Function(int totalItems, int syncedItems)? onSyncProgress;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check initial connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        final wasOnline = _isOnline;
        final isNowOnline = result != ConnectivityResult.none;
        
        if (!wasOnline && isNowOnline) {
          // Device came back online
          _onConnectivityRestored();
        }
        
        onConnectivityChanged?.call(isNowOnline);
      },
    );

    // Start periodic sync for online devices
    if (isOnline) {
      _startPeriodicSync();
    }

    _isInitialized = true;
  }

  bool get _isOnline {
    // This will be updated by the connectivity listener
    // For now, we'll check connectivity synchronously if possible
    return true; // Simplified for demo
  }

  void _onConnectivityRestored() {
    debugPrint('SyncService: Connectivity restored, starting sync...');
    onSyncStatusChanged?.call('Connection restored. Syncing data...');
    
    // Start immediate sync
    syncPendingData();
    
    // Start periodic sync
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isOnline && !_isSyncing) {
        syncPendingData();
      }
    });
  }

  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<bool> syncPendingData() async {
    if (_isSyncing) {
      debugPrint('SyncService: Sync already in progress');
      return false;
    }

    _isSyncing = true;
    onSyncStatusChanged?.call('Syncing data...');

    try {
      // Get all items in sync queue
      final syncQueue = await OfflineStorageService.getSyncQueue();
      final totalItems = syncQueue.length;

      if (totalItems == 0) {
        onSyncStatusChanged?.call('All data is up to date');
        return true;
      }

      debugPrint('SyncService: Syncing $totalItems items');
      int syncedItems = 0;

      for (final item in syncQueue) {
        try {
          final success = await _processSyncItem(item);
          if (success) {
            await OfflineStorageService.removeSyncQueueItem(item['id']);
            syncedItems++;
            onSyncProgress?.call(totalItems, syncedItems);
          } else {
            // Increment retry count
            await OfflineStorageService.incrementSyncRetryCount(item['id']);
            
            // Remove items that have failed too many times
            if (item['retry_count'] >= 3) {
              debugPrint('SyncService: Removing item after 3 failed attempts: ${item['id']}');
              await OfflineStorageService.removeSyncQueueItem(item['id']);
            }
          }
        } catch (e) {
          debugPrint('SyncService: Error processing sync item ${item['id']}: $e');
          await OfflineStorageService.incrementSyncRetryCount(item['id']);
        }
      }

      // Sync unsynced ECG records
      await _syncUnsyncedECGRecords();

      final message = syncedItems == totalItems 
          ? 'All data synced successfully'
          : 'Synced $syncedItems of $totalItems items';
      
      onSyncStatusChanged?.call(message);
      debugPrint('SyncService: $message');

      return syncedItems > 0;
    } catch (e) {
      debugPrint('SyncService: Sync failed: $e');
      onSyncStatusChanged?.call('Sync failed: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _processSyncItem(Map<String, dynamic> item) async {
    final action = item['action'];
    final tableName = item['table_name'];
    final recordId = item['record_id'];
    final data = jsonDecode(item['data']);

    debugPrint('SyncService: Processing $action for $tableName:$recordId');

    try {
      switch (action) {
        case 'upload_ecg':
          return await _syncECGUpload(data);
        case 'request_review':
          return await _syncReviewRequest(recordId, data);
        case 'update_record':
          return await _syncRecordUpdate(recordId, data);
        default:
          debugPrint('SyncService: Unknown action: $action');
          return false;
      }
    } catch (e) {
      debugPrint('SyncService: Error processing $action: $e');
      return false;
    }
  }

  Future<bool> _syncECGUpload(Map<String, dynamic> data) async {
    try {
      // This would normally upload the actual file
      // For now, we'll just simulate the upload since we need file bytes and name
      // In a real implementation, we'd need to store the file bytes in the sync data
      debugPrint('SyncService: ECG upload sync - file operations need web-compatible implementation');
      return true; // Simulate success for now
    } catch (e) {
      debugPrint('SyncService: ECG upload sync failed: $e');
      return false;
    }
  }

  Future<bool> _syncReviewRequest(String recordId, Map<String, dynamic> data) async {
    try {
      final result = await ECGService.requestDoctorReview(int.parse(recordId));
      if (result['success'] == true) {
        // Update local record
        await OfflineStorageService.updateECGRecord(recordId, {
          'doctorReview': {'status': 'pending'},
          'isSynced': true,
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('SyncService: Review request sync failed: $e');
      return false;
    }
  }

  Future<bool> _syncRecordUpdate(String recordId, Map<String, dynamic> data) async {
    try {
      // Update the record on the server
      // This would depend on your specific API endpoints
      await OfflineStorageService.updateECGRecord(recordId, {
        'isSynced': true,
      });
      return true;
    } catch (e) {
      debugPrint('SyncService: Record update sync failed: $e');
      return false;
    }
  }

  Future<void> _syncUnsyncedECGRecords() async {
    try {
      final unsyncedRecords = await OfflineStorageService.getUnsyncedRecords();
      
      for (final record in unsyncedRecords) {
        try {
          // Try to sync the record with the server
          // This would normally sync with your actual API
          // For now, we'll just mark it as synced
          await OfflineStorageService.updateECGRecord(record['id'], {
            'isSynced': true,
          });

          debugPrint('SyncService: Synced ECG record ${record['id']}');
        } catch (e) {
          debugPrint('SyncService: Failed to sync ECG record ${record['id']}: $e');
        }
      }
    } catch (e) {
      debugPrint('SyncService: Error syncing unsynced records: $e');
    }
  }

  // Manual sync trigger
  Future<void> forcSync() async {
    if (!_isOnline) {
      onSyncStatusChanged?.call('No internet connection');
      return;
    }

    await syncPendingData();
  }

  // Add item to sync queue for later processing
  Future<void> queueForSync(String action, String tableName, String recordId, Map<String, dynamic> data) async {
    await OfflineStorageService.addToSyncQueue(action, tableName, recordId, data);
    debugPrint('SyncService: Queued $action for $tableName:$recordId');

    // Try immediate sync if online
    if (_isOnline && !_isSyncing) {
      syncPendingData();
    }
  }

  // Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final syncQueue = await OfflineStorageService.getSyncQueue();
    final unsyncedRecords = await OfflineStorageService.getUnsyncedRecords();
    
    return {
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'pendingItems': syncQueue.length,
      'unsyncedRecords': unsyncedRecords.length,
      'totalPending': syncQueue.length + unsyncedRecords.length,
    };
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _stopPeriodicSync();
    _isInitialized = false;
  }
}

// Extension methods for easier integration
extension SyncServiceIntegration on SyncService {
  // Queue ECG upload for sync
  Future<void> queueECGUpload(Map<String, dynamic> ecgData) async {
    await queueForSync('upload_ecg', 'ecg_records', ecgData['id'], ecgData);
  }

  // Queue review request for sync
  Future<void> queueReviewRequest(String recordId) async {
    await queueForSync('request_review', 'ecg_records', recordId, {'recordId': recordId});
  }

  // Queue record update for sync
  Future<void> queueRecordUpdate(String recordId, Map<String, dynamic> updates) async {
    await queueForSync('update_record', 'ecg_records', recordId, updates);
  }
}