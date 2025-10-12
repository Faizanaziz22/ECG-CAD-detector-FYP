import 'package:flutter/material.dart';
import '../services/doctor_service.dart';

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({Key? key}) : super(key: key);

  @override
  State<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _assignedPatients = [];
  List<Map<String, dynamic>> _availablePatients = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assignedResult = await DoctorService.getAssignedPatients();
      final availableResult = await DoctorService.getAvailablePatients();

      if (assignedResult['success'] && availableResult['success']) {
        setState(() {
          _assignedPatients = List<Map<String, dynamic>>.from(assignedResult['patients']);
          _availablePatients = List<Map<String, dynamic>>.from(availableResult['patients']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = assignedResult['error'] ?? availableResult['error'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load patient data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _assignPatient(String patientId) async {
    try {
      final result = await DoctorService.assignPatient(patientId: patientId);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        _loadPatientData(); // Refresh the data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign patient: $e')),
      );
    }
  }

  Future<void> _unassignPatient(String patientId) async {
    try {
      final result = await DoctorService.unassignPatient(patientId);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        _loadPatientData(); // Refresh the data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unassign patient: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _filterPatients(List<Map<String, dynamic>> patients) {
    if (_searchQuery.isEmpty) return patients;
    
    return patients.where((patient) {
      final name = patient['name']?.toString().toLowerCase() ?? '';
      final email = patient['email']?.toString().toLowerCase() ?? '';
      final id = patient['id']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || email.contains(query) || id.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatientData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Assigned Patients'),
            Tab(text: 'Available Patients'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients by name, email, or ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Tab Content
          Expanded(
            child: _isLoading
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
                              _error!,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadPatientData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAssignedPatientsTab(),
                          _buildAvailablePatientsTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedPatientsTab() {
    final filteredPatients = _filterPatients(_assignedPatients);
    
    if (filteredPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No assigned patients match your search'
                  : 'No assigned patients yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = filteredPatients[index];
        return _buildPatientCard(patient, isAssigned: true);
      },
    );
  }

  Widget _buildAvailablePatientsTab() {
    final filteredPatients = _filterPatients(_availablePatients);
    
    if (filteredPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No available patients match your search'
                  : 'No available patients',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = filteredPatients[index];
        return _buildPatientCard(patient, isAssigned: false);
      },
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient, {required bool isAssigned}) {
    final name = patient['name'] ?? 'Unknown Patient';
    final email = patient['email'] ?? '';
    final age = patient['age']?.toString() ?? '';
    final gender = patient['gender'] ?? '';
    final lastActivity = patient['lastActivity'] ?? '';
    final ecgCount = patient['ecgCount']?.toString() ?? '0';
    final riskLevel = patient['riskLevel'] ?? 'low';
    
    Color riskColor = Colors.green;
    IconData riskIcon = Icons.check_circle;
    
    switch (riskLevel.toLowerCase()) {
      case 'high':
        riskColor = Colors.red;
        riskIcon = Icons.warning;
        break;
      case 'medium':
        riskColor = Colors.orange;
        riskIcon = Icons.info;
        break;
      case 'low':
      default:
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(riskIcon, size: 16, color: riskColor),
                      const SizedBox(width: 4),
                      Text(
                        riskLevel.toUpperCase(),
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Patient Details
            Row(
              children: [
                if (age.isNotEmpty) ...[
                  Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('$age years', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 16),
                ],
                if (gender.isNotEmpty) ...[
                  Icon(
                    gender.toLowerCase() == 'male' ? Icons.male : Icons.female,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(gender, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 16),
                ],
                Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('$ecgCount ECGs', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            
            if (lastActivity.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Last activity: $lastActivity',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
                if (isAssigned) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showPatientDetails(patient),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _unassignPatient(patient['id']),
                      icon: const Icon(Icons.person_remove),
                      label: const Text('Unassign'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showPatientDetails(patient),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _assignPatient(patient['id']),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Assign'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(patient['name'] ?? 'Patient Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', patient['email'] ?? 'N/A'),
              _buildDetailRow('Age', patient['age']?.toString() ?? 'N/A'),
              _buildDetailRow('Gender', patient['gender'] ?? 'N/A'),
              _buildDetailRow('Phone', patient['phone'] ?? 'N/A'),
              _buildDetailRow('Risk Level', patient['riskLevel'] ?? 'N/A'),
              _buildDetailRow('ECG Count', patient['ecgCount']?.toString() ?? '0'),
              _buildDetailRow('Last Activity', patient['lastActivity'] ?? 'N/A'),
              if (patient['medicalHistory'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Medical History:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(patient['medicalHistory']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}