import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import 'home_tab.dart';
import 'bookings_tab.dart';
import 'support_tab.dart';
import 'profile_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const BookingsTab(),
    const SupportTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primaryColor.withOpacity(0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month, color: AppTheme.primaryColor),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.support_agent_outlined),
              selectedIcon: Icon(Icons.support_agent, color: AppTheme.primaryColor),
              label: 'Support',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
