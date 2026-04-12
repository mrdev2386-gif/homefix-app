import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:customer_app/core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../widgets/referral_code_card.dart';
import '../widgets/referral_stats.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  bool _isLoading = true;
  String _referralCode = '';
  int _totalReferrals = 0;
  double _totalEarnings = 0.0;
  List<Map<String, dynamic>> _referralHistory = [];

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final user = authService.currentUser;

      if (user != null) {
        // Get user data to fetch referral code
        final userData = await firestoreService.getUserData(user.uid);
        _referralCode = userData?['referralCode'] ?? '';

        // If no referral code exists, generate one
        if (_referralCode.isEmpty) {
          _referralCode = await _generateReferralCode(user.uid);
        }

        // Fetch referral stats (mock data for now - will be replaced with actual Firestore query)
        _totalReferrals = 0;
        _totalEarnings = 0.0;
        _referralHistory = [];
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading referral data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load referral data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _generateReferralCode(String userId) async {
    // Generate a unique 6-character referral code
    final code = userId.substring(0, 6).toUpperCase();
    
    // Save to Firestore
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    await firestoreService.updateUserData(userId, {'referralCode': code});
    
    return code;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Referral & Earn', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReferralData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    _buildHeaderBanner(),
                    const SizedBox(height: 24),

                    // Referral Code Card
                    ReferralCodeCard(
                      referralCode: _referralCode,
                      onCopy: _copyReferralCode,
                      onShare: _shareReferralCode,
                    ),
                    const SizedBox(height: 24),

                    // Referral Stats
                    ReferralStats(
                      totalReferrals: _totalReferrals,
                      totalEarnings: _totalEarnings,
                    ),
                    const SizedBox(height: 24),

                    // How it Works
                    _buildHowItWorks(),
                    const SizedBox(height: 24),

                    // Referral History
                    _buildReferralHistory(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Earn ₹100',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'For every friend you refer!',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Your friend gets ₹50 too!',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.card_giftcard,
            size: 80,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it Works',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStep(
            '1',
            'Share your code',
            'Share your unique referral code with friends',
            Icons.share,
          ),
          const SizedBox(height: 16),
          _buildStep(
            '2',
            'Friend signs up',
            'Your friend signs up using your code',
            Icons.person_add,
          ),
          const SizedBox(height: 16),
          _buildStep(
            '3',
            'Both get rewarded',
            'You get ₹100 and your friend gets ₹50',
            Icons.celebration,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String description, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6366F1),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Icon(icon, color: const Color(0xFF6366F1), size: 24),
      ],
    );
  }

  Widget _buildReferralHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Referral History',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_referralHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No referrals yet',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start sharing your code to earn rewards!',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_referralHistory.length, (index) {
              final referral = _referralHistory[index];
              return _buildReferralItem(referral);
            }),
        ],
      ),
    );
  }

  Widget _buildReferralItem(Map<String, dynamic> referral) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
            child: const Icon(Icons.person, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral['name'] ?? 'User',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  referral['date'] ?? '',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+₹${referral['amount'] ?? 0}',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _copyReferralCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Referral code copied!', style: GoogleFonts.outfit()),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareReferralCode() {
    final message = '''
🎉 Join HomeFix and get ₹50 off on your first service!

Use my referral code: $_referralCode

Download the app and book expert home services at your doorstep.

HomeFix - Your Home, Our Care 🏠
''';

    Share.share(message);
  }
}
