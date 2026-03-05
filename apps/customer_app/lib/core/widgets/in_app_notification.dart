import 'package:flutter/material.dart';
import 'dart:async';

/// ================================================
/// IN-APP NOTIFICATION WIDGET
/// ================================================
///
/// Modern, animated notification UI that displays
/// above content with:
/// - Slide-in animation from top
/// - Icon based on notification type
/// - Auto-dismiss after 4 seconds
/// - Customizable colors and icons
/// - Tap to dismiss

// Notification type enum
enum InAppNotificationType {
  success,     // Green
  error,       // Red
  warning,     // Orange
  info,        // Blue
  booking,     // Custom color
  custom,      // Custom color
}

// ================================================
// SHOW NOTIFICATION - Main entry point
// ================================================

void showInAppNotification(
  BuildContext context, {
  required String title,
  required String body,
  InAppNotificationType type = InAppNotificationType.info,
  Duration duration = const Duration(seconds: 4),
  VoidCallback? onTap,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (_) => InAppNotificationWidget(
      title: title,
      body: body,
      type: type,
      duration: duration,
      onDismiss: () => overlayEntry.remove(),
      onTap: () {
        overlayEntry.remove();
        onTap?.call();
      },
    ),
  );

  overlay.insert(overlayEntry);
}

// ================================================
// IN-APP NOTIFICATION WIDGET (Stateful)
// ================================================

class InAppNotificationWidget extends StatefulWidget {
  final String title;
  final String body;
  final InAppNotificationType type;
  final Duration duration;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const InAppNotificationWidget({
    Key? key,
    required this.title,
    required this.body,
    required this.type,
    required this.duration,
    required this.onDismiss,
    this.onTap,
  }) : super(key: key);

  @override
  State<InAppNotificationWidget> createState() =>
      _InAppNotificationWidgetState();
}

class _InAppNotificationWidgetState extends State<InAppNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Start animation
    _animationController.forward();

    // Auto-dismiss timer
    _dismissTimer = Timer(widget.duration, _dismissNotification);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _dismissNotification() async {
    await _animationController.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: widget.onTap ?? _dismissNotification,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap ?? _dismissNotification,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // ICON
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getIconBackgroundColor(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            _getIconData(),
                            color: _getIconColor(),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // CONTENT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Body
                            Text(
                              widget.body,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 13,
                                height: 1.3,
                                color: Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // CLOSE BUTTON
                      GestureDetector(
                        onTap: _dismissNotification,
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================================================
  // COLOR & ICON HELPERS
  // ================================================

  Color _getBackgroundColor() {
    switch (widget.type) {
      case InAppNotificationType.success:
        return const Color(0xFFE8F5E9); // Light green
      case InAppNotificationType.error:
        return const Color(0xFFFFEBEE); // Light red
      case InAppNotificationType.warning:
        return const Color(0xFFFFF3E0); // Light orange
      case InAppNotificationType.info:
        return const Color(0xFFE3F2FD); // Light blue
      case InAppNotificationType.booking:
        return const Color(0xFFECE7FF); // Light purple
      case InAppNotificationType.custom:
        return const Color(0xFFE3F2FD); // Light blue
    }
  }

  Color _getIconColor() {
    switch (widget.type) {
      case InAppNotificationType.success:
        return const Color(0xFF2E7D32); // Dark green
      case InAppNotificationType.error:
        return const Color(0xFFC62828); // Dark red
      case InAppNotificationType.warning:
        return const Color(0xFFE65100); // Dark orange
      case InAppNotificationType.info:
        return const Color(0xFF1A73E8); // Dark blue
      case InAppNotificationType.booking:
        return const Color(0xFF6200EE); // Purple
      case InAppNotificationType.custom:
        return const Color(0xFF1A73E8); // Dark blue
    }
  }

  Color _getIconBackgroundColor() {
    return _getIconColor().withOpacity(0.1);
  }

  IconData _getIconData() {
    switch (widget.type) {
      case InAppNotificationType.success:
        return Icons.check_circle_outline;
      case InAppNotificationType.error:
        return Icons.error_outline;
      case InAppNotificationType.warning:
        return Icons.warning_amber;
      case InAppNotificationType.info:
        return Icons.info_outline;
      case InAppNotificationType.booking:
        return Icons.event_note;
      case InAppNotificationType.custom:
        return Icons.build_circle_outlined;
    }
  }
}

// ================================================
// HELPER: Map notification type to InAppType
// ================================================

InAppNotificationType mapFirebaseNotificationType(String type) {
  switch (type.toLowerCase()) {
    case 'booking_confirmed':
    case 'booking_cancelled':
    case 'technician_en_route':
    case 'technician_arrived':
    case 'job_completed':
    case 'new_instant_booking':
      return InAppNotificationType.booking;

    case 'payment_success':
      return InAppNotificationType.success;

    case 'payment_failed':
      return InAppNotificationType.error;

    case 'custom_request_accepted':
      return InAppNotificationType.custom;

    case 'new_request_nearby':
      return InAppNotificationType.info;

    default:
      return InAppNotificationType.info;
  }
}

// ================================================
// EXTENSION: Show from Firebase Message
// ================================================

extension InAppNotificationExtension on BuildContext {
  void showNotificationFromMessage(
    String title,
    String body, {
    String? type,
    VoidCallback? onTap,
  }) {
    showInAppNotification(
      this,
      title: title,
      body: body,
      type: type != null ? mapFirebaseNotificationType(type) : InAppNotificationType.info,
      onTap: onTap,
    );
  }
}
