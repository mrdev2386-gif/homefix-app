import 'package:flutter/foundation.dart';

/// Valid booking statuses (STANDARDIZED)
const List<String> validBookingStatuses = [
  'pending_admin_approval',
  'approved_by_admin',
  'technician_accepted',
  'service_in_progress',
  'service_completed',
  'rejected',
  // Legacy statuses for backward compatibility
  'pending_admin_review',
  'admin_approved',
  'awaiting_payment',
  'confirmed',
  'in_progress',
  'completed',
  'cancelled',
  'pending',
  'accepted',
  'on_the_way',
];

/// Sanitize booking status to ensure it's always a valid value
/// Returns 'processing' for null or unknown statuses (safe fallback)
String sanitizeBookingStatus(String? status) {
  if (status == null || status.isEmpty) {
    if (kDebugMode) {
      debugPrint('[BOOKING_STATUS_SANITIZED] Null/empty status → defaulting to processing');
    }
    return 'processing';
  }
  
  // Check if status is in the valid list (case-insensitive comparison)
  final normalizedStatus = status.toLowerCase().trim();
  if (validBookingStatuses.contains(normalizedStatus)) {
    return normalizedStatus;
  }
  
  // Invalid status - log warning and return safe fallback
  if (kDebugMode) {
    debugPrint('[BOOKING_STATUS_SANITIZED] Unknown status "$status" → defaulting to processing');
  }
  return 'processing';
}

/// Check if a status is valid
bool isValidBookingStatus(String? status) {
  if (status == null || status.isEmpty) return false;
  return validBookingStatuses.contains(status.toLowerCase().trim());
}

/// Get display name for booking status
String getBookingStatusDisplayName(String status) {
  final sanitized = sanitizeBookingStatus(status);
  switch (sanitized) {
    case 'pending_admin_approval':
    case 'pending_admin_review':
      return 'Pending Admin Approval';
    case 'approved_by_admin':
    case 'admin_approved':
      return 'Approved by Admin';
    case 'technician_accepted':
      return 'Technician Accepted';
    case 'service_in_progress':
    case 'in_progress':
      return 'Service in Progress';
    case 'service_completed':
    case 'completed':
      return 'Service Completed';
    case 'rejected':
      return 'Rejected';
    case 'awaiting_payment':
      return 'Awaiting Payment';
    case 'confirmed':
      return 'Confirmed';
    case 'cancelled':
      return 'Cancelled';
    // Legacy statuses
    case 'pending':
      return 'Pending';
    case 'accepted':
      return 'Accepted';
    case 'on_the_way':
      return 'On the Way';
    // Safe fallback
    default:
      return 'Processing';
  }
}
