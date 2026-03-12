import 'package:flutter/foundation.dart';

/// Valid booking statuses (NEW FLOW)
const List<String> validBookingStatuses = [
  'pending_admin_review',
  'admin_approved',
  'technician_accepted',
  'awaiting_payment',
  'confirmed',
  'in_progress',
  'completed',
  'cancelled',
  // Legacy statuses for backward compatibility
  'pending',
  'accepted',
  'on_the_way',
];

/// Sanitize booking status to ensure it's always a valid value
/// Returns 'processing' for null or unknown statuses (safe fallback)
String sanitizeBookingStatus(String? status) {
  if (status == null || status.isEmpty) {
    debugPrint('[BOOKING_STATUS_SANITIZED] Null/empty status → defaulting to processing');
    return 'processing';
  }
  
  // Check if status is in the valid list (case-insensitive comparison)
  final normalizedStatus = status.toLowerCase().trim();
  if (validBookingStatuses.contains(normalizedStatus)) {
    return normalizedStatus;
  }
  
  // Invalid status - log warning and return safe fallback
  debugPrint('[BOOKING_STATUS_SANITIZED] Unknown status "$status" → defaulting to processing');
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
    case 'pending_admin_review':
      return 'Pending Admin Review';
    case 'admin_approved':
      return 'Admin Approved';
    case 'technician_accepted':
      return 'Technician Accepted';
    case 'awaiting_payment':
      return 'Awaiting Payment';
    case 'confirmed':
      return 'Confirmed';
    case 'in_progress':
      return 'In Progress';
    case 'completed':
      return 'Completed';
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
