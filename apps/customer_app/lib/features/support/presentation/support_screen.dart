import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/support_option_card.dart';
import 'faqs_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Need Assistance?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'We\'re Here to Help!',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '24/7 Support Available',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.support_agent,
                    size: 60,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Contact Options
            Text(
              'Quick Contact',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            SupportOptionCard(
              icon: Icons.phone,
              title: 'Call Us',
              subtitle: 'Talk to our support team',
              color: const Color(0xFF10B981),
              onTap: () => _makePhoneCall(context),
            ),
            const SizedBox(height: 12),

            SupportOptionCard(
              icon: Icons.chat,
              title: 'WhatsApp',
              subtitle: 'Chat with us on WhatsApp',
              color: const Color(0xFF25D366),
              onTap: () => _openWhatsApp(context),
            ),
            const SizedBox(height: 12),

            SupportOptionCard(
              icon: Icons.email,
              title: 'Email Us',
              subtitle: 'Send us an email',
              color: const Color(0xFF6366F1),
              onTap: () => _sendEmail(context),
            ),
            const SizedBox(height: 12),

            SupportOptionCard(
              icon: Icons.help_outline,
              title: 'FAQs',
              subtitle: 'Find answers to common questions',
              color: const Color(0xFFEF4444),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FaqsScreen()),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Tips
            Text(
              'Quick Tips',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildTipCard(
              Icons.lightbulb_outline,
              'Check FAQs First',
              'Most questions are answered in our comprehensive FAQ section.',
            ),
            const SizedBox(height: 12),
            _buildTipCard(
              Icons.schedule,
              'Response Time',
              'We typically respond to emails within 24 hours on business days.',
            ),
            const SizedBox(height: 12),
            _buildTipCard(
              Icons.phone_in_talk,
              'Urgent Issues',
              'For urgent matters, please call us directly for immediate assistance.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF6366F1), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+911234567890');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone app')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/911234567890?text=Hi, I need help with HomeFix');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@homefix.com',
      query: 'subject=Support Request&body=Hi HomeFix Team,',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email app')),
        );
      }
    }
  }
}
