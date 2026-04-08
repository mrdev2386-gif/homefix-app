import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../home/home_screen.dart';
import '../bookings/presentation/booking_history_screen.dart';
import '../services/presentation/request_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/screens/complete_location_screen.dart';
import 'package:customer_app/core/services/auth_service.dart';
import 'package:customer_app/core/theme/app_theme.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _currentIndex = 0;
  bool _isCheckingProfile = true;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      BookingHistoryScreen(onNavigateToHome: _navigateToHomeTab),
      const RequestScreen(),
      const ProfileScreen(),
    ];
    _checkProfileCompletion();
  }

  void _navigateToHomeTab() {
    if (!mounted) return;
    setState(() => _currentIndex = 0);
  }

  Future<void> _checkProfileCompletion() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _isCheckingProfile = false);
        return;
      }

      // Use AuthService to check profile completion (includes district check)
      final hasCompletedProfile = await authService.hasUserCompletedProfile(user.uid);
      if (!mounted) return;
      
      if (!hasCompletedProfile) {
        _forceProfileCompletion();
        return;
      }
      
      // All location data present - allow access
      if (!mounted) return;
      setState(() => _isCheckingProfile = false);
    } catch (e) {
      debugPrint('Error checking profile completion: $e');
      if (!mounted) return;
      setState(() => _isCheckingProfile = false);
    }
  }

  void _forceProfileCompletion() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CompleteLocationScreen()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildPremiumNavBar(),
    );
  }

  Widget _buildPremiumNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _navItem(1, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Bookings'),
              _navItem(2, Icons.add_circle_rounded, Icons.add_circle_outline_rounded, 'Request'),
              _navItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData selectedIcon, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        if (!isSelected && mounted) {
          HapticFeedback.mediumImpact();
          setState(() => _currentIndex = index);
        }
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutExpo,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.subtitleColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppTheme.primaryColor : AppTheme.subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
