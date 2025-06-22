import 'package:flutter/material.dart';
import 'package:ecg_cad_detector/res/colors/app_colors.dart';
import 'package:ecg_cad_detector/view/home/home_screen.dart';
import 'package:ecg_cad_detector/view/patient/patient_screen.dart';
import 'package:ecg_cad_detector/view/report/report_screen.dart';
import 'package:ecg_cad_detector/view/setting/setting_screen.dart';

class CustomUserNavBar extends StatefulWidget {
  @override
  _CustomUserNavBarState createState() => _CustomUserNavBarState();
}

class _CustomUserNavBarState extends State<CustomUserNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    PatientScreen(),
    ReportScreen(),
    SettingScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.lightBlue,
        unselectedItemColor: Colors.white,
        backgroundColor: AppColors.darkBlue,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Setting',
          ),
        ],
      ),
    );
  }
}
