// ECG Patient App widget tests.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecg_patient_app/main.dart';

void main() {
  group('ECG Patient App Tests', () {
    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('App launches and shows login screen when not authenticated', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const ECGPatientApp());
      await tester.pumpAndSettle();

      // Verify that login screen is displayed
      expect(find.text('ECG Patient Login'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('Login form validation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const ECGPatientApp());
      await tester.pumpAndSettle();

      // Try to login without entering credentials
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Verify validation messages appear
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Navigation to registration screen works', (WidgetTester tester) async {
      await tester.pumpWidget(const ECGPatientApp());
      await tester.pumpAndSettle();

      // Tap on "Don't have an account? Register" link
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Verify registration screen is displayed
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
    });

    testWidgets('App shows home screen when authenticated', (WidgetTester tester) async {
      // Mock authenticated state
      SharedPreferences.setMockInitialValues({
        'isLoggedIn': true,
        'userEmail': 'test@example.com',
        'userName': 'Test User',
      });

      await tester.pumpWidget(const ECGPatientApp());
      await tester.pumpAndSettle();

      // Verify home screen is displayed with bottom navigation
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
      expect(find.text('Results'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });
  });
}
