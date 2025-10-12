import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'api_service.dart';

class ECGService {
  static ECGService? _instance;
  static ECGService get instance => _instance ??= ECGService._();
  
  ECGService._();
  
  final ApiService _apiService = ApiService.instance;
  
  // Upload ECG file for analysis
  Future<ECGResult> uploadECG({
    required File file,
    String? notes,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiService.uploadFile(
        '/ecg/upload',
        file,
        additionalFields: {
          if (notes != null) 'notes': notes,
          if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
          if (metadata != null) 'metadata': jsonEncode(metadata),
        },
      );
      
      if (response.success && response.data != null) {
        return ECGResult(
          success: true,
          message: response.message,
          record: response.data['record'],
        );
      }
      
      return ECGResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ECGResult(
        success: false,
        message: 'ECG upload failed: ${e.toString()}',
      );
    }
  }
  
  // Upload ECG data from bytes
  Future<ECGResult> uploadECGFromBytes({
    required Uint8List bytes,
    required String fileName,
    String? notes,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiService.uploadFileFromBytes(
        '/ecg/upload',
        bytes: bytes,
        fileName: fileName,
        additionalFields: {
          if (notes != null) 'notes': notes,
          if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
          if (metadata != null) 'metadata': jsonEncode(metadata),
        },
      );
      
      if (response.success && response.data != null) {
        return ECGResult(
          success: true,
          message: response.message,
          record: response.data['record'],
        );
      }
      
      return ECGResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ECGResult(
        success: false,
        message: 'ECG upload failed: ${e.toString()}',
      );
    }
  }
  
  // Get all ECG records for current user
  Future<ECGListResult> getECGRecords({
    int page = 1,
    int limit = 10,
    String? status,
    String? sortBy,
    String? sortOrder,
    String? search,
    List<String>? tags,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortOrder != null) 'sortOrder': sortOrder,
        if (search != null) 'search': search,
        if (tags != null) 'tags': tags.join(','),
      };
      
      final response = await _apiService.get('/ecg', queryParams: queryParams);
      
      if (response.success && response.data != null) {
        return ECGListResult(
          success: true,
          message: response.message,
          records: List<Map<String, dynamic>>.from(response.data['records'] ?? []),
          pagination: response.data['pagination'],
        );
      }
      
      return ECGListResult(
        success: false,
        message: response.message,
        records: [],
      );
    } catch (e) {
      return ECGListResult(
        success: false,
        message: 'Failed to load ECG records: ${e.toString()}',
        records: [],
      );
    }
  }
  
  // Get specific ECG record by ID
  Future<ECGResult> getECGRecord(String recordId) async {
    try {
      final response = await _apiService.get('/ecg/$recordId');
      
      if (response.success && response.data != null) {
        return ECGResult(
          success: true,
          message: response.message,
          record: response.data['record'],
        );
      }
      
      return ECGResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ECGResult(
        success: false,
        message: 'Failed to load ECG record: ${e.toString()}',
      );
    }
  }
  
  // Update ECG record
  Future<ECGResult> updateECGRecord({
    required String recordId,
    String? notes,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (notes != null) body['notes'] = notes;
      if (tags != null) body['tags'] = tags;
      if (metadata != null) body['metadata'] = metadata;
      
      final response = await _apiService.put('/ecg/$recordId', body: body);
      
      if (response.success && response.data != null) {
        return ECGResult(
          success: true,
          message: response.message,
          record: response.data['record'],
        );
      }
      
      return ECGResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ECGResult(
        success: false,
        message: 'Failed to update ECG record: ${e.toString()}',
      );
    }
  }
  
  // Delete ECG record
  Future<ECGResult> deleteECGRecord(String recordId) async {
    try {
      final response = await _apiService.delete('/ecg/$recordId');
      
      return ECGResult(
        success: response.success,
        message: response.message,
      );
    } catch (e) {
      return ECGResult(
        success: false,
        message: 'Failed to delete ECG record: ${e.toString()}',
      );
    }
  }
  
  // Request reanalysis of ECG record
  Future<ECGResult> reanalyzeECG(String recordId) async {
    try {
      final response = await _apiService.post('/ecg/$recordId/reanalyze');
      
      if (response.success && response.data != null) {
        return ECGResult(
          success: true,
          message: response.message,
          record: response.data['record'],
        );
      }
      
      return ECGResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ECGResult(
        success: false,
        message: 'Failed to reanalyze ECG: ${e.toString()}',
      );
    }
  }
  
  // Get ECG statistics
  Future<ECGStatsResult> getECGStats() async {
    try {
      final response = await _apiService.get('/ecg/stats');
      
      if (response.success && response.data != null) {
        return ECGStatsResult(
          success: true,
          message: response.message,
          stats: response.data['stats'],
        );
      }
      
      return ECGStatsResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ECGStatsResult(
        success: false,
        message: 'Failed to load ECG statistics: ${e.toString()}',
      );
    }
  }
  
  // Share ECG record
  Future<ECGResult> shareECGRecord({
    required String recordId,
    required String shareWith,
    String? message,
    DateTime? expiresAt,
  }) async {
    try {
      final response = await _apiService.post('/ecg/$recordId/share', body: {
        'shareWith': shareWith,
        if (message != null) 'message': message,
        if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
      });
      
      if (response.success && response.data != null) {
        return ECGResult(
          success: true,
          message: response.message,
          record: response.data['record'],
        );
      }
      
      return ECGResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ECGResult(
        success: false,
        message: 'Failed to share ECG record: ${e.toString()}',
      );
    }
  }
  
  // Export ECG record
  Future<ECGExportResult> exportECGRecord({
    required String recordId,
    String format = 'pdf',
    bool includeAnalysis = true,
    bool includeRawData = false,
  }) async {
    try {
      final response = await _apiService.get('/ecg/$recordId/export', queryParams: {
        'format': format,
        'includeAnalysis': includeAnalysis.toString(),
        'includeRawData': includeRawData.toString(),
      });
      
      if (response.success && response.data != null) {
        return ECGExportResult(
          success: true,
          message: response.message,
          downloadUrl: response.data['downloadUrl'],
          fileName: response.data['fileName'],
        );
      }
      
      return ECGExportResult(
        success: false,
        message: response.message,
      );
    } catch (e) {
      return ECGExportResult(
        success: false,
        message: 'Failed to export ECG record: ${e.toString()}',
      );
    }
  }
}

class ECGResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? record;
  
  ECGResult({
    required this.success,
    required this.message,
    this.record,
  });
  
  @override
  String toString() {
    return 'ECGResult(success: $success, message: $message)';
  }
}

class ECGListResult {
  final bool success;
  final String message;
  final List<Map<String, dynamic>> records;
  final Map<String, dynamic>? pagination;
  
  ECGListResult({
    required this.success,
    required this.message,
    required this.records,
    this.pagination,
  });
  
  @override
  String toString() {
    return 'ECGListResult(success: $success, message: $message, recordCount: ${records.length})';
  }
}

class ECGStatsResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? stats;
  
  ECGStatsResult({
    required this.success,
    required this.message,
    this.stats,
  });
  
  @override
  String toString() {
    return 'ECGStatsResult(success: $success, message: $message)';
  }
}

class ECGExportResult {
  final bool success;
  final String message;
  final String? downloadUrl;
  final String? fileName;
  
  ECGExportResult({
    required this.success,
    required this.message,
    this.downloadUrl,
    this.fileName,
  });
  
  @override
  String toString() {
    return 'ECGExportResult(success: $success, message: $message)';
  }
}