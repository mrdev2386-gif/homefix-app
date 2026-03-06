import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_settings.dart';

class UserSettingsService {
  UserSettingsService();

  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  Stream<UserSettings> streamUserSettings(String userId) {
    return firestore
        .collection('user_settings')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return UserSettings.defaults();
      }

      final data = doc.data();
      if (data == null) {
        return UserSettings.defaults();
      }

      return UserSettings(
        notifications: NotificationSettings.fromMap(data['notifications'] as Map<String, dynamic>? ?? {}),
        privacy: PrivacySettings.fromMap(data['privacy'] as Map<String, dynamic>? ?? {}),
        preferences: PreferenceSettings.fromMap(data['preferences'] as Map<String, dynamic>? ?? {}),
      );
    });
  }

  Future<UserSettings?> getUserSettings(String userId) async {
    final doc = await firestore
        .collection('user_settings')
        .doc(userId)
        .get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    return UserSettings(
      notifications: NotificationSettings.fromMap(data['notifications'] as Map<String, dynamic>? ?? {}),
      privacy: PrivacySettings.fromMap(data['privacy'] as Map<String, dynamic>? ?? {}),
      preferences: PreferenceSettings.fromMap(data['preferences'] as Map<String, dynamic>? ?? {}),
    );
  }

  Future<void> updateNotificationSettings(
    String userId,
    NotificationSettings settings,
  ) async {
    await firestore
        .collection('user_settings')
        .doc(userId)
        .set(
          {'notifications': settings.toMap()},
          SetOptions(merge: true),
        );
  }

  Future<void> updatePrivacySettings(
    String userId,
    PrivacySettings settings,
  ) async {
    await firestore
        .collection('user_settings')
        .doc(userId)
        .set(
          {'privacy': settings.toMap()},
          SetOptions(merge: true),
        );
  }

  Future<void> updatePreferenceSettings(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    await firestore
        .collection('user_settings')
        .doc(userId)
        .set(
          preferences,
          SetOptions(merge: true),
        );
  }
}
