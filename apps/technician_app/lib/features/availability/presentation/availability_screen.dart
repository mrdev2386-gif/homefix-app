import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/services/functions_service.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  bool _isLoading = false;

  Future<void> _generateSlots() async {
    setState(() => _isLoading = true);
    
    // Show "Coming Soon" message - backend function not yet implemented
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slot generation is coming soon. Contact support for assistance.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text("Manage Visibility", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.event_available_rounded, size: 64, color: Color(0xFF6366F1)),
                    ),
                    const SizedBox(height: 32),
                    Text(
                        "Booking Schedule",
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                        "Set your working hours so customers can find and book your services. Generating slots makes you visible on the platform.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 15, height: 1.5),
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
                          _buildInfoTile(Icons.timer_outlined, "Standard Hours", "09:00 AM - 06:00 PM"),
                          const Divider(height: 32),
                          _buildInfoTile(Icons.calendar_month_outlined, "Duration", "Next 7 Days"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 56),
                    ElevatedButton(
                        onPressed: _isLoading ? null : _generateSlots,
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Text("Generate Weekly Slots"),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coming Soon: Granular Editing")));
                        }, 
                        child: Text("Edit Individual Slots", style: GoogleFonts.outfit(color: const Color(0xFF6366F1))),
                    )
                ]
            ),
          ),
        )
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
          ],
        ),
      ],
    );
  }
}
