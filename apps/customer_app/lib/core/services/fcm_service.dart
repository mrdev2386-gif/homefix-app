import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Background message handler - MUST be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM BACKGROUND] ${message.notification?.title}');
  debugPrint('[FCM BACKGROUND] Data: ${message.data}');
}

/// DEPRECATED: FCM token management moved to NotificationsService
/// This service only handles message handlers now
/// TODO: Remove this service and use NotificationsService directly
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize FCM and request permissions
  /// NOTE: Token management is handled by NotificationsService
  Future<void> initialize() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Setup message handlers only - token saving handled by NotificationsService
        _setupMessageHandlers();
      } else {
        debugPrint('[FCM] Permission denied');
      }
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }

  /// Message display is handled by NotificationsService.
  /// FCMService only manages permissions.
  void _setupMessageHandlers() {
    debugPrint('[FCM] Message handlers delegated to NotificationsService');
  }

  void dispose() {}
}
