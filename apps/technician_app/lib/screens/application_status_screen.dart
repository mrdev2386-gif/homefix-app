import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/providers/technician_provider.dart';

class ApplicationStatusScreen extends StatelessWidget {
  final String status;
  final String? reason;

  const ApplicationStatusScreen({super.key, required this.status, this.reason});


  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    final isSuspended = status == 'suspended';
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusIllustration(isPending, isSuspended),
                const SizedBox(height: 48),
                Text(
                  _getTitle(status),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _getSubtitle(isPending, reason),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: const Color(0xFF64748B),
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 64),
                if (!isPending)
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Contact Support"),
                  ),
                const SizedBox(height: 12),
                TextButton(
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIllustration(bool isPending, bool isSuspended) {
    final color = isPending ? const Color(0xFF6366F1) : const Color(0xFFEF4444);
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
              color: color.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            isPending ? Icons.hourglass_top_rounded : Icons.gpp_bad_rounded,
            size: 64,
            color: color,
          ),
        ],
      ),
    );
  }

  String _getTitle(String status) {
    if (status == 'pending') return 'Reviewing Details';
    if (status == 'suspended') return 'Account Suspended';
    return 'Application Rejected';
  }

  String _getSubtitle(bool isPending, String? reason) {
    if (isPending) {
      return 'Our team is currently verifying your profile and documents. You will notify you once your account is activated.';
    }
    return reason ?? 'Unfortunately, your application was not approved. Please reach out to our support team for more information.';
  }

}
