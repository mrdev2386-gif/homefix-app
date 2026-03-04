import 'package:cloud_firestore/cloud_firestore.dart';

/// Safe Firestore Parser Utility
/// 
/// Provides type-safe conversion methods for Firestore data
/// to prevent runtime crashes from type mismatches.
class FirestoreSafeParser {
  /// Safely convert any value to double
  static double toSafeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Safely convert any value to int
  static int toSafeInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Safely convert Timestamp to DateTime
  static DateTime toSafeDateTime(dynamic value, {DateTime? fallback}) {
    if (value == null) return fallback ?? DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return fallback ?? DateTime.now();
  }

  /// Safely convert to String
  static String toSafeString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  /// Safely convert to bool
  static bool toSafeBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return fallback;
  }

  /// Safely convert Firestore document data to Map
  static Map<String, dynamic> toSafeMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  /// Safely get nested map value
  static Map<String, dynamic> getSafeNestedMap(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    return toSafeMap(value);
  }
}
