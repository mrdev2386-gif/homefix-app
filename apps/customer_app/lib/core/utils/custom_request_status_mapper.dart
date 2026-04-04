import 'package:flutter/material.dart';

/// SINGLE SOURCE OF TRUTH for Custom Request Status Mapping
/// 
/// This utility provides centralized status-to-timeline mapping
/// to avoid scattered hardcoded logic across the UI.
class CustomRequestStatusMapper {
  /// Timeline steps in order
  static const List<String> timelineSteps = [
    'created',
    'sent_to_admin',
    'admin_approved',
    'sent_to_technician',
    'technician_accepted',
    'payment_pending',
    'service_completed',
  ];

  /// Map Firestore status values to timeline steps
  static List<TimelineStepData> mapStatusToTimeline(String firestoreStatus) {
    // Normalize status
    final status = firestoreStatus.toLowerCase().trim();

    // Determine which steps are completed based on current status
    final completedSteps = <String>[];
    String? currentStep;

    switch (status) {
      case 'pending_admin':
        completedSteps.addAll(['created', 'sent_to_admin']);
        currentStep = 'sent_to_admin';
        break;

      case 'technician_pending':
        completedSteps.addAll(['created', 'sent_to_admin', 'admin_approved', 'sent_to_technician']);
        currentStep = 'sent_to_technician';
        break;

      case 'awaiting_payment':
        completedSteps.addAll([
          'created',
          'sent_to_admin',
          'admin_approved',
          'sent_to_technician',
          'technician_accepted',
          'payment_pending'
        ]);
        currentStep = 'payment_pending';
        break;

      case 'confirmed':
        completedSteps.addAll([
          'created',
          'sent_to_admin',
          'admin_approved',
          'sent_to_technician',
          'technician_accepted',
          'payment_pending'
        ]);
        currentStep = 'service_completed';
        break;

      case 'completed':
        completedSteps.addAll(timelineSteps);
        currentStep = null; // All done
        break;

      case 'admin_rejected':
      case 'technician_rejected':
      case 'cancelled':
        completedSteps.add('created');
        currentStep = null; // Terminal state
        break;

      default:
        // Fallback: just created
        completedSteps.add('created');
        currentStep = 'created';
    }

    // Build timeline data
    return timelineSteps.map((step) {
      final isCompleted = completedSteps.contains(step);
      final isCurrent = step == currentStep;
      final isPending = !isCompleted && !isCurrent;

      return TimelineStepData(
        step: step,
        displayName: _getStepDisplayName(step),
        icon: _getStepIcon(step),
        isCompleted: isCompleted,
        isCurrent: isCurrent,
        isPending: isPending,
      );
    }).toList();
  }

  /// Get display name for timeline step
  static String _getStepDisplayName(String step) {
    switch (step) {
      case 'created':
        return 'Request Created';
      case 'sent_to_admin':
        return 'Sent to Admin';
      case 'admin_approved':
        return 'Admin Approved';
      case 'sent_to_technician':
        return 'Sent to Technician';
      case 'technician_accepted':
        return 'Technician Accepted';
      case 'payment_pending':
        return 'Payment Pending';
      case 'service_completed':
        return 'Service Completed';
      default:
        return step.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Get icon for timeline step
  static IconData _getStepIcon(String step) {
    switch (step) {
      case 'created':
        return Icons.add_circle_outline;
      case 'sent_to_admin':
        return Icons.send;
      case 'admin_approved':
        return Icons.verified;
      case 'sent_to_technician':
        return Icons.person_search;
      case 'technician_accepted':
        return Icons.check_circle;
      case 'payment_pending':
        return Icons.payment;
      case 'service_completed':
        return Icons.done_all;
      default:
        return Icons.circle;
    }
  }

  /// Get CTA buttons based on status
  static List<CTAButton> getCTAButtons(String firestoreStatus) {
    final status = firestoreStatus.toLowerCase().trim();

    switch (status) {
      case 'awaiting_payment':
        return [
          CTAButton(
            label: 'Pay Now',
            icon: Icons.payment,
            action: CTAAction.payNow,
            isPrimary: true,
          ),
        ];

      case 'confirmed':
        return [
          CTAButton(
            label: 'Track Technician',
            icon: Icons.location_on,
            action: CTAAction.trackTechnician,
            isPrimary: true,
          ),
          CTAButton(
            label: 'Call Technician',
            icon: Icons.phone,
            action: CTAAction.callTechnician,
            isPrimary: false,
          ),
        ];

      case 'pending_admin':
        return [
          CTAButton(
            label: 'Cancel Request',
            icon: Icons.cancel,
            action: CTAAction.cancelRequest,
            isPrimary: false,
            isDestructive: true,
          ),
        ];

      case 'technician_pending':
        return [
          CTAButton(
            label: 'View Details',
            icon: Icons.info_outline,
            action: CTAAction.viewDetails,
            isPrimary: false,
          ),
        ];

      case 'completed':
        return [
          CTAButton(
            label: 'Rate Service',
            icon: Icons.star,
            action: CTAAction.rateService,
            isPrimary: true,
          ),
        ];

      default:
        return [];
    }
  }

  /// Get status badge color
  static Color getStatusColor(String firestoreStatus) {
    final status = firestoreStatus.toLowerCase().trim();

    switch (status) {
      case 'pending_admin':
        return Colors.orange;
      case 'technician_pending':
        return Colors.blue;
      case 'awaiting_payment':
        return Colors.amber;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'admin_rejected':
      case 'technician_rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get user-friendly status text
  static String getStatusDisplayText(String firestoreStatus) {
    final status = firestoreStatus.toLowerCase().trim();

    switch (status) {
      case 'pending_admin':
        return 'Pending Admin Review';
      case 'technician_pending':
        return 'Awaiting Technician';
      case 'awaiting_payment':
        return 'Payment Required';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'admin_rejected':
        return 'Rejected by Admin';
      case 'technician_rejected':
        return 'Technician Declined';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }
}

/// Timeline step data model
class TimelineStepData {
  final String step;
  final String displayName;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;
  final bool isPending;

  TimelineStepData({
    required this.step,
    required this.displayName,
    required this.icon,
    required this.isCompleted,
    required this.isCurrent,
    required this.isPending,
  });
}

/// CTA button data model
class CTAButton {
  final String label;
  final IconData icon;
  final CTAAction action;
  final bool isPrimary;
  final bool isDestructive;

  CTAButton({
    required this.label,
    required this.icon,
    required this.action,
    this.isPrimary = false,
    this.isDestructive = false,
  });
}

/// CTA action types
enum CTAAction {
  payNow,
  trackTechnician,
  callTechnician,
  cancelRequest,
  viewDetails,
  rateService,
}
