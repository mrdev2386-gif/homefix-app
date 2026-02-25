import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:technician_app/core/providers/technician_provider.dart';

class LimitedDashboard extends StatelessWidget {
  const LimitedDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF3C7),
        elevation: 0,
        title: Text(
          'Your account is under review',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF92400E),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Limited Access',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildMenuItem(
                context,
                icon: Icons.person_outline,
                title: 'View Profile',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                context,
                icon: Icons.help_outline,
                title: 'Support',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                context,
                icon: Icons.logout_outlined,
                title: 'Logout',
                onTap: () {
                  context.read<TechnicianProvider>().signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6366F1)),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
