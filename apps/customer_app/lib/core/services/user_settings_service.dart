import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_settings.dart';

class UserSettingsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream user settings
  Stream<UserSettings> streamUserSettings(String userId) {
    return _db
        .collection('customers')
        .doc(userId)
        .collection('settings')
        .doc('preferences')
        .snapshots()
        .map((doc) => UserSettings.fromFirestore(doc));
  }

  /// Get user settings once
  Future<UserSettings> getUserSettings(String userId) async {
    try {
      final doc = await _db
          .collection('customers')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .get();
      
      return UserSettings.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting user settings: $e');
      return UserSettings.defaults();
    }
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(
    String userId,
    NotificationSettings settings,
  ) async {
    try {
      await _db
          .collection('customers')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .set({
        'notifications': settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
      rethrow;
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(
    String userId,
    PrivacySettings settings,
  ) async {
    try {
      await _db
          .collection('customers')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .set({
        'privacy': settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating privacy settings: $e');
      rethrow;
    }
  }

  /// Update preference settings
  Future<void> updatePreferenceSettings(
    String userId,
    PreferenceSettings settings,
  ) async {
    try {
      await _db
          .collection('customers')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .set({
        'preferences': settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating preference settings: $e');
      rethrow;
    }
  }

  /// Update all settings at once
  Future<void> updateAllSettings(
    String userId,
    UserSettings settings,
  ) async {
    try {
      await _db
          .collection('customers')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .set({
        ...settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating all settings: $e');
      rethrow;
    }
  }

  /// Initialize default settings for new user
  Future<void> initializeDefaultSettings(String userId) async {
    try {
      final doc = await _db
          .collection('customers')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .get();

      if (!doc.exists) {
        await _db
            .collection('customers')
            .doc(userId)
            .collection('settings')
            .doc('preferences')
            .set({
          ...UserSettings.defaults().toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error initializing default settings: $e');
    }
  }
}
