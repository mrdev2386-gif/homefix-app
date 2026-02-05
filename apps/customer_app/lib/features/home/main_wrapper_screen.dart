import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dashboard/dashboard_screen.dart';
import '../services/presentation/service_list_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/theme/app_theme.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ServiceListScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              HapticFeedback.lightImpact();
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.white,
            elevation: 0,
            height: 80,
            indicatorColor: AppTheme.accentColor,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, size: 24, color: AppTheme.subtitleColor),
                selectedIcon: Icon(Icons.home_rounded, size: 24, color: AppTheme.primaryColor),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined, size: 24, color: AppTheme.subtitleColor),
                selectedIcon: Icon(Icons.grid_view_rounded, size: 24, color: AppTheme.primaryColor),
                label: 'Services',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined, size: 24, color: AppTheme.subtitleColor),
                selectedIcon: Icon(Icons.calendar_month_rounded, size: 24, color: AppTheme.primaryColor),
                label: 'Bookings',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, size: 24, color: AppTheme.subtitleColor),
                selectedIcon: Icon(Icons.person_rounded, size: 24, color: AppTheme.primaryColor),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
