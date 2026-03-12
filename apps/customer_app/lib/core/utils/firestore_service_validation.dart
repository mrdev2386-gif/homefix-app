import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firestore service data validation result
class ServiceValidationResult {
  final bool isValid;
  final List<String> missingFields;
  final List<String> warnings;

  ServiceValidationResult({
    required this.isValid,
    required this.missingFields,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasMissingFields => missingFields.isNotEmpty;
}

/// Firestore service document validation and safety utilities
/// Ensures service documents have required fields before processing
class FirestoreServiceValidation {
  /// Validation result structure is defined above


  /// ============================================================================
  /// REQUIRED FIELDS VALIDATION
  /// ============================================================================

  /// Validate that service document has all required fields
  static ServiceValidationResult validateServiceDocument(
    DocumentSnapshot doc, {
    bool logWarnings = true,
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final List<String> missingFields = [];
    final List<String> warnings = [];

    // Validate name/title - at least ONE must exist
    final hasName = (data['name']?.toString() ?? '').trim().isNotEmpty;
    final hasTitle = (data['title']?.toString() ?? '').trim().isNotEmpty;
    if (!hasName && !hasTitle) {
      missingFields.add('name (or title)');
    }

    // Validate price - at least ONE price field must exist and be > 0
    final price = _extractNumericValue(data['price'] ?? data['basePrice']);
    if (price == null || price <= 0) {
      missingFields.add('price (must be > 0)');
    }

    // Check categoryId
    final hasCategoryId = (data['categoryId']?.toString() ?? '').trim().isNotEmpty;
    final hasCategory = (data['category']?.toString() ?? '').trim().isNotEmpty;
    if (!hasCategoryId && !hasCategory) {
      warnings.add('categoryId missing - will infer from path or use empty string');
    }

    // Check image
    final hasImage = (data['imageUrl']?.toString() ?? '').trim().isNotEmpty ||
        (data['image']?.toString() ?? '').trim().isNotEmpty;
    if (!hasImage) {
      warnings.add('image missing - using global fallback placeholder');
    }

    final isValid = missingFields.isEmpty;

    // Log results only in debug mode and only for validation failures
    if (logWarnings && kDebugMode && !isValid) {
      debugPrint('📋 [Service Validation] ${doc.id}:');
      if (missingFields.isNotEmpty) {
        debugPrint('   ❌ Missing REQUIRED: ${missingFields.join(", ")}');
      }
      if (warnings.isNotEmpty) {
        for (final warning in warnings) {
          debugPrint('   ⚠️ $warning');
        }
      }
    }

    return ServiceValidationResult(
      isValid: isValid,
      missingFields: missingFields,
      warnings: warnings,
    );
  }

  /// ============================================================================
  /// SAFE DATA EXTRACTION METHODS
  /// ============================================================================

  /// Safely extract string value with fallbacks
  static String safeString(
    Map<String, dynamic> data, {
    required List<String> fieldNames,
    required String defaultValue,
    String? fieldDescription,
  }) {
    for (final fieldName in fieldNames) {
      final value = data[fieldName]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return defaultValue;
  }

  /// Safely extract numeric value
  static double? safeNumeric(
    Map<String, dynamic> data, {
    required List<String> fieldNames,
    String? fieldDescription,
  }) {
    for (final fieldName in fieldNames) {
      final value = _extractNumericValue(data[fieldName]);
      if (value != null && value > 0) {
        return value;
      }
    }

    return null;
  }

  /// Safely extract integer value with default
  static int safeInteger(
    Map<String, dynamic> data, {
    required List<String> fieldNames,
    required int defaultValue,
    String? fieldDescription,
  }) {
    for (final fieldName in fieldNames) {
      final value = data[fieldName];
      if (value is num) {
        return value.toInt();
      } else if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return defaultValue;
  }

  /// Safely extract boolean value with default
  static bool safeBool(
    Map<String, dynamic> data,
    String fieldName, {
    bool defaultValue = false,
  }) {
    final value = data[fieldName];
    if (value is bool) {
      return value;
    } else if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    } else if (value is num) {
      return value != 0;
    }
    return defaultValue;
  }

  /// Safely extract timestamp with default
  static DateTime safeTimestamp(
    Map<String, dynamic> data,
    String fieldName,
  ) {
    if (data[fieldName] is Timestamp) {
      return (data[fieldName] as Timestamp).toDate();
    }
    return DateTime.now();
  }

  /// ============================================================================
  /// INTEGRITY CHECKING
  /// ============================================================================

  /// Check if service document is safe to render
  static bool isSafeToRender(Map<String, dynamic> data) {
    // Must have display name
    final hasName = (data['name']?.toString() ?? '').trim().isNotEmpty ||
        (data['title']?.toString() ?? '').trim().isNotEmpty;

    // Must have price
    final price = _extractNumericValue(data['price'] ?? data['basePrice']);
    final hasPrice = price != null && price > 0;

    return hasName && hasPrice;
  }

  /// Get incomplete document report
  static String getIncompleteDocumentReport(
    DocumentSnapshot doc, {
    ServiceValidationResult? validation,
  }) {
    validation ??= validateServiceDocument(doc, logWarnings: false);

    final buffer = StringBuffer();
    buffer.writeln('📋 Incomplete Service Document: ${doc.id}');
    buffer.writeln('Path: ${doc.reference.path}');

    if (validation.missingFields.isNotEmpty) {
      buffer.writeln('  ❌ Missing Required:');
      for (final field in validation.missingFields) {
        buffer.writeln('     - $field');
      }
    }

    if (validation.warnings.isNotEmpty) {
      buffer.writeln('  ⚠️ Warnings:');
      for (final warning in validation.warnings) {
        buffer.writeln('     - $warning');
      }
    }

    return buffer.toString();
  }

  /// ============================================================================
  /// PRIVATE HELPERS
  /// ============================================================================

  /// Extract numeric value from any type
  static double? _extractNumericValue(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      final num = value.toDouble();
      return num.isFinite ? num : null;
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
}
