
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/technician_provider.dart';
import '../../../core/models/technician.dart';
import '../../availability/presentation/availability_screen.dart';
import 'reviews_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TechnicianProvider>(context);
    final tech = provider.technician;
    final isLoading = provider.isLoading;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (tech == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text("Profile", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Profile not found',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please complete onboarding',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: provider.signOut,
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Profile", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildProfileHeader(tech),
                  const SizedBox(height: 32),
                  _buildStatsRow(tech),
                  const SizedBox(height: 32),
                  _buildMenuSection(context, tech, provider),
                  const SizedBox(height: 32),
                  _buildLogoutButton(provider),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(Technician tech) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: const Icon(Icons.person_rounded, size: 50, color: Color(0xFF6366F1)),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(tech.name, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(tech.phone, style: GoogleFonts.outfit(color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatsRow(Technician tech) {
    return Row(
      children: [
        _buildStatItem("Experience", "${tech.jobsDone > 10 ? 2 : 0}+ yrs"), // Placeholder logic or add exp field
        _buildStatItem("Rating", "${tech.avgRating.toStringAsFixed(1)} ★"),
        _buildStatItem("Jobs", "${tech.jobsDone}"),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          Text(label, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, Technician tech, TechnicianProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.build_circle_outlined, "Skills & Services", tech.skills.join(", ")),
          const Divider(height: 1, indent: 60),
          _buildMenuItem(Icons.calendar_month_outlined, "Availability", "Set your working hours", onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AvailabilityScreen()));
          }),
          const Divider(height: 1, indent: 60),
          _buildMenuItem(Icons.star_outline_rounded, "Ratings & Reviews", "${tech.avgRating.toStringAsFixed(1)} (${tech.totalRatings} reviews)", onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewsScreen(technician: tech)));
          }),
          const Divider(height: 1, indent: 60),
          _buildMenuItem(Icons.file_copy_outlined, "KYC Documents", "Approved", trailing: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)),
          const Divider(height: 1, indent: 60),
          _buildMenuItem(Icons.settings_outlined, "Settings", "Notifications & Privacy"),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, {VoidCallback? onTap, Widget? trailing}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF64748B), size: 20),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  Widget _buildLogoutButton(TechnicianProvider provider) {
    return OutlinedButton.icon(
      onPressed: provider.signOut,
      icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFFEF4444)),
      label: const Text("Logout"),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFEF4444),
        side: const BorderSide(color: Color(0xFFFCA5A5)),
        minimumSize: const Size(double.infinity, 56),
      ),
    );
  }
}
