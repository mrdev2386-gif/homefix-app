
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/widgets/safe_network_image.dart';
import 'package:customer_app/core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('About HomeFix', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const SafeNetworkImage(
              imageUrl: 'https://cdn-icons-png.flaticon.com/512/3064/3064155.png',
              height: 120,
              fit: BoxFit.contain,
              usePlaceholder: false,
            ),
            const SizedBox(height: 24),
            Text(
              'HomeFix',
              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
            ),
            Text(
              'Version 2.0.1',
              style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.subtitleColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 40),
            _buildInfoCard(
              'Our Mission',
              'To provide reliable, high-quality home services at the touch of a button, empowering both customers and service professionals.'
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Excellence',
              'All our technicians are verified and background-checked to ensure your safety and satisfaction.'
            ),
            const SizedBox(height: 40),
            Text(
              '© 2026 HomeFix Inc. All rights reserved.',
              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.subtitleColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.outfit(color: AppTheme.subtitleColor, height: 1.5),
          ),
        ],
      ),
    );
  }
}
