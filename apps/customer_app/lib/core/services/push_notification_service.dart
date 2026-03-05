import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';

/// ================================================
/// PUSH NOTIFICATION SERVICE (FCM TOKEN MANAGEMENT)
/// ================================================
///
/// Handles:
/// - FCM token request & permission
/// - Token persistence to Firestore (users/{userId}/fcmTokens)
/// - Token auto-refresh
/// - Message handlers setup
/// - Background notification handling

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;
  String? _currentToken;
  final List<VoidCallback> _listeners = [];

  String? get currentToken => _currentToken;

  /// ================================================
  /// INITIALIZE - Main entry point
  /// ================================================
  /// Call this once during app startup (after Firebase.initializeApp())
  /// Typically in main.dart or app_init.dart

  Future<void> initialize({
    VoidCallback? onTokenRefresh,
  }) async {
    if (_isInitialized) {
      debugPrint('[PushNotificationService] Already initialized, skipping');
      return;
    }

    try {
      debugPrint('[PushNotificationService] Initializing...');

      // Step 1: Request notification permission
      await _requestNotificationPermission();

      // Step 2: Get initial token
      final token = await _messaging.getToken();
      if (token != null) {
        _currentToken = token;
        debugPrint('[PushNotificationService] Initial token obtained: ${token.substring(0, 20)}...');
      }

      // Step 3: Setup token refresh listener
      _setupTokenRefreshListener(onTokenRefresh);

      // Step 4: Setup message handlers (foreground, background, tap)
      _setupMessageHandlers();

      // Step 5: Save token on auth state change
      _setupAuthStateListener();

      _isInitialized = true;
      debugPrint('[PushNotificationService] ✅ Initialization complete');
    } catch (error) {
      debugPrint('[PushNotificationService] ❌ Initialization failed: $error');
    }
  }

  /// ================================================
  /// REQUEST NOTIFICATION PERMISSION
  /// ================================================
  /// iOS: Shows permission dialog
  /// Android: Automatic in Android 13+

  Future<void> _requestNotificationPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('[PushNotificationService] Notification permission: GRANTED');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('[PushNotificationService] Notification permission: PROVISIONAL');
      } else {
        debugPrint('[PushNotificationService] Notification permission: DENIED');
      }
    } catch (error) {
      debugPrint('[PushNotificationService] Permission request error: $error');
    }
  }

  /// ================================================
  /// SETUP TOKEN REFRESH LISTENER
  /// ================================================

  void _setupTokenRefreshListener(VoidCallback? onTokenRefresh) {
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[PushNotificationService] Token refreshed: ${newToken.substring(0, 20)}...');
      _currentToken = newToken;

      // Save new token to Firestore
      await _saveFcmTokenToFirestore(newToken);

      // Notify listeners
      if (onTokenRefresh != null) onTokenRefresh();
      _notifyListeners();
    });
  }

  /// ================================================
  /// SETUP AUTH STATE LISTENER
  /// ================================================

  void _setupAuthStateListener() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        debugPrint('[PushNotificationService] User logged in: ${user.uid}');
        // Save token on login
        if (_currentToken != null) {
          await _saveFcmTokenToFirestore(_currentToken!);
        } else {
          // If no token, fetch it
          final token = await _messaging.getToken();
          if (token != null) {
            _currentToken = token;
            await _saveFcmTokenToFirestore(token);
          }
        }
      } else {
        debugPrint('[PushNotificationService] User logged out');
        // Optionally remove token on logout
        // await _removeTokenOnLogout();
      }
    });
  }

  /// ================================================
  /// SAVE FCM TOKEN TO FIRESTORE
  /// ================================================
  /// Path: users/{userId}/fcmTokens/{tokenId}
  /// Enables push notifications from Cloud Functions

  Future<void> _saveFcmTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[PushNotificationService] ⚠️ Cannot save token - user not logged in');
      return;
    }

    try {
      final userId = user.uid;
      final tokenId = _generateTokenId(token);
      final now = FieldValue.serverTimestamp();

      // Save token to Firestore with metadata
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(tokenId)
          .set({
        'token': token,
        'platform': defaultTargetPlatform.toString().split('.').last, // 'android' or 'ios'
        'createdAt': now,
        'updatedAt': now,
        'isActive': true,
      }, SetOptions(merge: true));

      // Also save to legacy location for backward compatibility
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': now,
      });

      debugPrint('[PushNotificationService] ✅ Token saved to Firestore');
    } catch (error) {
      debugPrint('[PushNotificationService] ❌ Failed to save token: $error');
      // Don't throw - token will be saved on next refresh
    }
  }

  /// ================================================
  /// SETUP MESSAGE HANDLERS
  /// ================================================
  /// Handles notifications in 3 scenarios:
  /// 1. Foreground (onMessage)
  /// 2. Background (onBackgroundMessage) - already set in main.dart
  /// 3. Notification tap (onMessageOpenedApp)

  void _setupMessageHandlers() {
    // 1. FOREGROUND MESSAGES
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[PushNotificationService] Foreground message received');
      debugPrint('  Title: ${message.notification?.title}');
      debugPrint('  Body: ${message.notification?.body}');
      // The NotificationsService will handle displaying in-app UI
    });

    // 2. NOTIFICATION TAP (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[PushNotificationService] Notification tapped');
      debugPrint('  Data: ${message.data}');
      // The NotificationsService will handle deep linking
    });
  }

  /// ================================================
  /// OPTIONAL: REMOVE TOKEN ON LOGOUT
  /// ================================================

  Future<void> removeTokenOnLogout() async {
    final user = _auth.currentUser;
    if (user == null || _currentToken == null) return;

    try {
      final userId = user.uid;
      final tokenId = _generateTokenId(_currentToken!);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(tokenId)
          .delete();

      debugPrint('[PushNotificationService] Token removed on logout');
    } catch (error) {
      debugPrint('[PushNotificationService] Failed to remove token: $error');
    }
  }

  /// ================================================
  /// MANUAL TOKEN REFRESH
  /// ================================================
  /// Call if needed to force a token refresh

  Future<String?> refreshToken() async {
    try {
      await _messaging.deleteToken();
      final newToken = await _messaging.getToken();
      if (newToken != null) {
        _currentToken = newToken;
        await _saveFcmTokenToFirestore(newToken);
        return newToken;
      }
    } catch (error) {
      debugPrint('[PushNotificationService] Token refresh failed: $error');
    }
    return null;
  }

  /// ================================================
  /// HELPER: LISTENER MANAGEMENT
  /// ================================================

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// ================================================
  /// HELPER: GENERATE TOKEN ID
  /// ================================================
  /// Creates a stable ID from token for Firestore doc naming

  String _generateTokenId(String token) {
    // Use first 12 chars of token as ID
    return token.substring(0, 12);
  }

  /// ================================================
  /// STATE GETTERS
  /// ================================================

  bool get isInitialized => _isInitialized;

  /// ================================================
  /// DISPOSE
  /// ================================================

  void dispose() {
    _listeners.clear();
  }
}
