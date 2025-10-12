import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_manager.dart';
import '../providers/auth_provider.dart';

class AppInitializer extends StatefulWidget {
  final Widget child;

  const AppInitializer({Key? key, required this.child}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _initializeApp() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationManager = Provider.of<NotificationManager>(context, listen: false);

    // Start notification polling when user is authenticated
    if (authProvider.isAuthenticated) {
      notificationManager.startPolling();
    }

    // Listen to auth changes to start/stop polling
    authProvider.addListener(() {
      if (authProvider.isAuthenticated) {
        notificationManager.startPolling();
      } else {
        notificationManager.stopPolling();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}