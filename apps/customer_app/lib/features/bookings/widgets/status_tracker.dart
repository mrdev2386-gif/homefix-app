import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusTracker extends StatelessWidget {
  final String status;

  const StatusTracker({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();
    final currentStepIndex = _getCurrentStepIndex();

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
    final statusLower = status.toLowerCase();

    // Handle terminal negative statuses
    if (statusLower == 'cancelled' || statusLower == 'admin_rejected' || statusLower == 'technician_rejected') {
      String title = 'Cancelled';
      if (statusLower == 'admin_rejected') title = 'Rejected by Admin';
      if (statusLower == 'technician_rejected') title = 'Declined by Technician';

      return [
        {
          'title': 'Booking Requested',
          'subtitle': 'Your request was submitted',
          'icon': Icons.receipt_long,
        },
        {
          'title': title,
          'subtitle': 'Booking will not proceed',
          'icon': Icons.cancel,
        },
      ];
    }

    return [
      {
        'title': 'Booking Requested',
        'subtitle': 'Awaiting admin approval',
        'icon': Icons.history,
      },
      {
        'title': 'Technician Assigned',
        'subtitle': 'Technician is reviewing',
        'icon': Icons.person_search,
      },
      {
        'title': 'Payment & Confirmation',
        'subtitle': 'Secure your booking',
        'icon': Icons.payments,
      },
      {
        'title': 'Service in Progress',
        'subtitle': 'Technician is working',
        'icon': Icons.build,
      },
      {
        'title': 'Completed',
        'subtitle': 'Service is done',
        'icon': Icons.check_circle,
      },
    ];
  }

  int _getCurrentStepIndex() {
    final statusLower = status.toLowerCase();
    
    if (statusLower == 'cancelled' || statusLower == 'admin_rejected' || statusLower == 'technician_rejected') {
      return 1;
    }

    switch (statusLower) {
      case 'pending_admin':
        return 0;
      case 'technician_pending':
      case 'assigned':
        return 1;
      case 'awaiting_payment':
      case 'confirmed':
        return 2;
      case 'on_the_way':
      case 'started':
      case 'in_progress':
        return 3;
      case 'completed':
        return 4;
      default:
        // Fallback for legacy
        if (statusLower == 'pending') return 0;
        return 0;
    }
  }
}
