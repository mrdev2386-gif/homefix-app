import 'package:flutter/material.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SlotSelectionScreen extends StatefulWidget {
  final HomeService service;
  final String? preSelectedTechId;

  const SlotSelectionScreen({
    super.key,
    required this.service,
    this.preSelectedTechId,
  });

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Slot', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Slot selection coming soon'),
      ),
    );
  }
}
