
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/theme/app_theme.dart';

class PolicyScreen extends StatelessWidget {
  final String title;
  const PolicyScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. Data Collection',
              'We collect information you provide directly to us, such as when you create or modify your account, request services, contact customer support, or otherwise communicate with us.'
            ),
            _buildSection(
              '2. Use of Information',
              'We use the information we collect to provide, maintain, and improve our services, such as to facilitate payments, send receipts, provide products and services you request.'
            ),
            _buildSection(
              '3. Sharing of Information',
              'We may share your information with service professionals to enable them to provide the services you request, and with third-party service providers who perform services on our behalf.'
            ),
            _buildSection(
              '4. Security',
              'We take reasonable measures to help protect information about you from loss, theft, misuse and unauthorized access, disclosure, alteration and destruction.'
            ),
            _buildSection(
              '5. Your Choices',
              'You may update, correct or delete information about you at any time by logging into your online account or by contacting us.'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textColor),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.subtitleColor, height: 1.6),
          ),
        ],
      ),
    );
  }
}
