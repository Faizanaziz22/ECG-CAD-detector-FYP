import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class OfflineService {
  static Database? _database;
  static const String _dbName = 'ecg_patient_app.db';
  static const int _dbVersion = 1;
  
  // Singleton pattern
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // ECG Reports table
    await db.execute('''
      CREATE TABLE ecg_reports (
        id TEXT PRIMARY KEY,
        user_email TEXT NOT NULL,
        classification TEXT,
        confidence REAL,
        heart_rate INTEGER,
        status TEXT,
        doctor_reviewed INTEGER DEFAULT 0,
        notes TEXT,
        file_path TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Doctor Reviews table
    await db.execute('''
      CREATE TABLE doctor_reviews (
        id TEXT PRIMARY KEY,
        report_id TEXT,
        user_email TEXT NOT NULL,
        request_date TEXT,
        status TEXT,
        priority TEXT,
        assigned_doctor TEXT,
        review_date TEXT,
        doctor_notes TEXT,
        recommendation TEXT,
        urgency TEXT,
        patient_symptoms TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (report_id) REFERENCES ecg_reports (id)
      )
    ''');

    // User Profile table
    await db.execute('''
      CREATE TABLE user_profile (
        email TEXT PRIMARY KEY,
        name TEXT,
        phone TEXT,
        date_of_birth TEXT,
        emergency_contact TEXT,
        blood_type TEXT,
        allergies TEXT,
        medications TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Sync Queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        data TEXT,
        created_at TEXT,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // App Settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic for future versions
    }
  }

  // ECG Reports CRUD operations
  Future<String> saveECGReport(Map<String, dynamic> report) async {
    final db = await database;
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('current_user_email') ?? '';
    
    final reportData = {
      ...report,
      'user_email': userEmail,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'synced': 0,
    };
    
    await db.insert('ecg_reports', reportData, conflictAlgorithm: ConflictAlgorithm.replace);
    
    // Add to sync queue
    await _addToSyncQueue('ecg_reports', report['id'], 'INSERT', reportData);
    
    // Try to sync if online
    _attemptSync();
    
    return report['id'];
  }

  Future<List<Map<String, dynamic>>> getECGReports({String? userEmail}) async {
    final db = await database;
    final prefs = await SharedPreferences.getInstance();
    final email = userEmail ?? prefs.getString('current_user_email') ?? '';
    
    return await db.query(
      'ecg_reports',
      where: 'user_email = ?',
      whereArgs: [email],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getECGReport(String reportId) async {
    final db = await database;
    final results = await db.query(
      'ecg_reports',
      where: 'id = ?',
      whereArgs: [reportId],
      limit: 1,
    );
    
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateECGReport(String reportId, Map<String, dynamic> updates) async {
    final db = await database;
    
    final updateData = {
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
      'synced': 0,
    };
    
    await db.update(
      'ecg_reports',
      updateData,
      where: 'id = ?',
      whereArgs: [reportId],
    );
    
    // Add to sync queue
    await _addToSyncQueue('ecg_reports', reportId, 'UPDATE', updateData);
    
    _attemptSync();
  }

  // Doctor Reviews CRUD operations
  Future<String> saveDoctorReview(Map<String, dynamic> review) async {
    final db = await database;
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('current_user_email') ?? '';
    
    final reviewData = {
      ...review,
      'user_email': userEmail,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'synced': 0,
    };
    
    await db.insert('doctor_reviews', reviewData, conflictAlgorithm: ConflictAlgorithm.replace);
    
    await _addToSyncQueue('doctor_reviews', review['id'], 'INSERT', reviewData);
    
    _attemptSync();
    
    return review['id'];
  }

  Future<List<Map<String, dynamic>>> getDoctorReviews({String? userEmail}) async {
    final db = await database;
    final prefs = await SharedPreferences.getInstance();
    final email = userEmail ?? prefs.getString('current_user_email') ?? '';
    
    return await db.query(
      'doctor_reviews',
      where: 'user_email = ?',
      whereArgs: [email],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> updateDoctorReview(String reviewId, Map<String, dynamic> updates) async {
    final db = await database;
    
    final updateData = {
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
      'synced': 0,
    };
    
    await db.update(
      'doctor_reviews',
      updateData,
      where: 'id = ?',
      whereArgs: [reviewId],
    );
    
    await _addToSyncQueue('doctor_reviews', reviewId, 'UPDATE', updateData);
    
    _attemptSync();
  }

  // User Profile operations
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    final db = await database;
    
    final profileData = {
      ...profile,
      'updated_at': DateTime.now().toIso8601String(),
      'synced': 0,
    };
    
    await db.insert('user_profile', profileData, conflictAlgorithm: ConflictAlgorithm.replace);
    
    await _addToSyncQueue('user_profile', profile['email'], 'UPSERT', profileData);
    
    _attemptSync();
  }

  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    final db = await database;
    final results = await db.query(
      'user_profile',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    
    return results.isNotEmpty ? results.first : null;
  }

  // Sync Queue operations
  Future<void> _addToSyncQueue(String tableName, String recordId, String action, Map<String, dynamic> data) async {
    final db = await database;
    
    await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'action': action,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
      limit: 50, // Process in batches
    );
  }

  Future<void> markSyncItemCompleted(int syncId) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [syncId]);
  }

  Future<void> incrementSyncRetryCount(int syncId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1 WHERE id = ?',
      [syncId],
    );
  }

  // Connectivity and Sync operations
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _attemptSync() async {
    if (await isOnline()) {
      await syncPendingData();
    }
  }

  Future<void> syncPendingData() async {
    try {
      final pendingItems = await getPendingSyncItems();
      
      for (final item in pendingItems) {
        try {
          // Simulate API call - replace with actual API integration
          await _simulateAPISync(item);
          
          // Mark as completed
          await markSyncItemCompleted(item['id']);
          
          // Update the original record as synced
          await _markRecordSynced(item['table_name'], item['record_id']);
          
        } catch (e) {
          // Increment retry count
          await incrementSyncRetryCount(item['id']);
          
          // Remove from queue if too many retries
          if (item['retry_count'] >= 3) {
            await markSyncItemCompleted(item['id']);
          }
        }
      }
    } catch (e) {
      // Handle sync errors
      print('Sync error: $e');
    }
  }

  Future<void> _simulateAPISync(Map<String, dynamic> syncItem) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In a real app, this would make actual HTTP requests to your backend
    // For now, we'll just simulate success
    print('Syncing ${syncItem['table_name']} - ${syncItem['action']} - ${syncItem['record_id']}');
  }

  Future<void> _markRecordSynced(String tableName, String recordId) async {
    final db = await database;
    
    String whereClause;
    if (tableName == 'user_profile') {
      whereClause = 'email = ?';
    } else {
      whereClause = 'id = ?';
    }
    
    await db.update(
      tableName,
      {'synced': 1},
      where: whereClause,
      whereArgs: [recordId],
    );
  }

  // App Settings operations
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    
    await db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    
    return results.isNotEmpty ? results.first['value'] as String? : null;
  }

  // Utility methods
  Future<void> clearUserData(String userEmail) async {
    final db = await database;
    
    await db.delete('ecg_reports', where: 'user_email = ?', whereArgs: [userEmail]);
    await db.delete('doctor_reviews', where: 'user_email = ?', whereArgs: [userEmail]);
    await db.delete('user_profile', where: 'email = ?', whereArgs: [userEmail]);
  }

  Future<Map<String, int>> getDataCounts(String userEmail) async {
    final db = await database;
    
    final reportsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ecg_reports WHERE user_email = ?', [userEmail]),
    ) ?? 0;
    
    final reviewsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM doctor_reviews WHERE user_email = ?', [userEmail]),
    ) ?? 0;
    
    final pendingSyncCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sync_queue'),
    ) ?? 0;
    
    return {
      'reports': reportsCount,
      'reviews': reviewsCount,
      'pendingSync': pendingSyncCount,
    };
  }

  Future<void> forceSyncAll() async {
    await syncPendingData();
  }

  // Initialize connectivity listener
  void startConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        // Device came online, attempt to sync
        _attemptSync();
      }
    });
  }

  // Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}