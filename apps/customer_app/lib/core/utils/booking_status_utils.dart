import 'package:flutter/foundation.dart';

/// Valid booking statuses
const List<String> validBookingStatuses = [
  'pending',
  'accepted',
  'on_the_way',
  'in_progress',
  'completed',
  'cancelled',
];

/// Sanitize booking status to ensure it's always a valid value
/// Returns 'pending' for null or unknown statuses
String sanitizeBookingStatus(String? status) {
  if (status == null || status.isEmpty) {
    debugPrint('[BOOKING_STATUS_SANITIZED] Null/empty status → defaulting to pending');
    return 'pending';
  }
  
  // Check if status is in the valid list (case-insensitive comparison)
  final normalizedStatus = status.toLowerCase().trim();
  if (validBookingStatuses.contains(normalizedStatus)) {
    return normalizedStatus;
  }
  
  // Invalid status - log warning and return pending
  debugPrint('[BOOKING_STATUS_SANITIZED] Unknown status "$status" → defaulting to pending');
  return 'pending';
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
    case 'pending':
      return 'Pending';
    case 'accepted':
      return 'Accepted';
    case 'on_the_way':
      return 'On the Way';
    case 'in_progress':
      return 'In Progress';
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    default:
      return 'Pending';
  }
}
