import 'package:cloud_firestore/cloud_firestore.dart';

class UserSettings {
  final NotificationSettings notifications;
  final PrivacySettings privacy;
  final PreferenceSettings preferences;

  UserSettings({
    required this.notifications,
    required this.privacy,
    required this.preferences,
  });

  factory UserSettings.defaults() {
    return UserSettings(
      notifications: NotificationSettings.defaults(),
      privacy: PrivacySettings.defaults(),
      preferences: PreferenceSettings.defaults(),
    );
  }

  factory UserSettings.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) return UserSettings.defaults();
    
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return UserSettings(
      notifications: NotificationSettings.fromMap(data['notifications'] as Map<String, dynamic>? ?? {}),
      privacy: PrivacySettings.fromMap(data['privacy'] as Map<String, dynamic>? ?? {}),
      preferences: PreferenceSettings.fromMap(data['preferences'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notifications': notifications.toMap(),
      'privacy': privacy.toMap(),
      'preferences': preferences.toMap(),
    };
  }

  UserSettings copyWith({
    NotificationSettings? notifications,
    PrivacySettings? privacy,
    PreferenceSettings? preferences,
  }) {
    return UserSettings(
      notifications: notifications ?? this.notifications,
      privacy: privacy ?? this.privacy,
      preferences: preferences ?? this.preferences,
    );
  }
}

class NotificationSettings {
  final bool enabled;
  final bool bookingUpdates;
  final bool promotions;
  final bool payments;
  final bool technicianStatus;

  NotificationSettings({
    required this.enabled,
    required this.bookingUpdates,
    required this.promotions,
    required this.payments,
    required this.technicianStatus,
  });

  factory NotificationSettings.defaults() {
    return NotificationSettings(
      enabled: true,
      bookingUpdates: true,
      promotions: true,
      payments: true,
      technicianStatus: true,
    );
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      enabled: map['enabled'] ?? true,
      bookingUpdates: map['bookingUpdates'] ?? true,
      promotions: map['promotions'] ?? true,
      payments: map['payments'] ?? true,
      technicianStatus: map['technicianStatus'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'bookingUpdates': bookingUpdates,
      'promotions': promotions,
      'payments': payments,
      'technicianStatus': technicianStatus,
    };
  }

  NotificationSettings copyWith({
    bool? enabled,
    bool? bookingUpdates,
    bool? promotions,
    bool? payments,
    bool? technicianStatus,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      promotions: promotions ?? this.promotions,
      payments: payments ?? this.payments,
      technicianStatus: technicianStatus ?? this.technicianStatus,
    );
  }
}

class PrivacySettings {
  final bool appLock;

  PrivacySettings({
    required this.appLock,
  });

  factory PrivacySettings.defaults() {
    return PrivacySettings(appLock: false);
  }

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      appLock: map['appLock'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appLock': appLock,
    };
  }

  PrivacySettings copyWith({
    bool? appLock,
  }) {
    return PrivacySettings(
      appLock: appLock ?? this.appLock,
    );
  }
}

class PreferenceSettings {
  final String language;

  PreferenceSettings({
    required this.language,
  });

  factory PreferenceSettings.defaults() {
    return PreferenceSettings(language: 'en');
  }

  factory PreferenceSettings.fromMap(Map<String, dynamic> map) {
    return PreferenceSettings(
      language: map['language'] ?? 'en',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
    };
  }

  PreferenceSettings copyWith({
    String? language,
  }) {
    return PreferenceSettings(
      language: language ?? this.language,
    );
  }
}
