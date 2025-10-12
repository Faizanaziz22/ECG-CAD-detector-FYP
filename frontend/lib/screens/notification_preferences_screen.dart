import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/notification_categories.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _pushNotificationsEnabled = true;
  final Map<NotificationCategory, bool> _categorySettings = {};
  
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _soundEnabled = prefs.getBool('notification_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notification_vibration') ?? true;
      _pushNotificationsEnabled = prefs.getBool('push_notifications') ?? true;
      
      // Load category preferences
      for (final category in NotificationCategory.values) {
        _categorySettings[category] = prefs.getBool('category_${category.name}') ?? true;
      }
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // General Settings Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive notifications on this device'),
                    value: _pushNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _pushNotificationsEnabled = value;
                      });
                      _savePreference('push_notifications', value);
                    },
                    secondary: const Icon(Icons.notifications),
                  ),
                  SwitchListTile(
                    title: const Text('Sound'),
                    subtitle: const Text('Play sound for new notifications'),
                    value: _soundEnabled,
                    onChanged: _pushNotificationsEnabled ? (value) {
                      setState(() {
                        _soundEnabled = value;
                      });
                      _savePreference('notification_sound', value);
                    } : null,
                    secondary: const Icon(Icons.volume_up),
                  ),
                  SwitchListTile(
                    title: const Text('Vibration'),
                    subtitle: const Text('Vibrate for new notifications'),
                    value: _vibrationEnabled,
                    onChanged: _pushNotificationsEnabled ? (value) {
                      setState(() {
                        _vibrationEnabled = value;
                      });
                      _savePreference('notification_vibration', value);
                    } : null,
                    secondary: const Icon(Icons.vibration),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Category Settings Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Categories',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose which types of notifications you want to receive',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...NotificationCategory.values.map((category) {
                    return SwitchListTile(
                      title: Text(NotificationCategoryHelper.getCategoryName(category)),
                      subtitle: Text(_getCategoryDescription(category)),
                      value: _categorySettings[category] ?? true,
                      onChanged: _pushNotificationsEnabled ? (value) {
                        setState(() {
                          _categorySettings[category] = value;
                        });
                        _savePreference('category_${category.name}', value);
                      } : null,
                      secondary: Icon(
                        NotificationCategoryHelper.getCategoryIcon(category),
                        color: NotificationCategoryHelper.getCategoryColor(category),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quiet Hours Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiet Hours',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Disable non-urgent notifications during these hours',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    leading: Icon(Icons.bedtime),
                    title: Text('Enable Quiet Hours'),
                    subtitle: Text('Coming soon'),
                    trailing: Switch(
                      value: false,
                      onChanged: null, // Disabled for now
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Reset Button
          Center(
            child: OutlinedButton.icon(
              onPressed: _resetToDefaults,
              icon: const Icon(Icons.restore),
              label: const Text('Reset to Defaults'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryDescription(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.urgent:
        return 'Critical alerts that require immediate attention';
      case NotificationCategory.medical:
        return 'ECG results, diagnoses, and medical updates';
      case NotificationCategory.appointment:
        return 'Appointment reminders and scheduling updates';
      case NotificationCategory.reminder:
        return 'Medication and general reminders';
      case NotificationCategory.system:
        return 'App updates and system messages';
      case NotificationCategory.info:
        return 'General information and tips';
      case NotificationCategory.success:
        return 'Confirmation and success messages';
      case NotificationCategory.warning:
        return 'Important warnings and alerts';
      case NotificationCategory.error:
        return 'Error messages and issues';
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Preferences'),
        content: const Text('Are you sure you want to reset all notification preferences to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all notification preferences
      await prefs.remove('notification_sound');
      await prefs.remove('notification_vibration');
      await prefs.remove('push_notifications');
      
      for (final category in NotificationCategory.values) {
        await prefs.remove('category_${category.name}');
      }
      
      // Reload preferences
      await _loadPreferences();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences reset to defaults'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}