import 'package:autism_project/screens/userdashbordscreen.dart';
import 'package:autism_project/widget/bottomnavbar.dart';
import 'package:autism_project/widget/chatbot/chatbot_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home/doctor_screen.dart';
import 'home/profile_screen.dart';
import 'home/questinar_screen.dart';
import 'home/upload_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const UploadScreen(),
    const QuestionnaireScreen(),
    const DoctorsScreen(),
    const ProfileScreen(),
  ];

  void _navigateToChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatbotPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],

          // Floating Chatbot Button - Positioned at bottom right
          Positioned(
            bottom: isTablet ? 90 : 80, // Above bottom navbar
            right: isTablet ? 24 : 16,
            child: GestureDetector(
              onTap: _navigateToChatbot,
              child: Container(
                width: isTablet ? 70 : 56,
                height: isTablet ? 70 : 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Robot icon
                    Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: isTablet ? 32 : 28,
                    ),

                    // Notification dot (optional - for unread messages)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: isTablet ? 12 : 10,
                        height: isTablet ? 12 : 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        isTablet: isTablet,
      ),
    );
  }
}