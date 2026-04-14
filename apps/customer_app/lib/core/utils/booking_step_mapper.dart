import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Canonical booking step definition
class BookingStep {
  final int index;
  final String status;
  final String title;
  final String subtitle;
  final IconData icon;

  const BookingStep({
    required this.index,
    required this.status,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Centralized booking step mapper - SINGLE SOURCE OF TRUTH
/// All UI screens use this mapping to ensure consistency
class BookingStepMapper {
  static const List<BookingStep> steps = [
    BookingStep(
      index: 0,
      status: 'pending_admin_approval',
      title: 'Request Placed',
      subtitle: 'Booking created successfully',
      icon: Icons.receipt_long_rounded,
    ),
    BookingStep(
      index: 1,
      status: 'approved_by_admin',
      title: 'Admin Approved',
      subtitle: 'Request verified and approved',
      icon: Icons.verified_rounded,
    ),
    BookingStep(
      index: 2,
      status: 'technician_accepted',
      title: 'Technician Assigned',
      subtitle: 'Professional assigned to your job',
      icon: Icons.person_add_rounded,
    ),
    BookingStep(
      index: 3,
      status: 'service_in_progress',
      title: 'Work Started',
      subtitle: 'Service is in progress',
      icon: Icons.engineering_rounded,
    ),
    BookingStep(
      index: 4,
      status: 'service_completed',
      title: 'Completed',
      subtitle: 'Service finished successfully',
      icon: Icons.check_circle_rounded,
    ),
  ];

  /// Get all steps for normal flow
  static List<BookingStep> getAllSteps() => steps;

  /// Get step by index
  static BookingStep? getStepByIndex(int index) {
    try {
      return steps.firstWhere((s) => s.index == index);
    } catch (e) {
      return null;
    }
  }

  /// Get step by status
  static BookingStep? getStepByStatus(String status) {
    try {
      return steps.firstWhere((s) => s.status == status);
    } catch (e) {
      return null;
    }
  }

  /// Map any booking status to canonical step index
  /// Returns -1 for terminal negative states (cancelled/rejected)
  static int getStepIndexFromStatus(String status) {
    final statusLower = status.toLowerCase();
    if (kDebugMode) {
      debugPrint('🗐️ [BookingStepMapper] Mapping status: "$status" -> "$statusLower"');
    }

    // Terminal negative states
    if (statusLower.contains('cancel') || 
        statusLower.contains('reject') || 
        statusLower == 'admin_rejected' ||
        statusLower == 'technician_rejected') {
      return -1;
    }

    // Map to canonical statuses
    switch (statusLower) {
      // Step 0: pending_admin_approval
      case 'pending_admin_approval':
      case 'pending_admin_review':
      case 'pending':
      case 'pending_admin':
        return 0;

      // Step 1: approved_by_admin
      case 'approved_by_admin':
      case 'admin_approved':
      case 'technician_pending':
        return 1;

      // Step 2: technician_accepted
      case 'technician_accepted':
      case 'assigned':
      case 'accepted':
      case 'awaiting_payment':
      case 'confirmed':
        return 2;

      // Step 3: service_in_progress
      case 'service_in_progress':
      case 'in_progress':
      case 'started':
      case 'on_the_way':
        return 3;

      // Step 4: service_completed
      case 'service_completed':
      case 'completed':
        return 4;

      default:
        if (kDebugMode) {
          debugPrint('⚠️ [BookingStepMapper] Unknown status: "$statusLower" - defaulting to step 0');
        }
        return 0; // Default to first step
    }
  }

  /// Check if status is a terminal negative state
  static bool isTerminalNegativeState(String status) {
    final statusLower = status.toLowerCase();
    return statusLower.contains('cancel') || 
           statusLower.contains('reject') || 
           statusLower == 'admin_rejected' ||
           statusLower == 'technician_rejected';
  }

  /// Get terminal state title
  static String getTerminalStateTitle(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('reject') || statusLower == 'admin_rejected') {
      return 'Request Rejected';
    }
    return 'Booking Cancelled';
  }
}
