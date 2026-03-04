import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_theme.dart';

/// Urgent Booking Configuration Widget
class UrgentBookingConfigWidget extends StatefulWidget {
  final bool enabled;
  final String? arrivalTime;
  final int? urgentFee;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String?> onArrivalTimeChanged;
  final ValueChanged<int?> onUrgentFeeChanged;

  const UrgentBookingConfigWidget({
    super.key,
    required this.enabled,
    this.arrivalTime,
    this.urgentFee,
    required this.onEnabledChanged,
    required this.onArrivalTimeChanged,
    required this.onUrgentFeeChanged,
  });

  @override
  State<UrgentBookingConfigWidget> createState() => _UrgentBookingConfigWidgetState();
}

class _UrgentBookingConfigWidgetState extends State<UrgentBookingConfigWidget> {
  late bool _enabled;
  late String? _arrivalTime;
  late int? _urgentFee;

  final List<String> _arrivalTimeOptions = ['30-60min', '1-2hours', '2-3hours'];
  final List<int> _urgentFeeOptions = [50, 100, 150, 200, 250, 300];

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
    _arrivalTime = widget.arrivalTime;
    _urgentFee = widget.urgentFee;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Urgent Booking (Express Service)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Allow customers to book urgent services',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _enabled,
                  onChanged: (value) {
                    setState(() => _enabled = value);
                    widget.onEnabledChanged(value);
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
          if (_enabled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Arrival Time',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _arrivalTimeOptions.map((option) {
                      final isSelected = _arrivalTime == option;
                      return ChoiceChip(
                        label: Text(
                          _formatArrivalTime(option),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _arrivalTime = selected ? option : null);
                          widget.onArrivalTimeChanged(selected ? option : null);
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppTheme.primaryColor,
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Urgent Service Charge',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _urgentFeeOptions.map((fee) {
                      final isSelected = _urgentFee == fee;
                      return ChoiceChip(
                        label: Text(
                          '₹$fee',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _urgentFee = selected ? fee : null);
                          widget.onUrgentFeeChanged(selected ? fee : null);
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppTheme.primaryColor,
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatArrivalTime(String time) {
    switch (time) {
      case '30-60min':
        return '30–60 minutes';
      case '1-2hours':
        return '1–2 hours';
      case '2-3hours':
        return '2–3 hours';
      default:
        return time;
    }
  }
}

/// Night Service Configuration Widget
class NightServiceConfigWidget extends StatefulWidget {
  final bool enabled;
  final int? nightCharge;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int?> onNightChargeChanged;

  const NightServiceConfigWidget({
    super.key,
    required this.enabled,
    this.nightCharge,
    required this.onEnabledChanged,
    required this.onNightChargeChanged,
  });

  @override
  State<NightServiceConfigWidget> createState() => _NightServiceConfigWidgetState();
}

class _NightServiceConfigWidgetState extends State<NightServiceConfigWidget> {
  late bool _enabled;
  late int? _nightCharge;

  final List<int> _nightChargeOptions = [50, 100, 150, 200];

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
    _nightCharge = widget.nightCharge;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Night Service Availability',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '10:00 PM – 6:00 AM',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _enabled,
                  onChanged: (value) {
                    setState(() => _enabled = value);
                    widget.onEnabledChanged(value);
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
          if (_enabled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Night Service Charge (Optional)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _nightChargeOptions.map((charge) {
                      final isSelected = _nightCharge == charge;
                      return ChoiceChip(
                        label: Text(
                          '₹$charge',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _nightCharge = selected ? charge : null);
                          widget.onNightChargeChanged(selected ? charge : null);
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppTheme.primaryColor,
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
