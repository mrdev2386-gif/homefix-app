import 'package:flutter/foundation.dart';

/// Safe parsing utilities for Firestore data
/// Prevents NaN, Infinity, and type conversion errors
class SafeParsing {
  /// Safely parse an integer from dynamic Firestore data
  static int safeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    
    if (value is int) return value;
    
    if (value is num && value.isFinite) {
      return value.toInt();
    }
    
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    
    if (kDebugMode) {
      debugPrint('[SAFE_PARSE] Invalid int value: $value (type: ${value.runtimeType})');
    }
    return defaultValue;
  }
  
  /// Safely parse a double from dynamic Firestore data
  static double safeDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    
    if (value is double && value.isFinite) return value;
    
    if (value is num && value.isFinite) {
      return value.toDouble();
    }
    
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && parsed.isFinite) return parsed;
    }
    
    if (kDebugMode) {
      debugPrint('[SAFE_PARSE] Invalid double value: $value (type: ${value.runtimeType})');
    }
    return defaultValue;
  }
  
  /// Safely parse a string from dynamic Firestore data
  static String safeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    
    if (value is String) return value;
    
    return value.toString();
  }
  
  /// Safely parse a boolean from dynamic Firestore data
  static bool safeBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    
    if (value is bool) return value;
    
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    
    if (value is num) {
      return value != 0;
    }
    
    if (kDebugMode) {
      debugPrint('[SAFE_PARSE] Invalid bool value: $value (type: ${value.runtimeType})');
    }
    return defaultValue;
  }
  
  /// Safely parse a list from dynamic Firestore data
  static List<T> safeList<T>(dynamic value, {List<T> defaultValue = const []}) {
    if (value == null) return defaultValue;
    
    if (value is List) {
      try {
        return value.cast<T>();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SAFE_PARSE] Failed to cast list: $e');
        }
        return defaultValue;
      }
    }
    
    if (kDebugMode) {
      debugPrint('[SAFE_PARSE] Invalid list value: $value (type: ${value.runtimeType})');
    }
    return defaultValue;
  }
  
  /// Safely parse a map from dynamic Firestore data
  static Map<String, dynamic> safeMap(dynamic value, {Map<String, dynamic> defaultValue = const {}}) {
    if (value == null) return defaultValue;
    
    if (value is Map<String, dynamic>) return value;
    
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SAFE_PARSE] Failed to convert map: $e');
        }
        return defaultValue;
      }
    }
    
    if (kDebugMode) {
      debugPrint('[SAFE_PARSE] Invalid map value: $value (type: ${value.runtimeType})');
    }
    return defaultValue;
  }
  
  /// Safely parse a DateTime from dynamic Firestore data
  static DateTime? safeDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is DateTime) return value;
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SAFE_PARSE] Failed to parse DateTime: $value');
        }
        return null;
      }
    }
    
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SAFE_PARSE] Failed to parse DateTime from timestamp: $value');
        }
        return null;
      }
    }
    
    if (kDebugMode) {
      debugPrint('[SAFE_PARSE] Invalid DateTime value: $value (type: ${value.runtimeType})');
    }
    return null;
  }
  
  /// Validate that a numeric value is finite (not NaN or Infinity)
  static bool isFiniteNumber(dynamic value) {
    if (value is num) {
      return value.isFinite;
    }
    return false;
  }
}
