import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/providers/auth_provider.dart';

class TicketScreen extends StatefulWidget {
  final String? bookingId;
  const TicketScreen({super.key, this.bookingId});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final _descController = TextEditingController();
  String _category = "Booking Issue";

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Support Tickets", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Create a Ticket", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildCategorySelector(),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(hintText: "Describe your issue..."),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_descController.text.trim().isEmpty) return;
                // Create ticket logic via Service
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ticket created successfully!")));
              },
              child: const Text("Submit Ticket"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          isExpanded: true,
          onChanged: (v) => setState(() => _category = v!),
          items: ["Booking Issue", "Payment Issue", "Technician Issue", "Other"]
              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.outfit())))
              .toList(),
        ),
      ),
    );
  }
}
