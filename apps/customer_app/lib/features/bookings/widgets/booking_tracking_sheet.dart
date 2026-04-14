import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking.dart';
import '../../../core/utils/booking_step_mapper.dart';

class BookingTrackingSheet extends StatelessWidget {
  final Booking booking;

  const BookingTrackingSheet({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final steps = _getTimelineSteps();
    final currentStepIndex = _getCurrentStepIndex();

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.timeline, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Track Booking',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${booking.id.substring(0, 8).toUpperCase()}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Timeline with proper scrolling and bottom padding
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  children: List.generate(steps.length, (index) {
                    final step = steps[index];
                    final isCompleted = index < currentStepIndex;
                    final isCurrent = index == currentStepIndex;
                    final isLast = index == steps.length - 1;

                    return _buildTimelineStep(
                      step['title'] as String,
                      step['subtitle'] as String,
                      step['icon'] as IconData,
                      step['timestamp'] as DateTime?,
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                      isLast: isLast,
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(
    String title,
    String subtitle,
    IconData icon,
    DateTime? timestamp, {
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    Color iconColor;
    Color lineColor;
    Color bgColor;

    if (isCompleted) {
      iconColor = const Color(0xFF10B981);
      lineColor = const Color(0xFF10B981);
      bgColor = const Color(0xFF10B981);
    } else if (isCurrent) {
      iconColor = const Color(0xFF6366F1);
      lineColor = Colors.grey[300]!;
      bgColor = const Color(0xFF6366F1);
    } else {
      iconColor = Colors.grey[400]!;
      lineColor = Colors.grey[300]!;
      bgColor = Colors.grey[400]!;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: bgColor, width: 2),
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : icon,
                color: bgColor,
                size: 24,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: lineColor,
              ),
          ],
        ),
        const SizedBox(width: 16),
        
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.w600,
                    color: isCurrent || isCompleted ? Colors.black : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                if (timestamp != null && (isCompleted || isCurrent)) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      DateFormat('MMM dd, hh:mm a').format(timestamp),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: bgColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getTimelineSteps() {
    if (BookingStepMapper.isTerminalNegativeState(booking.status)) {
      return [
        {
          'title': 'Request Placed',
          'subtitle': 'Your booking was created',
          'icon': Icons.receipt_long_rounded,
          'timestamp': booking.createdAt,
        },
        {
          'title': BookingStepMapper.getTerminalStateTitle(booking.status),
          'subtitle': 'This booking will not proceed',
          'icon': Icons.cancel_rounded,
          'timestamp': booking.updatedAt,
        },
      ];
    }

    return BookingStepMapper.getAllSteps()
        .map((step) => {
              'title': step.title,
              'subtitle': step.subtitle,
              'icon': step.icon,
              'timestamp': _getStepTimestamp(step.index),
            })
        .toList();
  }

  int _getCurrentStepIndex() {
    return BookingStepMapper.getStepIndexFromStatus(booking.status);
  }

  DateTime? _getStepTimestamp(int stepIndex) {
    // Try to get from statusHistory if available
    if (booking.statusHistory != null && booking.statusHistory!.isNotEmpty) {
      try {
        if (stepIndex < booking.statusHistory!.length) {
          final historyItem = booking.statusHistory![stepIndex];
          if (historyItem['timestamp'] != null) {
            return (historyItem['timestamp'] as dynamic).toDate();
          }
        }
      } catch (e) {
        // Fallback to generated timestamps
      }
    }

    // Generate timestamps based on current step
    final currentStep = _getCurrentStepIndex();
    if (stepIndex > currentStep) return null;
    if (stepIndex == 0) return booking.createdAt;
    if (stepIndex == currentStep) return booking.updatedAt;
    
    // Estimate intermediate timestamps
    final duration = booking.updatedAt.difference(booking.createdAt);
    final stepDuration = duration ~/ (currentStep > 0 ? currentStep : 1);
    return booking.createdAt.add(stepDuration * stepIndex);
  }
}
