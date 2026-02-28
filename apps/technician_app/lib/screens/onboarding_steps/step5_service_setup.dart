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
  late TextEditingController _basePriceController;
  late TextEditingController _visitingChargeController;
  late TextEditingController _maxDistanceController;
  late TextEditingController _descriptionController;
  bool _emergencyService = false;
  List<String> _selectedServices = [];

  final List<Map<String, String>> _serviceOptions = [
    {'id': 'installation', 'name': 'Installation', 'icon': '🔧'},
    {'id': 'repair', 'name': 'Repair', 'icon': '🔨'},
    {'id': 'maintenance', 'name': 'Maintenance', 'icon': '🛠️'},
    {'id': 'inspection', 'name': 'Inspection', 'icon': '🔍'},
    {'id': 'consultation', 'name': 'Consultation', 'icon': '💬'},
    {'id': 'emergency', 'name': 'Emergency Service', 'icon': '🚨'},
  ];

  @override
  void initState() {
    super.initState();
    _basePriceController = TextEditingController(
      text: widget.formData['basePrice']?.toString() ?? '',
    );
    _visitingChargeController = TextEditingController(
      text: widget.formData['visitingCharge']?.toString() ?? '',
    );
    _maxDistanceController = TextEditingController(
      text: widget.formData['maxTravelDistance']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.formData['serviceDescription'] ?? '',
    );
    _emergencyService = widget.formData['emergencyService'] ?? false;
    _selectedServices =
        List<String>.from(widget.formData['offeredServices'] ?? []);
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    _visitingChargeController.dispose();
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
          _buildServicesSelector(),
          const SizedBox(height: 24),
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

  Widget _buildServicesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services Offered',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _serviceOptions.map((service) {
            final isSelected = _selectedServices.contains(service['id']);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedServices.remove(service['id']);
                  } else {
                    _selectedServices.add(service['id']!);
                  }
                });
                widget.onDataChanged('offeredServices', _selectedServices);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : const Color(0xFFE2E8F0),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service['icon']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service['name']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPricingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: _buildPriceField(
                controller: _basePriceController,
                label: 'Base Price',
                hint: '₹500',
                onChanged: (value) {
                  final price = int.tryParse(value) ?? 0;
                  widget.onDataChanged('basePrice', price);
                },
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              fit: FlexFit.loose,
              child: _buildPriceField(
                controller: _visitingChargeController,
                label: 'Visiting Charge',
                hint: '₹100',
                onChanged: (value) {
                  final charge = int.tryParse(value) ?? 0;
                  widget.onDataChanged('visitingCharge', charge);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
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
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: const Icon(
                Icons.currency_rupee_outlined,
                color: Color(0xFF6366F1),
                size: 18,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
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
