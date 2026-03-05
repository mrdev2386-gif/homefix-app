import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingProgressTracker extends StatelessWidget {
  final String currentStatus;

  const BookingProgressTracker({
    super.key,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();
    final currentIndex = _getCurrentStepIndex();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Progress',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length, (index) {
              final isActive = index <= currentIndex;
              final isLast = index == steps.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    _buildStep(
                      step: steps[index],
                      isActive: isActive,
                      isCurrent: index == currentIndex,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isActive
                              ? const Color(0xFF6366F1)
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required _ProgressStep step,
    required bool isActive,
    required bool isCurrent,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCurrent ? step.icon : (isActive ? Icons.check : step.icon),
            size: 16,
            color: isActive ? Colors.white : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF6366F1) : Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }

  List<_ProgressStep> _getSteps() {
    return [
      _ProgressStep(
        status: 'pending_admin',
        label: 'Pending',
        icon: Icons.hourglass_empty_rounded,
      ),
      _ProgressStep(
        status: 'technician_pending',
        label: 'Assigned',
        icon: Icons.person_rounded,
      ),
      _ProgressStep(
        status: 'awaiting_payment',
        label: 'Payment',
        icon: Icons.payment_rounded,
      ),
      _ProgressStep(
        status: 'confirmed',
        label: 'Confirmed',
        icon: Icons.check_circle_rounded,
      ),
      _ProgressStep(
        status: 'completed',
        label: 'Done',
        icon: Icons.done_all_rounded,
      ),
    ];
  }

  int _getCurrentStepIndex() {
    final steps = _getSteps();
    final normalizedStatus = currentStatus.toLowerCase();

    // Map statuses to step indices
    switch (normalizedStatus) {
      case 'pending':
      case 'pending_admin':
        return 0;
      case 'technician_pending':
      case 'assigned':
      case 'accepted':
        return 1;
      case 'awaiting_payment':
        return 2;
      case 'confirmed':
      case 'on_the_way':
        return 3;
      case 'in_progress':
      case 'started':
        return 3;
      case 'completed':
        return 4;
      case 'cancelled':
        return -1; // Special case
      default:
        return 0;
    }
  }
}

class _ProgressStep {
  final String status;
  final String label;
  final IconData icon;

  _ProgressStep({
    required this.status,
    required this.label,
    required this.icon,
  });
}
