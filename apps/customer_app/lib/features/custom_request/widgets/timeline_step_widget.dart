import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/utils/custom_request_status_mapper.dart';

/// Reusable Timeline Step Widget
/// 
/// Displays a single step in the vertical timeline with:
/// - Icon (completed/current/pending state)
/// - Connecting line
/// - Step name
/// - Timestamp (optional)
class TimelineStepWidget extends StatelessWidget {
  final TimelineStepData stepData;
  final bool isFirst;
  final bool isLast;
  final DateTime? timestamp;

  const TimelineStepWidget({
    super.key,
    required this.stepData,
    this.isFirst = false,
    this.isLast = false,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Top line (hidden for first step)
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: stepData.isCompleted
                          ? Colors.green
                          : Colors.grey[300],
                    ),
                  ),

                // Icon
                _buildIcon(),

                // Bottom line (hidden for last step)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: stepData.isCompleted
                          ? Colors.green
                          : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : 24,
                top: 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step name
                  Text(
                    stepData.displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: stepData.isCompleted || stepData.isCurrent
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: stepData.isCompleted || stepData.isCurrent
                          ? Colors.black87
                          : Colors.grey[500],
                    ),
                  ),

                  // Timestamp (if available and step is completed)
                  if (timestamp != null && stepData.isCompleted) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(timestamp!),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],

                  // Current step indicator
                  if (stepData.isCurrent) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'In Progress',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    Color iconColor;
    Color backgroundColor;
    IconData iconData;

    if (stepData.isCompleted) {
      iconColor = Colors.white;
      backgroundColor = Colors.green;
      iconData = Icons.check;
    } else if (stepData.isCurrent) {
      iconColor = Colors.white;
      backgroundColor = Colors.blue;
      iconData = stepData.icon;
    } else {
      iconColor = Colors.grey[400]!;
      backgroundColor = Colors.grey[200]!;
      iconData = stepData.icon;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: stepData.isCompleted || stepData.isCurrent
            ? [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        iconData,
        size: 16,
        color: iconColor,
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
