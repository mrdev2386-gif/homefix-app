import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_settings.dart';

class UserSettingsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream user settings
  Stream<UserSettings> streamUserSettings(String userId) {
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in streamUserSettings');
      return Stream.value(UserSettings.defaults());
    }
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
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in getUserSettings');
      return UserSettings.defaults();
    }
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
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in updateNotificationSettings');
      return;
    }
    debugPrint('[WRITE GUARD] Direct write blocked in updateNotificationSettings');
    await updateAllSettings(userId, UserSettings(
      notifications: settings,
      privacy: PrivacySettings.defaults(),
      preferences: PreferenceSettings.defaults(),
    ));
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(
    String userId,
    PrivacySettings settings,
  ) async {
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in updatePrivacySettings');
      return;
    }
    debugPrint('[WRITE GUARD] Direct write blocked in updatePrivacySettings');
    await updateAllSettings(userId, UserSettings(
      notifications: NotificationSettings.defaults(),
      privacy: settings,
      preferences: PreferenceSettings.defaults(),
    ));
  }

  /// Update preference settings
  Future<void> updatePreferenceSettings(
    String userId,
    PreferenceSettings settings,
  ) async {
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in updatePreferenceSettings');
      return;
    }
    debugPrint('[WRITE GUARD] Direct write blocked in updatePreferenceSettings');
    await updateAllSettings(userId, UserSettings(
      notifications: NotificationSettings.defaults(),
      privacy: PrivacySettings.defaults(),
      preferences: settings,
    ));
  }

  /// Update all settings at once
  Future<void> updateAllSettings(
    String userId,
    UserSettings settings,
  ) async {
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in updateAllSettings');
      return;
    }
    debugPrint('[WRITE GUARD] Direct write blocked in updateAllSettings');
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('updateUserSettingsCallable');
      await callable.call(settings.toMap());
      debugPrint('✅ [Settings] Updated via callable');
    } catch (e) {
      debugPrint('❌ [Settings] Update failed: $e');
      rethrow;
    }
  }

  /// Initialize default settings for new user
  Future<void> initializeDefaultSettings(String userId) async {
    if (userId.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in initializeDefaultSettings');
      return;
    }
    debugPrint('[WRITE GUARD] Direct write blocked in initializeDefaultSettings');
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('initializeUserSettingsCallable');
      await callable.call();
      debugPrint('✅ [Settings] Initialized via callable');
    } catch (e) {
      debugPrint('❌ [Settings] Initialization failed: $e');
    }
  }
}
