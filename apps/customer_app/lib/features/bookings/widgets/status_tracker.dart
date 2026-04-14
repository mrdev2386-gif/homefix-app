import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../../core/utils/booking_step_mapper.dart';

class StatusTracker extends StatelessWidget {
  final String status;

  const StatusTracker({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();
    final currentStepIndex = _getCurrentStepIndex();
    if (kDebugMode) {
      debugPrint('📊 [StatusTracker] Building with status="$status", stepIndex=$currentStepIndex, totalSteps=${steps.length}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking Status',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(steps.length, (index) {
          final step = steps[index];
          final isCompleted = index < currentStepIndex;
          final isCurrent = index == currentStepIndex;
          final isLast = index == steps.length - 1;

          return _buildStep(
            step['title'] as String,
            step['subtitle'] as String,
            step['icon'] as IconData,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isLast: isLast,
          );
        }),
      ],
    );
  }

  Widget _buildStep(
    String title,
    String subtitle,
    IconData icon, {
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    Color iconColor;
    Color lineColor;
    Color textColor;

    if (isCompleted) {
      iconColor = Colors.green;
      lineColor = Colors.green;
      textColor = Colors.black;
    } else if (isCurrent) {
      iconColor = const Color(0xFF6366F1);
      lineColor = Colors.grey.shade300;
      textColor = Colors.black;
    } else {
      iconColor = Colors.grey.shade400;
      lineColor = Colors.grey.shade300;
      textColor = Colors.grey.shade600;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon and Line
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? iconColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor,
                  width: 2,
                ),
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: iconColor,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: lineColor,
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Text
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getSteps() {
    if (BookingStepMapper.isTerminalNegativeState(status)) {
      return [
        {
          'title': 'Request Placed',
          'subtitle': 'Your request was submitted',
          'icon': Icons.receipt_long_rounded,
        },
        {
          'title': BookingStepMapper.getTerminalStateTitle(status),
          'subtitle': 'Booking will not proceed',
          'icon': Icons.cancel_rounded,
        },
      ];
    }

    return BookingStepMapper.getAllSteps()
        .map((step) => {
              'title': step.title,
              'subtitle': step.subtitle,
              'icon': step.icon,
            })
        .toList();
  }

  int _getCurrentStepIndex() {
    final index = BookingStepMapper.getStepIndexFromStatus(status);
    if (kDebugMode) {
      debugPrint('📊 [StatusTracker._getCurrentStepIndex] status="$status" -> index=$index');
    }
    return index;
  }
}
