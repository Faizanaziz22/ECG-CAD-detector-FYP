import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineStorageService {
  static Database? _database;
  static const String _databaseName = 'healthcare_app.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _ecgRecordsTable = 'ecg_records';
  static const String _syncQueueTable = 'sync_queue';
  static const String _notificationsTable = 'notifications';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // ECG Records table
    await db.execute('''
      CREATE TABLE $_ecgRecordsTable (
        id TEXT PRIMARY KEY,
        filename TEXT NOT NULL,
        upload_date TEXT NOT NULL,
        type TEXT NOT NULL,
        classification TEXT,
        confidence REAL,
        heart_rate INTEGER,
        status TEXT NOT NULL,
        ai_analysis TEXT,
        doctor_review TEXT,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Sync Queue table
    await db.execute('''
      CREATE TABLE $_syncQueueTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE $_notificationsTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT NOT NULL,
        data TEXT,
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
  }

  // ECG Records operations
  static Future<void> saveECGRecord(Map<String, dynamic> record) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final recordData = {
      'id': record['id'],
      'filename': record['filename'] ?? '',
      'upload_date': record['uploadDate'] ?? record['date'] ?? now,
      'type': record['type'] ?? 'upload',
      'classification': record['aiAnalysis']?['classification'] ?? record['classification'],
      'confidence': record['aiAnalysis']?['confidence'] ?? record['confidence'],
      'heart_rate': record['aiAnalysis']?['heartRate'] ?? record['heartRate'],
      'status': record['status'] ?? 'pending',
      'ai_analysis': record['aiAnalysis'] != null ? jsonEncode(record['aiAnalysis']) : null,
      'doctor_review': record['doctorReview'] != null ? jsonEncode(record['doctorReview']) : null,
      'is_synced': record['isSynced'] == true ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    };

    await db.insert(
      _ecgRecordsTable,
      recordData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getECGRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> records = await db.query(
      _ecgRecordsTable,
      orderBy: 'upload_date DESC',
    );

    return records.map((record) {
      return {
        'id': record['id'],
        'filename': record['filename'],
        'uploadDate': record['upload_date'],
        'date': record['upload_date'].split('T')[0],
        'time': _formatTime(record['upload_date']),
        'type': record['type'],
        'classification': record['classification'],
        'confidence': record['confidence'],
        'heartRate': record['heart_rate'],
        'status': record['status'],
        'aiAnalysis': record['ai_analysis'] != null 
            ? jsonDecode(record['ai_analysis']) 
            : null,
        'doctorReview': record['doctor_review'] != null 
            ? jsonDecode(record['doctor_review']) 
            : null,
        'isSynced': record['is_synced'] == 1,
      };
    }).toList();
  }

  static Future<Map<String, dynamic>?> getECGRecord(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> records = await db.query(
      _ecgRecordsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (records.isEmpty) return null;

    final record = records.first;
    return {
      'id': record['id'],
      'filename': record['filename'],
      'uploadDate': record['upload_date'],
      'date': record['upload_date'].split('T')[0],
      'time': _formatTime(record['upload_date']),
      'type': record['type'],
      'classification': record['classification'],
      'confidence': record['confidence'],
      'heartRate': record['heart_rate'],
      'status': record['status'],
      'aiAnalysis': record['ai_analysis'] != null 
          ? jsonDecode(record['ai_analysis']) 
          : null,
      'doctorReview': record['doctor_review'] != null 
          ? jsonDecode(record['doctor_review']) 
          : null,
      'isSynced': record['is_synced'] == 1,
    };
  }

  static Future<void> updateECGRecord(String id, Map<String, dynamic> updates) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final updateData = <String, dynamic>{
      'updated_at': now,
    };

    if (updates.containsKey('status')) {
      updateData['status'] = updates['status'];
    }
    if (updates.containsKey('doctorReview')) {
      updateData['doctor_review'] = jsonEncode(updates['doctorReview']);
    }
    if (updates.containsKey('isSynced')) {
      updateData['is_synced'] = updates['isSynced'] == true ? 1 : 0;
    }

    await db.update(
      _ecgRecordsTable,
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
    final db = await database;
    return await db.query(
      _ecgRecordsTable,
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  // Sync Queue operations
  static Future<void> addToSyncQueue(String action, String tableName, String recordId, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(_syncQueueTable, {
      'action': action,
      'table_name': tableName,
      'record_id': recordId,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query(
      _syncQueueTable,
      orderBy: 'created_at ASC',
    );
  }

  static Future<void> removeSyncQueueItem(int id) async {
    final db = await database;
    await db.delete(
      _syncQueueTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> incrementSyncRetryCount(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $_syncQueueTable SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  // Notifications operations
  static Future<void> saveNotification(Map<String, dynamic> notification) async {
    final db = await database;
    await db.insert(
      _notificationsTable,
      {
        'id': notification['id'],
        'title': notification['title'],
        'body': notification['body'],
        'type': notification['type'],
        'data': notification['data'] != null ? jsonEncode(notification['data']) : null,
        'is_read': notification['isRead'] == true ? 1 : 0,
        'created_at': notification['createdAt'] ?? DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> notifications = await db.query(
      _notificationsTable,
      orderBy: 'created_at DESC',
    );

    return notifications.map((notification) {
      return {
        'id': notification['id'],
        'title': notification['title'],
        'body': notification['body'],
        'type': notification['type'],
        'data': notification['data'] != null ? jsonDecode(notification['data']) : null,
        'isRead': notification['is_read'] == 1,
        'createdAt': notification['created_at'],
      };
    }).toList();
  }

  static Future<void> markNotificationAsRead(String id) async {
    final db = await database;
    await db.update(
      _notificationsTable,
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Utility methods
  static String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (e) {
      return 'Unknown';
    }
  }

  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_ecgRecordsTable);
    await db.delete(_syncQueueTable);
    await db.delete(_notificationsTable);
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}