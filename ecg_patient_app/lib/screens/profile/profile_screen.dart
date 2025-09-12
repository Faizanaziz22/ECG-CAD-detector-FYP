import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, String> _userInfo = {};
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _userInfo = {
        'name': prefs.getString('user_name') ?? 'John Doe',
        'email': prefs.getString('current_user_email') ?? 'john.doe@example.com',
        'phone': prefs.getString('user_phone') ?? '+1 (555) 123-4567',
        'dateOfBirth': prefs.getString('user_dob') ?? '1990-01-01',
        'bloodType': prefs.getString('blood_type') ?? 'O+',
        'allergies': prefs.getString('allergies') ?? 'None',
        'medications': prefs.getString('medications') ?? 'None',
      };
      
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _selectedLanguage = prefs.getString('selected_language') ?? 'English';
      _selectedTheme = prefs.getString('selected_theme') ?? 'Light';
      
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('biometric_enabled', _biometricEnabled);
    await prefs.setString('selected_language', _selectedLanguage);
    await prefs.setString('selected_theme', _selectedTheme);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userInfo: _userInfo),
      ),
    );
    
    if (result != null) {
      setState(() {
        _userInfo = result;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        _userInfo['name']?.split(' ').where((n) => n.isNotEmpty).map((n) => n[0]).join('') ?? 'JD',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userInfo['name'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userInfo['email'] ?? '',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Personal Information
            _buildSectionCard(
              'Personal Information',
              [
                _buildInfoTile(Icons.phone, 'Phone', _userInfo['phone'] ?? ''),
                _buildInfoTile(Icons.cake, 'Date of Birth', _userInfo['dateOfBirth'] ?? ''),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Medical Information
            _buildSectionCard(
              'Medical Information',
              [
                _buildInfoTile(Icons.bloodtype, 'Blood Type', _userInfo['bloodType'] ?? ''),
                _buildInfoTile(Icons.warning, 'Allergies', _userInfo['allergies'] ?? ''),
                _buildInfoTile(Icons.medication, 'Current Medications', _userInfo['medications'] ?? ''),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // App Settings
            _buildSectionCard(
              'App Settings',
              [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: const Text('Biometric Authentication'),
                  trailing: Switch(
                    value: _biometricEnabled,
                    onChanged: (value) {
                      setState(() {
                        _biometricEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  trailing: DropdownButton<String>(
                    value: _selectedLanguage,
                    items: ['English', 'Spanish', 'French', 'German']
                        .map((lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                        _saveSettings();
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Theme'),
                  trailing: DropdownButton<String>(
                    value: _selectedTheme,
                    items: ['Light', 'Dark', 'System']
                        .map((theme) => DropdownMenuItem(
                              value: theme,
                              child: Text(theme),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTheme = value;
                        });
                        _saveSettings();
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Support & About
            _buildSectionCard(
              'Support & About',
              [
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showHelpDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showPrivacyDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About App'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showAboutDialog();
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value.isEmpty ? 'Not specified' : value),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Frequently Asked Questions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Q: How do I upload ECG data?'),
                Text('A: Go to the ECG Upload tab and select a file or record new data.'),
                SizedBox(height: 8),
                Text('Q: How accurate are the AI results?'),
                Text('A: Our AI has high accuracy but should not replace professional medical advice.'),
                SizedBox(height: 8),
                Text('Q: Can I share reports with my doctor?'),
                Text('A: Yes, you can download PDF reports and share them.'),
                SizedBox(height: 16),
                Text(
                  'Contact Support:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Email: support@ecgapp.com'),
                Text('Phone: +1 (555) 123-HELP'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: const SingleChildScrollView(
            child: Text(
              'ECG Patient App Privacy Policy\n\n'
              'We are committed to protecting your privacy and ensuring the security of your medical data.\n\n'
              'Data Collection:\n'
              '• We collect ECG data and personal information you provide\n'
              '• Usage data to improve our services\n\n'
              'Data Usage:\n'
              '• ECG analysis and medical insights\n'
              '• Communication with healthcare providers\n'
              '• App functionality and improvements\n\n'
              'Data Security:\n'
              '• All data is encrypted in transit and at rest\n'
              '• HIPAA compliant storage and processing\n'
              '• Regular security audits and updates\n\n'
              'Your Rights:\n'
              '• Access, modify, or delete your data\n'
              '• Opt-out of data collection\n'
              '• Request data portability\n\n'
              'Contact us at privacy@ecgapp.com for any privacy concerns.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About ECG Patient App'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ECG Patient App',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text('Version: 1.0.0'),
                Text('Build: 2024.01.001'),
                SizedBox(height: 16),
                Text(
                  'Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• ECG data upload and recording'),
                Text('• AI-powered analysis'),
                Text('• Medical history tracking'),
                Text('• PDF report generation'),
                Text('• Doctor review requests'),
                Text('• Offline data caching'),
                Text('• Push notifications'),
                SizedBox(height: 16),
                Text(
                  'Developed with Flutter',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 8),
                Text('© 2024 ECG Patient App. All rights reserved.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final Map<String, String> userInfo;
  
  const EditProfileScreen({super.key, required this.userInfo});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bloodTypeController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userInfo['name']);
    _phoneController = TextEditingController(text: widget.userInfo['phone']);
    _bloodTypeController = TextEditingController(text: widget.userInfo['bloodType']);
    _allergiesController = TextEditingController(text: widget.userInfo['allergies']);
    _medicationsController = TextEditingController(text: widget.userInfo['medications']);
    
    if (widget.userInfo['dateOfBirth']?.isNotEmpty == true) {
      _selectedDate = DateTime.tryParse(widget.userInfo['dateOfBirth']!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final updatedInfo = {
        'name': _nameController.text.trim(),
        'email': widget.userInfo['email']!, // Email cannot be changed
        'phone': _phoneController.text.trim(),
        'dateOfBirth': _selectedDate?.toIso8601String().split('T')[0] ?? '',
        'bloodType': _bloodTypeController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'medications': _medicationsController.text.trim(),
      };
      
      // Save to SharedPreferences
      await prefs.setString('user_name', updatedInfo['name']!);
      await prefs.setString('user_phone', updatedInfo['phone']!);
      await prefs.setString('user_dob', updatedInfo['dateOfBirth']!);
      await prefs.setString('blood_type', updatedInfo['bloodType']!);
      await prefs.setString('allergies', updatedInfo['allergies']!);
      await prefs.setString('medications', updatedInfo['medications']!);
      
      if (mounted) {
        Navigator.of(context).pop(updatedInfo);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select date of birth',
                    style: TextStyle(
                      color: _selectedDate != null ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _bloodTypeController,
                decoration: const InputDecoration(
                  labelText: 'Blood Type',
                  prefixIcon: Icon(Icons.bloodtype),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Allergies',
                  prefixIcon: Icon(Icons.warning),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _medicationsController,
                decoration: const InputDecoration(
                  labelText: 'Current Medications',
                  prefixIcon: Icon(Icons.medication),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}