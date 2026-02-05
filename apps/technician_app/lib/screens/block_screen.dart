import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/providers/technician_provider.dart';

class BlockScreen extends StatelessWidget {
  const BlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.engineering_rounded,
                  size: 80,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Not a Technician Yet',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'To use the Technician App, you must first apply and get approved as a technician from the Customer App.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: const Color(0xFF64748B),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 56),
              ElevatedButton(
                onPressed: () {
                  // In a real app, this could open a URL or a specific screen
                  // For now, we show a dialog explaining the process
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("How to Apply"),
                      content: const Text("1. Open HomeFix Customer App\n2. Go to Profile\n3. Tap 'Apply as Technician'\n4. Complete the KYC process"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Apply as Technician'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Provider.of<TechnicianProvider>(context, listen: false).signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
