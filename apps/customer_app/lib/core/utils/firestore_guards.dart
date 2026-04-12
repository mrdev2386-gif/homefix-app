import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firestore document path validation utilities
/// Prevents crashes from invalid document IDs
class FirestoreGuards {
  /// Validates if a document ID is safe to use
  static bool isValidDocumentId(String? id) {
    if (id == null || id.isEmpty) {
      if (kDebugMode) {
        debugPrint('[PATH_GUARD] Blocked empty/null document ID');
      }
      return false;
    }
    
    if (id.contains('/')) {
      if (kDebugMode) {
        debugPrint('[PATH_GUARD] Blocked invalid character "/" in ID: $id');
      }
      return false;
    }
    
    if (id.contains('__')) {
      if (kDebugMode) {
        debugPrint('[PATH_GUARD] Blocked invalid pattern "__" in ID: $id');
      }
      return false;
    }
    
    return true;
  }
  
  /// Safely creates a document reference, returns null if ID is invalid
  static DocumentReference? safeDoc(
    CollectionReference collection,
    String? id,
  ) {
    if (!isValidDocumentId(id)) {
      return null;
    }
    return collection.doc(id);
  }
  
  /// Safely creates a document reference with error callback
  static DocumentReference? safeDocWithCallback(
    CollectionReference collection,
    String? id,
    void Function(String error) onError,
  ) {
    if (!isValidDocumentId(id)) {
      onError('Invalid document ID: $id');
      return null;
    }
    return collection.doc(id);
  }
}
