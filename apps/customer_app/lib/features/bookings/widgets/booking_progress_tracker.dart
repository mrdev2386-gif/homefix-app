import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/booking_step_mapper.dart';

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
    return BookingStepMapper.getAllSteps()
        .map((step) => _ProgressStep(
              status: step.status,
              label: step.title,
              icon: step.icon,
            ))
        .toList();
  }

  int _getCurrentStepIndex() {
    return BookingStepMapper.getStepIndexFromStatus(currentStatus);
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
