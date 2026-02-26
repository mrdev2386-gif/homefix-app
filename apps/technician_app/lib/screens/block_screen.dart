import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/providers/technician_provider.dart';

/// Blocked/Suspended screen for technicians who cannot access the app
/// 
/// [reason] - Optional reason for blocking (e.g., "Your account has been suspended")
/// 
/// NOTE: This screen is ONLY shown for blocked/suspended technicians.
/// New users who haven't completed onboarding will be redirected to OnboardingScreen
/// via AuthGate - NOT this screen.
class BlockScreen extends StatelessWidget {
  final String? reason;
  
  const BlockScreen({
    super.key,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    // Block screen is ONLY for blocked/suspended technicians
    // New users should be sent to OnboardingScreen via AuthGate
    final isBlocked = reason != null && reason!.isNotEmpty;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // TOP CONTENT
                      Column(
                        children: [
                          const SizedBox(height: 60),
                          _buildIllustration(isBlocked),
                          const SizedBox(height: 48),
                          Text(
                            isBlocked ? 'Account Blocked' : 'Access Restricted',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            reason ?? 'Your account has been suspended. Please contact support for assistance.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              color: const Color(0xFF64748B),
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      // BOTTOM BUTTON
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 24, 0, 28),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              Provider.of<TechnicianProvider>(context, listen: false).signOut();
                            },
                            style: TextButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                            ),
                            child: Text(
                              "Sign Out",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIllustration(bool isBlocked) {
    return Container(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: isBlocked 
                ? Colors.red.withOpacity(0.05)
                : const Color(0xFF6366F1).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isBlocked 
                ? Colors.red.withOpacity(0.1)
                : const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            isBlocked ? Icons.block : Icons.engineering_rounded,
            size: 64,
            color: isBlocked ? Colors.red : const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}
