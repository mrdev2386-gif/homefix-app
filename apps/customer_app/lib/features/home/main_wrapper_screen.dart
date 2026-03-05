import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/home_screen.dart';
import '../bookings/presentation/booking_history_screen.dart';
import '../services/presentation/request_screen.dart';
import '../profile/profile_screen.dart';
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
    setState(() => _currentIndex = 0);
  }

  Future<void> _checkProfileCompletion() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user == null) {
        setState(() => _isCheckingProfile = false);
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('customers').doc(user.uid).get();
      if (!doc.exists) {
        _forceProfileCompletion();
        return;
      }

      final data = doc.data();
      if (data?['profileCompleted'] != true || data?['district'] == null) {
        _forceProfileCompletion();
      } else {
        setState(() => _isCheckingProfile = false);
      }
    } catch (e) {
      setState(() => _isCheckingProfile = false);
    }
  }

  void _forceProfileCompletion() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const _DistrictSelectionScreenContent()),
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
        if (!isSelected) {
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

class _DistrictSelectionScreenContent extends StatefulWidget {
  const _DistrictSelectionScreenContent();

  @override
  State<_DistrictSelectionScreenContent> createState() => _DistrictSelectionScreenContentState();
}

class _DistrictSelectionScreenContentState extends State<_DistrictSelectionScreenContent> {
  String? _selectedDistrict;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _districts = [
    'Ahmedabad', 'Bangalore', 'Bhopal', 'Chennai', 'Coimbatore', 'Delhi', 'Gurgaon',
    'Hyderabad', 'Indore', 'Jaipur', 'Kolkata', 'Lucknow', 'Mumbai', 'Nagpur',
    'Patna', 'Pune', 'Ranchi', 'Surat', 'Thane', 'Vadodara', 'Visakhapatnam'
  ];

  List<String> get _filteredDistricts {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _districts;
    return _districts.where((d) => d.toLowerCase().contains(query)).toList();
  }

  Future<void> _saveDistrict() async {
    if (_selectedDistrict == null) return;
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user == null) return;
      
      final normalizedDistrict = _selectedDistrict!.trim().toLowerCase();
      
      await FirebaseFirestore.instance.collection('customers').doc(user.uid).update({
        'district': normalizedDistrict,
        'profileCompleted': true,
      });
      
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainWrapperScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text('Select Your District', 
                    style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textColor)),
                  const SizedBox(height: 8),
                  Text('Which city do you need services in?', 
                    style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.subtitleColor)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: AppTheme.inputDecoration(
                  hintText: 'Search city...',
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                itemCount: _filteredDistricts.length,
                itemBuilder: (context, index) {
                  final d = _filteredDistricts[index];
                  final isSelected = _selectedDistrict == d;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDistrict = d),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100, width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(d, style: GoogleFonts.outfit(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, fontSize: 16)),
                          if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: ElevatedButton(
                onPressed: _selectedDistrict == null || _isLoading ? null : _saveDistrict,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('CONTINUE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
