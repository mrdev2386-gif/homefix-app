import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/core/services/auth_service.dart';
import 'package:customer_app/core/services/firestore_service.dart';
import 'package:customer_app/core/models/user_model.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) return const Scaffold(body: Center(child: Text('Login required')));

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      appBar: AppBar(
        title: const Text('Refer & Earn', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<UserModel>(
        stream: firestoreService.streamUserModel(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          if (user == null) return const Center(child: Text('User not found'));

          final referralCode = user.referralCode ?? (user.uid.length >= 8 ? user.uid.substring(0, 8).toUpperCase() : user.uid.toUpperCase());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.card_giftcard_rounded, size: 100, color: Color(0xFF6366F1)),
                const SizedBox(height: 24),
                const Text(
                  'Invite Friends & Get ₹50',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Share your referral code with friends. When they join and book their first service, both of you get ₹50 in your wallet!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'YOUR REFERRAL CODE',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              referralCode,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: Color(0xFF6366F1)),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: referralCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Code copied to clipboard!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Share logic
                          },
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('Share Code', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildReferralStats(user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReferralStats(UserModel user) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Wallet Balance', '₹${user.walletBalance.toStringAsFixed(0)}', Icons.account_balance_wallet_outlined)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Total Earned', '₹0', Icons.trending_up_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6366F1), size: 24),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }
}
