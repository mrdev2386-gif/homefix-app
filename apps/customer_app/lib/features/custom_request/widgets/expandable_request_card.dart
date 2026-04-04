import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/utils/custom_request_status_mapper.dart';
import 'package:customer_app/features/custom_request/widgets/timeline_step_widget.dart';

/// Expandable Request Card with Timeline
/// 
/// Features:
/// - Collapsed: Shows basic info (service name, date, status badge)
/// - Expanded: Shows full timeline + dynamic CTA buttons
/// - Single source of truth: Uses CustomRequestStatusMapper
class ExpandableRequestCard extends StatefulWidget {
  final Map<String, dynamic> request;
  final VoidCallback? onPayNow;
  final VoidCallback? onTrackTechnician;
  final VoidCallback? onCallTechnician;
  final VoidCallback? onCancelRequest;
  final VoidCallback? onViewDetails;
  final VoidCallback? onRateService;

  const ExpandableRequestCard({
    super.key,
    required this.request,
    this.onPayNow,
    this.onTrackTechnician,
    this.onCallTechnician,
    this.onCancelRequest,
    this.onViewDetails,
    this.onRateService,
  });

  @override
  State<ExpandableRequestCard> createState() => _ExpandableRequestCardState();
}

class _ExpandableRequestCardState extends State<ExpandableRequestCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.request['status'] ?? 'pending_admin';
    final statusColor = CustomRequestStatusMapper.getStatusColor(status);
    final statusText = CustomRequestStatusMapper.getStatusDisplayText(status);

    DateTime createdAt;
    try {
      if (widget.request['createdAt'] is Timestamp) {
        createdAt = (widget.request['createdAt'] as Timestamp).toDate();
      } else if (widget.request['createdAt'] is String) {
        createdAt = DateTime.parse(widget.request['createdAt']);
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Collapsed header (always visible)
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and status badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.request['title'] ?? 'Untitled Request',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Category and date
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.request['category'] ?? 'N/A',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM dd, yyyy').format(createdAt),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Expand/collapse indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isExpanded ? 'Hide Details' : 'View Timeline',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      RotationTransition(
                        turns: Tween(begin: 0.0, end: 0.5).animate(_expandAnimation),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded content (timeline + actions)
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline section
                      _buildTimeline(status),

                      const SizedBox(height: 20),

                      // CTA buttons
                      _buildCTAButtons(status),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String status) {
    // Get timeline steps from mapper (single source of truth)
    final timelineSteps = CustomRequestStatusMapper.mapStatusToTimeline(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Timeline',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(timelineSteps.length, (index) {
          final stepData = timelineSteps[index];
          return TimelineStepWidget(
            stepData: stepData,
            isFirst: index == 0,
            isLast: index == timelineSteps.length - 1,
            timestamp: _getTimestampForStep(stepData.step),
          );
        }),
      ],
    );
  }

  Widget _buildCTAButtons(String status) {
    // Get CTA buttons from mapper (single source of truth)
    final ctaButtons = CustomRequestStatusMapper.getCTAButtons(status);

    if (ctaButtons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: ctaButtons.map((button) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildCTAButton(button),
        );
      }).toList(),
    );
  }

  Widget _buildCTAButton(CTAButton button) {
    final VoidCallback? onPressed = _getCallbackForAction(button.action);

    if (button.isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(button.icon, size: 18),
        label: Text(
          button.label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: button.isDestructive ? Colors.red : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(button.icon, size: 18),
        label: Text(
          button.label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: button.isDestructive ? Colors.red : AppTheme.primaryColor,
          side: BorderSide(
            color: button.isDestructive ? Colors.red : AppTheme.primaryColor,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  VoidCallback? _getCallbackForAction(CTAAction action) {
    switch (action) {
      case CTAAction.payNow:
        return widget.onPayNow;
      case CTAAction.trackTechnician:
        return widget.onTrackTechnician;
      case CTAAction.callTechnician:
        return widget.onCallTechnician;
      case CTAAction.cancelRequest:
        return widget.onCancelRequest;
      case CTAAction.viewDetails:
        return widget.onViewDetails;
      case CTAAction.rateService:
        return widget.onRateService;
    }
  }

  DateTime? _getTimestampForStep(String step) {
    // Map step to Firestore field
    String? fieldName;
    switch (step) {
      case 'created':
        fieldName = 'createdAt';
        break;
      case 'admin_approved':
        fieldName = 'adminApprovedAt';
        break;
      case 'technician_accepted':
        fieldName = 'technicianAcceptedAt';
        break;
      case 'payment_pending':
        fieldName = 'confirmedAt';
        break;
      default:
        return null;
    }

    if (fieldName == null) return null;

    try {
      final value = widget.request[fieldName];
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      }
    } catch (e) {
      // Ignore
    }

    return null;
  }
}
