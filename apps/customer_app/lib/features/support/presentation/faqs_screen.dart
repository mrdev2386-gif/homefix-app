import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Frequently Asked Questions',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
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
                hintStyle: GoogleFonts.outfit(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No FAQs found',
                          style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching with different keywords',
                          style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
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
    final allFaqs = _getCustomerFaqs();
    
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

  List<Map<String, dynamic>> _getCustomerFaqs() {
    return [
      {
        'category': '🏠 Booking & Services',
        'faqs': [
          {
            'question': 'How do I book a service?',
            'answer': 'Browse services from home screen → Select a service → Choose date & time slot → Add/select address → Apply coupon (optional) → Confirm booking. You\'ll receive instant confirmation.',
          },
          {
            'question': 'Can I book multiple services at once?',
            'answer': 'Currently, you can book one service per booking. However, you can create multiple bookings for different services at the same or different time slots.',
          },
          {
            'question': 'How far in advance can I book?',
            'answer': 'You can book services up to 7 days in advance. Select your preferred date and available time slots will be shown.',
          },
          {
            'question': 'What if no technician is available?',
            'answer': 'Try selecting different time slots or dates. If still unavailable, we\'ll notify you via push notification when technicians become available in your area.',
          },
          {
            'question': 'Can I reschedule my booking?',
            'answer': 'Yes, you can cancel your current booking and create a new one with your preferred time. Note that cancellation charges may apply based on timing.',
          },
          {
            'question': 'What areas do you serve?',
            'answer': 'We serve major cities across India. Enter your location when booking to check service availability in your area. We\'re constantly expanding to new locations.',
          },
          {
            'question': 'What is the minimum booking amount?',
            'answer': 'Minimum booking amount varies by service type, typically starting from ₹199. Check individual service details for exact pricing.',
          },
          {
            'question': 'Can I add special instructions for the technician?',
            'answer': 'Yes, you can add notes or special instructions during the booking process. The technician will see these before arriving.',
          },
        ],
      },
      {
        'category': '💳 Payments & Wallet',
        'faqs': [
          {
            'question': 'What payment methods do you accept?',
            'answer': 'We accept UPI, Credit/Debit Cards, Net Banking, Wallet payments, and Cash on Delivery (COD) for select services.',
          },
          {
            'question': 'Is online payment safe?',
            'answer': 'Absolutely! We use industry-standard secure payment gateways with 256-bit SSL encryption. Your payment information is never stored on our servers.',
          },
          {
            'question': 'When will money be deducted from my account?',
            'answer': 'For prepaid bookings, payment is deducted immediately after confirmation. For COD, payment is collected after service completion.',
          },
          {
            'question': 'How do I add money to my wallet?',
            'answer': 'Go to Profile → Wallet → Add Money. Enter amount and choose payment method. Wallet balance can be used for future bookings.',
          },
          {
            'question': 'Can I get a refund if I cancel?',
            'answer': 'Yes, refunds are processed based on cancellation timing. Free cancellation before technician assignment, partial refund after assignment. Refunds take 5-7 business days.',
          },
          {
            'question': 'How do coupons work?',
            'answer': 'Enter coupon code at checkout before payment. Discount will be applied instantly. Check Profile → Offers for available coupons.',
          },
          {
            'question': 'Where can I find my invoices?',
            'answer': 'Go to Bookings → Completed → Select booking → View Invoice. You can download or share invoices directly from the app.',
          },
          {
            'question': 'What if payment fails?',
            'answer': 'If payment fails, your booking won\'t be confirmed. Try again with a different payment method or contact your bank if the issue persists.',
          },
        ],
      },
      {
        'category': '🎁 Referral & Rewards',
        'faqs': [
          {
            'question': 'How does the referral program work?',
            'answer': 'Share your unique referral code → Friend signs up using your code → Both of you get ₹100 wallet credit after friend completes their first booking.',
          },
          {
            'question': 'Where can I find my referral code?',
            'answer': 'Go to Profile → Referral & Rewards. Your unique code and referral link will be displayed. Tap Share to send via WhatsApp, SMS, or social media.',
          },
          {
            'question': 'When will I receive my referral bonus?',
            'answer': 'Referral bonus is credited instantly to your wallet after your friend completes their first booking and payment.',
          },
          {
            'question': 'Is there a limit on referrals?',
            'answer': 'No limit! Refer unlimited friends and earn ₹100 for each successful referral. The more you refer, the more you earn.',
          },
          {
            'question': 'Can I use referral credit for any service?',
            'answer': 'Yes, wallet credit from referrals can be used for booking any service on the platform. No restrictions apply.',
          },
          {
            'question': 'What if my friend doesn\'t use my referral code?',
            'answer': 'Referral code must be applied during signup. If missed, neither of you will receive the bonus. Make sure they use the referral link you share.',
          },
        ],
      },
      {
        'category': '👨‍🔧 Technician & Tracking',
        'faqs': [
          {
            'question': 'How do I track my technician?',
            'answer': 'Real-time tracking is available after a technician accepts your booking. Go to Bookings → Upcoming → View on Map to see live location.',
          },
          {
            'question': 'Can I contact the technician directly?',
            'answer': 'Yes, a call button appears after technician assignment. You can call them for directions or any queries related to the service.',
          },
          {
            'question': 'What if the technician is running late?',
            'answer': 'You\'ll receive automatic notifications about delays. You can also call the technician directly to check their ETA or reschedule if needed.',
          },
          {
            'question': 'Can I request a specific technician?',
            'answer': 'Currently, technicians are auto-assigned based on availability and proximity. However, you can book again with the same technician from your booking history.',
          },
          {
            'question': 'How are technicians verified?',
            'answer': 'All technicians undergo strict verification including Aadhaar, PAN card, police verification, and skill assessment before onboarding.',
          },
          {
            'question': 'What if I\'m not satisfied with the technician?',
            'answer': 'Rate your experience after service completion. For serious issues, contact support immediately for resolution or replacement.',
          },
        ],
      },
      {
        'category': '❌ Cancellation & Refunds',
        'faqs': [
          {
            'question': 'How do I cancel my booking?',
            'answer': 'Go to Bookings → Upcoming → Select booking → Cancel Booking. Confirm cancellation and select reason. You\'ll receive instant confirmation.',
          },
          {
            'question': 'What are the cancellation charges?',
            'answer': 'Free cancellation: Before technician assignment\n50% charges: After assignment but before arrival\n100% charges: After technician arrives at location',
          },
          {
            'question': 'How long does a refund take?',
            'answer': 'Refunds are processed within 24 hours and credited to your original payment method in 5-7 business days. Wallet refunds are instant.',
          },
          {
            'question': 'What if the technician cancels?',
            'answer': 'You\'ll receive full refund plus ₹50 compensation credit in your wallet. We\'ll also try to assign another technician immediately.',
          },
          {
            'question': 'Can I cancel after service starts?',
            'answer': 'Once service starts, cancellation is not allowed. If you\'re unsatisfied, complete the service and raise a complaint for resolution.',
          },
          {
            'question': 'What if I need to cancel due to emergency?',
            'answer': 'Contact support immediately with details. We may waive cancellation charges for genuine emergencies on a case-by-case basis.',
          },
        ],
      },
      {
        'category': '⭐ Reviews & Ratings',
        'faqs': [
          {
            'question': 'How do I rate a service?',
            'answer': 'Rating screen appears automatically after service completion. Rate from 1-5 stars and optionally add a written review.',
          },
          {
            'question': 'Can I edit my review after submitting?',
            'answer': 'Yes, you can edit your review within 48 hours of submission. Go to Bookings → Completed → Edit Review.',
          },
          {
            'question': 'What if I forgot to rate the service?',
            'answer': 'Go to Bookings → Completed → Select booking → Rate Service. You can rate anytime, though we encourage rating immediately after service.',
          },
          {
            'question': 'Are my reviews visible to others?',
            'answer': 'Yes, your reviews help other customers make informed decisions. Your name and rating will be visible on technician profiles.',
          },
          {
            'question': 'Can I report a fake review?',
            'answer': 'If you notice suspicious reviews, report them via support. We take review authenticity seriously and investigate all reports.',
          },
        ],
      },
      {
        'category': '📍 Address & Location',
        'faqs': [
          {
            'question': 'How do I add multiple addresses?',
            'answer': 'Go to Profile → Saved Addresses → Add New Address. Enter complete details including landmark for easy technician navigation.',
          },
          {
            'question': 'Can I set a default address?',
            'answer': 'Yes, tap on any saved address → Set as Default. This address will be auto-selected for future bookings.',
          },
          {
            'question': 'What if my location is not detected automatically?',
            'answer': 'Enable GPS and location permissions in phone settings. If still not working, you can manually enter your address.',
          },
          {
            'question': 'Can I edit or delete saved addresses?',
            'answer': 'Yes, go to Profile → Saved Addresses → Select address → Edit or Delete. You can modify any saved address anytime.',
          },
          {
            'question': 'How accurate should my address be?',
            'answer': 'Provide complete address with house/flat number, landmark, and area name. Accurate addresses help technicians reach you faster.',
          },
        ],
      },
      {
        'category': '🔐 Account & Security',
        'faqs': [
          {
            'question': 'How do I change my phone number?',
            'answer': 'Contact support to change your registered phone number. Phone number is your primary login credential and requires verification.',
          },
          {
            'question': 'Is my personal data safe?',
            'answer': 'Yes, we follow industry-standard security practices and comply with data protection regulations. Your data is encrypted and never shared with third parties.',
          },
          {
            'question': 'How do I delete my account?',
            'answer': 'Go to Profile → Settings → Delete Account. Note: This action is irreversible and you\'ll lose all data, bookings, and wallet balance.',
          },
          {
            'question': 'I forgot my password, what should I do?',
            'answer': 'We use OTP-based login, so no password is needed. Simply enter your phone number and verify with OTP sent to your mobile.',
          },
          {
            'question': 'Can I have multiple accounts?',
            'answer': 'Each phone number can have only one account. Multiple accounts are not allowed and may result in account suspension.',
          },
          {
            'question': 'How do I update my profile information?',
            'answer': 'Go to Profile → Edit Profile. You can update your name, email, and profile photo anytime.',
          },
        ],
      },
      {
        'category': '🤖 AI Support & Help',
        'faqs': [
          {
            'question': 'What is AI Chat Support?',
            'answer': 'Our AI assistant powered by Google Gemini provides instant answers to your queries 24/7. It can help with bookings, payments, and general questions.',
          },
          {
            'question': 'Is AI support available 24/7?',
            'answer': 'Yes, AI chat support is always available for instant help. For complex issues, you can also contact human support during business hours.',
          },
          {
            'question': 'Can AI help me book services?',
            'answer': 'Yes, AI can guide you through the booking process, explain services, and answer questions. However, actual booking is done through the app interface.',
          },
          {
            'question': 'What if AI cannot solve my problem?',
            'answer': 'You can escalate to human support by tapping "Contact Support" or calling our helpline at 9508322397 for urgent issues.',
          },
          {
            'question': 'Is my chat history saved?',
            'answer': 'Chat history is saved during your session for context. It\'s cleared when you close the app for privacy.',
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
                  const Color(0xFF6366F1).withOpacity(0.1),
                  const Color(0xFF8B5CF6).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.2),
              ),
            ),
            child: Text(
              category,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6366F1),
              ),
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
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: const Color(0xFF6366F1),
          collapsedIconColor: Colors.grey,
          title: Text(
            question,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          children: [
            Text(
              answer,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
