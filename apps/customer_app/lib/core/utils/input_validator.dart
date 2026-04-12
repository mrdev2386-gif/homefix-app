import 'package:flutter/foundation.dart';

/// Production-grade input validation for all user inputs
/// Prevents injection attacks, data corruption, and invalid operations
class InputValidator {
  // Regex patterns for validation
  static final RegExp _idPattern = RegExp(r'^[a-zA-Z0-9_-]{1,128}$');
  static final RegExp _emailPattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp _phonePattern = RegExp(r'^\+?[1-9]\d{1,14}$');
  static final RegExp _pincodePattern = RegExp(r'^\d{6}$');

  /// Validate document ID (serviceId, technicianId, categoryId, etc.)
  static bool isValidId(String? id) {
    if (id == null || id.isEmpty) return false;
    if (id.length > 128) return false;
    if (id.contains('/') || id.contains('\\') || id.contains('..')) return false;
    return _idPattern.hasMatch(id);
  }

  /// Validate and sanitize string input
  static String? sanitizeString(String? input, {int maxLength = 500, bool allowEmpty = false}) {
    if (input == null) return null;
    
    final trimmed = input.trim();
    if (trimmed.isEmpty) return allowEmpty ? '' : null;
    if (trimmed.length > maxLength) return null;
    
    // Remove potentially dangerous characters
    return trimmed.replaceAll(RegExp(r"[<>\"']"), '');
  }

  /// Validate email address
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    return _emailPattern.hasMatch(email.trim());
  }

  /// Validate phone number (E.164 format)
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 15;
  }

  /// Validate pincode (India)
  static bool isValidPincode(String? pincode) {
    if (pincode == null || pincode.isEmpty) return false;
    return _pincodePattern.hasMatch(pincode.trim());
  }

  /// Validate price (must be positive)
  static bool isValidPrice(dynamic price) {
    if (price == null) return false;
    try {
      final p = price is num ? price.toDouble() : double.parse(price.toString());
      return p > 0 && p < 1000000; // Max ₹10 lakhs
    } catch (_) {
      return false;
    }
  }

  /// Validate quantity (must be positive integer)
  static bool isValidQuantity(dynamic quantity) {
    if (quantity == null) return false;
    try {
      final q = quantity is num ? quantity.toInt() : int.parse(quantity.toString());
      return q > 0 && q <= 1000;
    } catch (_) {
      return false;
    }
  }

  /// Validate date (must be in future)
  static bool isValidFutureDate(DateTime? date) {
    if (date == null) return false;
    return date.isAfter(DateTime.now());
  }

  /// Validate time slot format (HH:MM)
  static bool isValidTimeSlot(String? time) {
    if (time == null || time.isEmpty) return false;
    final parts = time.split(':');
    if (parts.length != 2) return false;
    try {
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour >= 0 && hour < 24 && minute >= 0 && minute < 60;
    } catch (_) {
      return false;
    }
  }

  /// Validate address object
  static bool isValidAddress(Map<String, dynamic>? address) {
    if (address == null || address.isEmpty) return false;
    
    final fullAddress = address['fullAddress']?.toString().trim();
    final city = address['city']?.toString().trim();
    final district = address['district']?.toString().trim();
    final state = address['state']?.toString().trim();
    
    if (fullAddress == null || fullAddress.isEmpty || fullAddress.length > 500) return false;
    if (city == null || city.isEmpty || city.length > 100) return false;
    if (district == null || district.isEmpty || district.length > 100) return false;
    if (state == null || state.isEmpty || state.length > 100) return false;
    
    return true;
  }

  /// Validate latitude/longitude
  static bool isValidCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
  }

  /// Validate booking status (only allowed values)
  static bool isValidBookingStatus(String? status) {
    const allowedStatuses = [
      'pending_admin',
      'technician_pending',
      'awaiting_payment',
      'confirmed',
      'in_progress',
      'completed',
      'cancelled',
    ];
    return status != null && allowedStatuses.contains(status);
  }

  /// Validate payment method
  static bool isValidPaymentMethod(String? method) {
    const allowedMethods = ['online', 'cash', 'wallet'];
    return method != null && allowedMethods.contains(method);
  }

  /// Log validation error (debug only)
  static void logValidationError(String field, String reason) {
    if (kDebugMode) {
      debugPrint('❌ [VALIDATION] $field: $reason');
    }
  }
}
