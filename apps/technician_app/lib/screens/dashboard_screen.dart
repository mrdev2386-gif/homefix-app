import 'package:flutter/material.dart';
import 'package:technician_app/features/job_requests/job_requests_screen.dart';
import 'package:technician_app/features/technician/services/services_screen.dart';
import 'package:technician_app/features/profile/presentation/technician_profile_screen.dart';
import 'package:technician_app/screens/dashboard_home_enhanced.dart';

/// Dashboard Screen - Main navigation hub for technician app
/// 
/// Features:
/// - IndexedStack for tab state preservation
/// - Bottom navigation with 4 tabs: Home, Jobs, Services, Profile
/// - Clean modern UI
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardHomeEnhanced(onNavigate: _onTabTapped),
          const JobRequestsScreen(),
          const ServicesScreen(),
          const TechnicianProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (!mounted) return;
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        iconSize: 22,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          height: 1.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          height: 1.1,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handyman_outlined),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
