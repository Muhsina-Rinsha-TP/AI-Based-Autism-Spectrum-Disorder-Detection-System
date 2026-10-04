import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isTablet;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF6B5B95),
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: TextStyle(
          fontSize: isTablet ? 14 : 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: isTablet ? 12 : 11,
        ),
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined, size: isTablet ? 28 : 24),
            activeIcon: Icon(Icons.dashboard, size: isTablet ? 28 : 24),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file_outlined, size: isTablet ? 28 : 24),
            activeIcon: Icon(Icons.upload_file, size: isTablet ? 28 : 24),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined, size: isTablet ? 28 : 24),
            activeIcon: Icon(Icons.quiz, size: isTablet ? 28 : 24),
            label: 'Questionnaire',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined, size: isTablet ? 28 : 24),
            activeIcon: Icon(Icons.medical_services, size: isTablet ? 28 : 24),
            label: 'Doctors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: isTablet ? 28 : 24),
            activeIcon: Icon(Icons.person, size: isTablet ? 28 : 24),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}