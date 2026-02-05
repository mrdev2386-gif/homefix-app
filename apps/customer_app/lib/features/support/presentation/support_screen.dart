import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/support_option_card.dart';
import '../widgets/help_request_form.dart';

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
            const SizedBox(height: 24),

            // Submit Help Request
            Text(
              'Submit a Request',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            const HelpRequestForm(),
            const SizedBox(height: 24),

            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildFAQItem(
              'How do I book a service?',
              'Browse services, select one, choose a time slot, and confirm booking. Our technician will arrive at your doorstep.',
            ),
            _buildFAQItem(
              'What payment methods do you accept?',
              'We accept UPI, Credit/Debit Cards, Net Banking, and Wallet payments.',
            ),
            _buildFAQItem(
              'Can I cancel my booking?',
              'Yes, you can cancel your booking before the technician arrives. Cancellation charges may apply based on timing.',
            ),
            _buildFAQItem(
              'How do I track my technician?',
              'Once assigned, you can track your technician in real-time from the booking details screen.',
            ),
            _buildFAQItem(
              'What if I\'m not satisfied with the service?',
              'We offer a satisfaction guarantee. Contact support within 24 hours for a resolution.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            question,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
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
