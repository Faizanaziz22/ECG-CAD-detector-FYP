import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'services/notification_manager.dart';
import 'widgets/app_initializer.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/patient_dashboard.dart';
import 'screens/doctor_dashboard.dart';
import 'screens/ecg_upload_screen.dart';
import 'screens/ecg_results_screen.dart';
import 'screens/medical_history_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/notification_preferences_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationManager(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return AppInitializer(
            child: MaterialApp.router(
              title: 'Healthcare App',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                primaryColor: const Color(0xFF5B86E5), // Primary blue
                scaffoldBackgroundColor: const Color(0xFFF4F7FC), // Light background
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF5B86E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B86E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                textTheme: const TextTheme(
                  bodyLarge: TextStyle(color: Color(0xFF222831)),
                  bodyMedium: TextStyle(color: Color(0xFF222831)),
                  titleLarge: TextStyle(color: Color(0xFF222831)),
                  titleMedium: TextStyle(color: Color(0xFF222831)),
                  titleSmall: TextStyle(color: Color(0xFF222831)),
                ),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF5B86E5),
                  primary: const Color(0xFF5B86E5),
                  secondary: const Color(0xFF36D1DC),
                  background: const Color(0xFFF4F7FC),
                  surface: Colors.white,
                  onPrimary: Colors.white,
                  onSecondary: Colors.white,
                  onBackground: const Color(0xFF222831),
                  onSurface: const Color(0xFF222831),
                ),
              ),
              routerConfig: _router(authProvider),
              debugShowCheckedModeBanner: false,
            ),
          );
        },
      ),
    );
  }

  GoRouter _router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final user = authProvider.user;

        // If not authenticated and not on login/signup pages, redirect to login
        if (!isAuthenticated && 
            !state.matchedLocation.startsWith('/login') && 
            !state.matchedLocation.startsWith('/signup')) {
          return '/login';
        }

        // If authenticated and on login/signup pages, redirect to welcome
        if (isAuthenticated && 
            (state.matchedLocation.startsWith('/login') || 
             state.matchedLocation.startsWith('/signup'))) {
          return '/welcome';
        }

        // Role-based access control
        if (isAuthenticated && user != null) {
          if (state.matchedLocation.startsWith('/patient') && !user.isPatient) {
            return user.isDoctor ? '/doctor' : '/login';
          }
          if (state.matchedLocation.startsWith('/doctor') && !user.isDoctor) {
            return user.isPatient ? '/patient' : '/login';
          }
        }

        return null; // No redirect needed
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/patient',
          builder: (context, state) => const PatientDashboard(),
        ),
        GoRoute(
          path: '/doctor',
          builder: (context, state) => const DoctorDashboard(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/notification-preferences',
          builder: (context, state) => const NotificationPreferencesScreen(),
        ),
        GoRoute(
              path: '/ecg-upload',
              builder: (context, state) => const ECGUploadScreen(),
            ),
            GoRoute(
              path: '/medical-history',
              builder: (context, state) => const MedicalHistoryScreen(),
            ),
      ],
    );
  }
}