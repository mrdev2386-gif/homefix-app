import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';

class FaqsScreen extends StatefulWidget {
  const FaqsScreen({super.key});

  @override
  State<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends State<FaqsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _getFilteredFaqs();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Frequently Asked Questions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),

          // FAQs List
          Expanded(
            child: filteredFaqs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No FAQs found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching with different keywords',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final category = filteredFaqs[index];
                      return _CategorySection(
                        category: category['category'],
                        faqs: category['faqs'],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredFaqs() {
    final allFaqs = _getTechnicianFaqs();
    
    if (_searchQuery.isEmpty) {
      return allFaqs;
    }

    return allFaqs.map((category) {
      final filteredFaqs = (category['faqs'] as List<Map<String, String>>)
          .where((faq) =>
              faq['question']!.toLowerCase().contains(_searchQuery) ||
              faq['answer']!.toLowerCase().contains(_searchQuery))
          .toList();

      return {
        'category': category['category'],
        'faqs': filteredFaqs,
      };
    }).where((category) => (category['faqs'] as List).isNotEmpty).toList();
  }

  List<Map<String, dynamic>> _getTechnicianFaqs() {
    return [
      {
        'category': '🔧 Getting Started',
        'faqs': [
          {
            'question': 'How do I complete my profile setup?',
            'answer': 'Go to Profile > Edit Profile and fill in all required fields including your name, location, experience, and upload a profile photo. Complete verification by uploading your documents.',
          },
          {
            'question': 'What documents do I need to verify my account?',
            'answer': 'You need to upload your Aadhaar card (front and back), PAN card, and a clear profile photo. Bank account details are also required for payments.',
          },
          {
            'question': 'How do I add my skills and services?',
            'answer': 'Go to Services tab and tap "Add New Service". Select your skills from the available categories and set your pricing for each service.',
          },
          {
            'question': 'Why is my profile approval taking time?',
            'answer': 'Profile verification typically takes 24-48 hours. Our team manually reviews all documents to ensure quality and safety. You\'ll be notified once approved.',
          },
        ],
      },
      {
        'category': '💼 Job Management',
        'faqs': [
          {
            'question': 'How do I accept or reject job requests?',
            'answer': 'When you receive a job notification, tap on it to view details. You can then tap "Accept" to take the job or "Reject" if you\'re unavailable. Be quick as jobs are offered to multiple technicians.',
          },
          {
            'question': 'Can I cancel a job after accepting it?',
            'answer': 'Yes, but frequent cancellations may affect your rating. Go to Active Jobs, select the booking, and tap "Cancel Job". Valid reasons include emergency, illness, or customer unavailability.',
          },
          {
            'question': 'What happens if I\'m late for a job?',
            'answer': 'Contact the customer immediately to inform them. Update the job status and provide a new ETA. Frequent delays may impact your rating and job allocation.',
          },
          {
            'question': 'How do I update job status?',
            'answer': 'Go to Active Jobs, select the booking, and use the status dropdown to update: "On the way", "Started", "In Progress", or "Completed". Customers receive real-time updates.',
          },
          {
            'question': 'What if customer is not available at scheduled time?',
            'answer': 'Try calling the customer first. If no response, wait for 15 minutes and update the job status to "Customer Unavailable". You\'ll still receive partial payment for your time.',
          },
        ],
      },
      {
        'category': '💰 Payments & Earnings',
        'faqs': [
          {
            'question': 'When will I receive payment for completed jobs?',
            'answer': 'Payments are processed within 24-48 hours after job completion. Money is transferred directly to your registered bank account.',
          },
          {
            'question': 'How is my service fee calculated?',
            'answer': 'You receive 80% of the total job amount. The platform retains 20% as commission for providing leads, payment processing, and support services.',
          },
          {
            'question': 'What are the platform charges?',
            'answer': 'Platform commission is 20% of the job value. This covers lead generation, payment processing, customer support, and app maintenance. No hidden charges.',
          },
          {
            'question': 'How do I withdraw money from wallet?',
            'answer': 'Go to Wallet > Withdraw. Enter the amount and confirm. Money will be transferred to your registered bank account within 2-3 business days.',
          },
          {
            'question': 'Why is payment delayed?',
            'answer': 'Payments may be delayed due to bank holidays, incorrect bank details, or pending verification. Check your bank details in Profile > Bank Details and contact support if needed.',
          },
        ],
      },
      {
        'category': '⭐ Ratings & Reviews',
        'faqs': [
          {
            'question': 'How does the rating system work?',
            'answer': 'Customers rate you from 1-5 stars after job completion. Your average rating affects job allocation - higher ratings get more job opportunities.',
          },
          {
            'question': 'What if I receive an unfair review?',
            'answer': 'You can dispute unfair reviews by going to Profile > Raise Dispute. Provide details and evidence. Our team will review and take appropriate action.',
          },
          {
            'question': 'How can I improve my rating?',
            'answer': 'Arrive on time, communicate clearly, complete jobs professionally, be courteous, and ensure customer satisfaction. Quality work leads to better ratings.',
          },
          {
            'question': 'Can customers change their review?',
            'answer': 'Customers can modify their review within 48 hours of submission. After that, reviews are permanent unless disputed and found invalid.',
          },
        ],
      },
      {
        'category': '📱 App Features',
        'faqs': [
          {
            'question': 'How do I go online/offline?',
            'answer': 'Use the toggle switch on the home screen. When online, you\'ll receive job notifications. Go offline when you\'re unavailable to avoid missing jobs.',
          },
          {
            'question': 'Why am I not receiving job notifications?',
            'answer': 'Check if you\'re online, notifications are enabled in phone settings, and your profile is complete. Also ensure you\'re in an area with active job requests.',
          },
          {
            'question': 'How do I update my location?',
            'answer': 'The app automatically updates your location when you\'re online. Ensure location permissions are granted and GPS is enabled for accurate job matching.',
          },
          {
            'question': 'What does "nearby jobs" mean?',
            'answer': 'Jobs within 10km of your current location. You can adjust this radius in Settings. Closer jobs are prioritized to reduce travel time.',
          },
          {
            'question': 'How do I contact customer support?',
            'answer': 'Go to Profile > Support & Help > Contact Support. You can also call our helpline at 9508322397 for urgent issues.',
          },
        ],
      },
      {
        'category': '🚨 Issues & Troubleshooting',
        'faqs': [
          {
            'question': 'App is crashing or not working properly',
            'answer': 'Try restarting the app, clearing cache, or updating to the latest version. If issues persist, contact support with your device details.',
          },
          {
            'question': 'I\'m not receiving any job requests',
            'answer': 'Ensure you\'re online, in a service area, have completed profile setup, and your skills match available jobs. Try expanding your service radius.',
          },
          {
            'question': 'Customer contact details not showing',
            'answer': 'Contact details are revealed only after accepting a job. If still not visible, refresh the app or contact support immediately.',
          },
          {
            'question': 'Location permission issues',
            'answer': 'Go to phone Settings > Apps > HomeFix Technician > Permissions and enable Location. Restart the app after granting permission.',
          },
          {
            'question': 'Notification problems',
            'answer': 'Check phone Settings > Notifications > HomeFix Technician and ensure all notifications are enabled. Also check Do Not Disturb settings.',
          },
        ],
      },
      {
        'category': '📋 Policies',
        'faqs': [
          {
            'question': 'What are the cancellation charges?',
            'answer': 'No charges for cancelling before accepting. After accepting, cancellation may result in a penalty and affect your rating. Emergency cancellations are usually waived.',
          },
          {
            'question': 'How do I report inappropriate customer behavior?',
            'answer': 'Go to Profile > Support & Help > Raise Dispute. Select "Customer Behavior" and provide details. We take such reports seriously and investigate promptly.',
          },
          {
            'question': 'What happens if I violate platform rules?',
            'answer': 'Violations may result in warnings, temporary suspension, or permanent account termination depending on severity. Common violations include fake profiles, poor service, or inappropriate behavior.',
          },
          {
            'question': 'How do I delete my account?',
            'answer': 'Contact support to request account deletion. Note that this action is irreversible and you\'ll lose all data, ratings, and earnings history.',
          },
        ],
      },
      {
        'category': '🔄 Account Management',
        'faqs': [
          {
            'question': 'How do I change my phone number?',
            'answer': 'Contact support to change your registered phone number. You\'ll need to verify the new number with OTP for security purposes.',
          },
          {
            'question': 'How do I update my bank details?',
            'answer': 'Go to Profile > Bank & Payout > Update. Enter new bank details and save. Changes take effect from the next payment cycle.',
          },
          {
            'question': 'Can I work in multiple cities?',
            'answer': 'Yes, update your location in the app when you move to a new city. You\'ll start receiving jobs in the new location based on availability.',
          },
          {
            'question': 'How do I add more services?',
            'answer': 'Go to Services tab > Add New Service. Select additional skills and set pricing. More services increase your job opportunities.',
          },
        ],
      },
    ];
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<Map<String, String>> faqs;

  const _CategorySection({
    required this.category,
    required this.faqs,
  });

  @override
  Widget build(BuildContext context) {
    if (faqs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Text(
                  category,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // FAQs in this category
          ...faqs.map((faq) => _FaqTile(
                question: faq['question']!,
                answer: faq['answer']!,
              )),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: AppTheme.primaryColor,
        collapsedIconColor: const Color(0xFF94A3B8),
        title: Text(
          question,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        children: [
          Text(
            answer,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}