import 'package:cloud_firestore/cloud_firestore.dart';
import 'logger.dart';

/// Service document data integrity guard
/// 
/// Ensures service documents have all required fields before rendering
/// Prevents crashes from incomplete or malformed Firestore data
/// Provides detailed validation reports for debugging
class ServiceDataIntegrityGuard {
  /// Validate a service document before rendering
  /// 
  /// Returns true if document is safe to render
  /// Logs warnings for incomplete documents
  static bool validateBeforeRender(
    DocumentSnapshot doc, {
    bool throwOnInvalid = false,
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final docId = doc.id;

    // Check required fields
    final hasName = _hasValidString(data['name'] ?? data['title']);
    final hasPrice = _hasValidPrice(data['price'] ?? data['basePrice']);
    final hasCategoryId = _hasValidString(data['categoryId'] ?? data['category']);
    final hasImage = _hasValidString(data['imageUrl'] ?? data['image']);

    // Determine validity
    final isValid = hasName && hasPrice;

    // Log warnings for missing optional fields
    if (!hasCategoryId) {
      AppLogger.warning('ServiceValidation', 'Service $docId missing categoryId - will infer from path');
    }

    if (!hasImage) {
      AppLogger.debug('ServiceValidation', 'Service $docId missing image - using fallback placeholder');
    }

    // Log critical issues
    if (!hasName) {
      AppLogger.error('ServiceValidation', 'Service $docId missing required field: name/title');
    }

    if (!hasPrice) {
      AppLogger.error('ServiceValidation', 'Service $docId missing required field: price (must be > 0)');
    }

    if (throwOnInvalid && !isValid) {
      throw Exception('Service document $docId is incomplete: missing required fields');
    }

    return isValid;
  }

  /// Get a detailed validation report for a service document
  static String getValidationReport(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final docId = doc.id;
    final buffer = StringBuffer();

    buffer.writeln('📋 Service Document Validation Report');
    buffer.writeln('Document ID: $docId');
    buffer.writeln('Path: ${doc.reference.path}');
    buffer.writeln('');

    // Check each required field
    buffer.writeln('Required Fields:');
    buffer.writeln('  • name/title: ${_hasValidString(data['name'] ?? data['title']) ? '✅' : '❌'}');
    buffer.writeln('  • price: ${_hasValidPrice(data['price'] ?? data['basePrice']) ? '✅' : '❌'}');

    buffer.writeln('');
    buffer.writeln('Optional Fields:');
    buffer.writeln('  • categoryId: ${_hasValidString(data['categoryId'] ?? data['category']) ? '✅' : '⚠️ (will infer)'}');
    buffer.writeln('  • image: ${_hasValidString(data['imageUrl'] ?? data['image']) ? '✅' : '⚠️ (using fallback)'}');

    buffer.writeln('');
    buffer.writeln('Additional Fields:');
    buffer.writeln('  • description: ${_hasValidString(data['description']) ? '✅' : '⚠️'}');
    buffer.writeln('  • status: ${data['status'] ?? 'N/A'}');
    buffer.writeln('  • isActive: ${data['isActive'] ?? 'N/A'}');

    return buffer.toString();
  }

  /// Validate multiple service documents and return statistics
  static Map<String, dynamic> validateBatch(List<DocumentSnapshot> docs) {
    int totalDocs = docs.length;
    int validDocs = 0;
    int missingName = 0;
    int missingPrice = 0;
    int missingCategory = 0;
    int missingImage = 0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};

      if (validateBeforeRender(doc)) {
        validDocs++;
      }

      if (!_hasValidString(data['name'] ?? data['title'])) missingName++;
      if (!_hasValidPrice(data['price'] ?? data['basePrice'])) missingPrice++;
      if (!_hasValidString(data['categoryId'] ?? data['category'])) missingCategory++;
      if (!_hasValidString(data['imageUrl'] ?? data['image'])) missingImage++;
    }

    return {
      'total': totalDocs,
      'valid': validDocs,
      'validPercentage': totalDocs > 0 ? (validDocs / totalDocs * 100).toStringAsFixed(1) : '0',
      'missingName': missingName,
      'missingPrice': missingPrice,
      'missingCategory': missingCategory,
      'missingImage': missingImage,
    };
  }

  /// ============================================================================
  /// PRIVATE HELPERS
  /// ============================================================================

  /// Check if value is a valid non-empty string
  static bool _hasValidString(dynamic value) {
    if (value == null) return false;
    final str = value.toString().trim();
    return str.isNotEmpty;
  }

  /// Check if value is a valid price (number > 0)
  static bool _hasValidPrice(dynamic value) {
    if (value == null) return false;

    if (value is num) {
      return value > 0 && value.isFinite;
    }

    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed != null && parsed > 0;
    }

    return false;
  }
}

/// Safe service document wrapper
/// 
/// Wraps a Firestore document and provides safe access to fields
/// with automatic fallbacks for missing data
class SafeServiceDocument {
  final DocumentSnapshot _doc;
  final Map<String, dynamic> _data;

  SafeServiceDocument(this._doc) : _data = _doc.data() as Map<String, dynamic>? ?? {};

  /// Get document ID
  String get id => _doc.id;

  /// Get document path
  String get path => _doc.reference.path;

  /// Get name with fallback
  String get name {
    final value = _data['name'] ?? _data['title'] ?? 'Unknown Service';
    return value.toString().trim();
  }

  /// Get price with fallback
  double get price {
    final value = _data['price'] ?? _data['basePrice'];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Get category ID with fallback
  String get categoryId {
    final value = _data['categoryId'] ?? _data['category'] ?? '';
    return value.toString().trim();
  }

  /// Get image URL with fallback
  String get imageUrl {
    final value = _data['imageUrl'] ?? _data['image'] ?? '';
    final url = value.toString().trim();
    
    // Validate URL format
    if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('assets/')) {
      return url;
    }
    
    // Return fallback if invalid
    return 'https://firebasestorage.googleapis.com/v0/b/homefix-860e3.appspot.com/o/placeholders%2Fservice_placeholder.png?alt=media';
  }

  /// Get description with fallback
  String get description {
    final value = _data['description'] ?? '';
    return value.toString().trim();
  }

  /// Get status
  String get status {
    return (_data['status'] ?? 'unknown').toString();
  }

  /// Check if document is valid for rendering
  bool get isValid => ServiceDataIntegrityGuard.validateBeforeRender(_doc);

  /// Get validation report
  String get validationReport => ServiceDataIntegrityGuard.getValidationReport(_doc);

  /// Get raw data
  Map<String, dynamic> get data => _data;
}
