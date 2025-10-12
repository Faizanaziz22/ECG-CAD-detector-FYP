import 'package:flutter/material.dart';
import '../models/ecg_record.dart';
import '../services/ecg_service.dart';
import 'ecg_results_screen.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({Key? key}) : super(key: key);

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  List<ECGRecord> _ecgHistory = [];
  List<ECGRecord> _filteredHistory = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = ['All', 'Normal', 'Abnormal', 'Borderline', 'Reviewed', 'Pending Review'];

  @override
  void initState() {
    super.initState();
    _loadECGHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadECGHistory() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await ECGService.getECGHistory();
      
      if (response['success'] == true) {
        final List<dynamic> historyData = response['data'];
        setState(() {
          _ecgHistory = historyData.map((data) => ECGRecord.fromJson(data)).toList();
          _filteredHistory = List.from(_ecgHistory);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load medical history: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterHistory() {
    setState(() {
      _filteredHistory = _ecgHistory.where((record) {
        // Search filter
        bool matchesSearch = _searchQuery.isEmpty ||
            record.fileName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            record.aiAnalysis.classification.toLowerCase().contains(_searchQuery.toLowerCase());

        // Category filter
        bool matchesFilter = _selectedFilter == 'All' ||
            (_selectedFilter == 'Normal' && record.aiAnalysis.classification.toLowerCase() == 'normal') ||
            (_selectedFilter == 'Abnormal' && record.aiAnalysis.classification.toLowerCase() == 'abnormal') ||
            (_selectedFilter == 'Borderline' && record.aiAnalysis.classification.toLowerCase() == 'borderline') ||
            (_selectedFilter == 'Reviewed' && record.hasReview) ||
            (_selectedFilter == 'Pending Review' && record.isReviewRequested && !record.hasReview);

        return matchesSearch && matchesFilter;
      }).toList();

      // Sort by upload date (newest first)
      _filteredHistory.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterHistory();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterHistory();
  }

  Color _getClassificationColor(String classification) {
    switch (classification.toLowerCase()) {
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

  IconData _getClassificationIcon(String classification) {
    switch (classification.toLowerCase()) {
      case 'normal':
        return Icons.check_circle;
      case 'abnormal':
        return Icons.warning;
      case 'borderline':
        return Icons.help;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
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

  Widget _buildECGCard(ECGRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ECGResultsScreen(ecgRecord: record),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getClassificationIcon(record.aiAnalysis.classification),
                    color: _getClassificationColor(record.aiAnalysis.classification),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.fileName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${record.uploadDate.day}/${record.uploadDate.month}/${record.uploadDate.year}',
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
                      color: _getClassificationColor(record.aiAnalysis.classification).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getClassificationColor(record.aiAnalysis.classification).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      record.aiAnalysis.classification.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getClassificationColor(record.aiAnalysis.classification),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Confidence: ${record.aiAnalysis.confidence}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (record.hasReview)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF36D1DC).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF36D1DC).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: const Color(0xFF36D1DC),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reviewed',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF36D1DC),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (record.isReviewRequested)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B86E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF5B86E5).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 14,
                            color: const Color(0xFF5B86E5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pending',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF5B86E5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (record.aiAnalysis.summary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record.aiAnalysis.summary,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Medical History',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF5B86E5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadECGHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B86E5)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadECGHistory,
              color: const Color(0xFF5B86E5),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Cards
                    Row(
                      children: [
                        _buildStatCard(
                          'Total',
                          _ecgHistory.length.toString(),
                          const Color(0xFF5B86E5),
                          Icons.analytics,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'Normal',
                          _ecgHistory.where((r) => r.aiAnalysis.classification.toLowerCase() == 'normal').length.toString(),
                          const Color(0xFF36D1DC),
                          Icons.check_circle,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'Abnormal',
                          _ecgHistory.where((r) => r.aiAnalysis.classification.toLowerCase() == 'abnormal').length.toString(),
                          const Color(0xFF5B86E5),
                          Icons.warning,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Search and Filter Section
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search by filename or classification...',
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF5B86E5)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF5B86E5)),
                                ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _filterOptions.map((filter) {
                                final isSelected = _selectedFilter == filter;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(filter),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) _onFilterChanged(filter);
                                    },
                                    selectedColor: const Color(0xFF5B86E5).withOpacity(0.2),
                                    checkmarkColor: const Color(0xFF5B86E5),
                                    labelStyle: TextStyle(
                                      color: isSelected ? const Color(0xFF5B86E5) : Colors.grey[700],
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Results Header
                    Row(
                      children: [
                        Text(
                          'ECG Records',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_filteredHistory.length} result${_filteredHistory.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ECG Records List
                    if (_filteredHistory.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No ECG records found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filter criteria',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...(_filteredHistory.map((record) => _buildECGCard(record)).toList()),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}