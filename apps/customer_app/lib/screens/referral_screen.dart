import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/providers/auth_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final code = authProvider.customer?.referralCode ?? "HOME50";
    final referralLink = "https://homefix.app/ref/$code";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Refer & Earn", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.card_giftcard, size: 100, color: AppTheme.primaryColor),
            const SizedBox(height: 32),
            Text(
              "Share HomeFix with friends!",
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "They get ₹100 off on their first booking, and you get ₹100 credit when they complete it!",
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Text("YOUR REFERRAL CODE", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(code, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 4)),
                  const SizedBox(height: 16),
                  Text(referralLink, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Copy to clipboard
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Referral link copied!")));
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text("Copy Link"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Share.share("Use my code $code to get ₹100 off on your first HomeFix service! Download now: $referralLink");
                    },
                    icon: const Icon(Icons.share),
                    label: const Text("Share"),
                  ),
                ),
              ],
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
