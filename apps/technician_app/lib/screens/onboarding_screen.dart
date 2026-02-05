import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../core/providers/technician_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<String> _availableSkills = [
    "AC Repair", "Cleaning", "Electrician", "Plumbing", "Pest Control", 
    "Washing Machine", "Refrigerator", "Water Purifier", "Television", "Microwave"
  ];
  final List<String> _selectedSkills = [];
  bool _isLoading = false;

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position? pos;
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        pos = await Geolocator.getCurrentPosition();
      }

      await Provider.of<TechnicianProvider>(context, listen: false).onboard(
        _selectedSkills,
        lat: pos?.latitude,
        lng: pos?.longitude,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Setup failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Professional Setup", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / 2,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            minHeight: 4,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (v) => setState(() => _currentPage = v),
              children: [
                _buildSkillsPage(),
                _buildLocationPage(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSkillsPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What are your skills?", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 12),
          Text("Select the services you are expert in. You will receive job requests based on these skills.", style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 16, height: 1.5)),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableSkills.map((skill) {
                  final isSelected = _selectedSkills.contains(skill);
                  return FilterChip(
                    label: Text(skill),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSkills.add(skill);
                        } else {
                          _selectedSkills.remove(skill);
                        }
                      });
                    },
                    selectedColor: const Color(0xFF6366F1),
                    checkmarkColor: Colors.white,
                    labelStyle: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.location_on_rounded, size: 80, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 40),
          Text("Location Access", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            "We need your location to show you jobs in your vicinity and provide directions to customer sites.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 48),
          if (_isLoading) const CircularProgressIndicator(color: Color(0xFF6366F1)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : (_currentPage == 0 ? (_selectedSkills.isEmpty ? null : _nextPage) : _completeOnboarding),
          child: Text(
            _currentPage == 0 ? "Next Step" : "Get Started",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
