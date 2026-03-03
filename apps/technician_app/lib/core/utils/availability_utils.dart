/// Technician Availability Utility Functions
/// 
/// Handles availability checking for customer-side technician filtering
/// Based on working hours and emergency service settings

class AvailabilityUtils {
  /// Check if technician is available at the selected booking time
  /// 
  /// Returns true if:
  /// 1. Selected time is within working hours, OR
  /// 2. Emergency service is enabled
  /// 
  /// Returns false if:
  /// - No availability data (backward compatibility - treat as available)
  /// - Invalid time data
  /// - Start time equals end time
  static bool isTechnicianAvailable({
    required Map<String, dynamic>? availabilityData,
    required DateTime selectedBookingTime,
  }) {
    // Backward compatibility - if no availability data, treat as available
    if (availabilityData == null) return true;
    
    try {
      final startTimeStr = availabilityData['startTime'] as String?;
      final endTimeStr = availabilityData['endTime'] as String?;
      final isEmergencyOn = availabilityData['isEmergencyOn'] as bool? ?? false;
      
      // If emergency service is on, always available
      if (isEmergencyOn) return true;
      
      // If no working hours set, treat as available (backward compatibility)
      if (startTimeStr == null || endTimeStr == null) return true;
      
      // Parse working hours
      final startMinutes = _timeStringToMinutes(startTimeStr);
      final endMinutes = _timeStringToMinutes(endTimeStr);
      
      // Invalid time data - fail safe to available
      if (startMinutes == null || endMinutes == null) return true;
      
      // Start equals end - treat as unavailable
      if (startMinutes == endMinutes) return false;
      
      // Get selected time in minutes from midnight
      final selectedMinutes = selectedBookingTime.hour * 60 + selectedBookingTime.minute;
      
      // Check if selected time is within working hours
      return selectedMinutes >= startMinutes && selectedMinutes <= endMinutes;
      
    } catch (e) {
      // On any error, fail safe to available
      return true;
    }
  }
  
  /// Convert time string (HH:mm) to minutes from midnight
  /// Returns null if invalid format
  static int? _timeStringToMinutes(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;
      
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      
      return hour * 60 + minute;
    } catch (e) {
      return null;
    }
  }
  
  /// Format availability for display
  static String formatAvailability(Map<String, dynamic>? availabilityData) {
    if (availabilityData == null) return 'Available';
    
    final isEmergencyOn = availabilityData['isEmergencyOn'] as bool? ?? false;
    if (isEmergencyOn) return '⚡ Emergency Available';
    
    final startTimeStr = availabilityData['startTime'] as String?;
    final endTimeStr = availabilityData['endTime'] as String?;
    
    if (startTimeStr != null && endTimeStr != null) {
      return '$startTimeStr - $endTimeStr';
    }
    
    return 'Available';
  }
  
  /// Check if technician has emergency service enabled
  static bool hasEmergencyService(Map<String, dynamic>? availabilityData) {
    if (availabilityData == null) return false;
    return availabilityData['isEmergencyOn'] as bool? ?? false;
  }
}