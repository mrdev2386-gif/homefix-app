import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'functions_service.dart';

/// Shared service for managing user location (state + district) with caching
/// Used by FirestoreService and CategoryService to avoid duplicate logic
class UserLocationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Location caching to prevent repeated Firestore reads
  Map<String, String>? _cachedLocation;
  bool _locationFetched = false;

  UserLocationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get user's location with caching to prevent repeated Firestore reads
  Future<Map<String, String>?> getUserLocationCached() async {
    if (_locationFetched) {
      return _cachedLocation;
    }

    _cachedLocation = await _getUserLocation();
    _locationFetched = true;

    return _cachedLocation;
  }

  /// Clear location cache (call when user updates address)
  void clearLocationCache() {
    _cachedLocation = null;
    _locationFetched = false;
  }

  /// Get user's location from their primary address with safe fallback handling
  /// Returns normalized state and district (lowercase, trimmed)
  Future<Map<String, String>?> _getUserLocation() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) debugPrint('⚠️ [UserLocationService] No authenticated user');
        return null;
      }

      // Get user document
      final userDoc = await _firestore.collection('customers').doc(user.uid).get();
      if (!userDoc.exists) {
        if (kDebugMode) debugPrint('⚠️ [UserLocationService] User document not found');
        return null;
      }

      final data = userDoc.data();
      final state = data?['state'];
      final district = data?['district'];

      if (state == null || district == null || state.isEmpty || district.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ [UserLocationService] Incomplete location data: state=$state, district=$district');
        }
        return null;
      }

      if (kDebugMode) debugPrint('✅ [UserLocationService] User location: $state/$district');

      return {
        'state': normalizeLocation(state),
        'district': normalizeLocation(district),
      };
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [UserLocationService] Error getting user location: $e');
      return null;
    }
  }

  /// Normalize location string (trim and lowercase)
  String normalizeLocation(String value) {
    return value.trim().toLowerCase();
  }

  /// Get user's location (alias for getUserLocationCached for backward compatibility)
  Future<Map<String, String>?> getLocation() async {
    return await getUserLocationCached();
  }

  /// Save user's location via Cloud Function
  Future<void> saveLocation(String state, String district) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) debugPrint('⚠️ [UserLocationService] No authenticated user for saveLocation');
        throw Exception('User not authenticated');
      }

      await FunctionsService().updateUserProfile({
        'state': state,
        'district': district,
      });

      // Clear cache to force refresh
      clearLocationCache();

      if (kDebugMode) debugPrint('✅ [UserLocationService] Location saved: $state/$district');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [UserLocationService] Error saving location: $e');
      rethrow;
    }
  }
}

