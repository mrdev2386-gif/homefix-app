import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Step5ServiceSetup extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const Step5ServiceSetup({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step5ServiceSetup> createState() => _Step5ServiceSetupState();
}

class _Step5ServiceSetupState extends State<Step5ServiceSetup> {
  late TextEditingController _maxDistanceController;
  late TextEditingController _descriptionController;
  bool _emergencyService = false;

  @override
  void initState() {
    super.initState();
    _maxDistanceController = TextEditingController(
      text: widget.formData['maxTravelDistance']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.formData['serviceDescription'] ?? '',
    );
    _emergencyService = widget.formData['emergencyService'] ?? false;
  }

  @override
  void dispose() {
    _maxDistanceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Setup',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure your services and pricing',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),
          _buildPricingFields(),
          const SizedBox(height: 24),
          _buildDistanceField(),
          const SizedBox(height: 24),
          _buildEmergencyToggle(),
          const SizedBox(height: 24),
          _buildDescriptionField(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPricingFields() {
    return const SizedBox.shrink();
  }



  Widget _buildDistanceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Max Travel Distance (km)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _maxDistanceController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final distance = int.tryParse(value) ?? 0;
              widget.onDataChanged('maxTravelDistance', distance);
            },
            decoration: InputDecoration(
              hintText: 'e.g., 10',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF6366F1),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emergency Service Available',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Available 24/7 for urgent jobs',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          Switch(
            value: _emergencyService,
            onChanged: (value) {
              setState(() => _emergencyService = value);
              widget.onDataChanged('emergencyService', value);
            },
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Description (Optional)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _descriptionController,
            maxLines: 4,
            onChanged: (value) =>
                widget.onDataChanged('serviceDescription', value),
            decoration: InputDecoration(
              hintText: 'Describe your services and specialties...',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
