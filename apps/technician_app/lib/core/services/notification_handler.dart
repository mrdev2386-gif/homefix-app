import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

// ==========================================
// TECHNICIAN NOTIFICATION CHANNELS
// ==========================================

class TechnicianNotificationChannels {
  static const String jobAlerts = 'job_alerts';
  static const String generalNotifications = 'general_notifications';
}

// ==========================================
// TECHNICIAN TYPE MAPPER
// ==========================================

class TechnicianNotificationTypeMapper {
  static String getChannelId(String type) {
    switch (type) {
      case 'new_request_nearby':
      case 'new_instant_booking':
      case 'booking_cancelled':
        return TechnicianNotificationChannels.jobAlerts;
      
      case 'payout_processed':
      case 'new_review':
      default:
        return TechnicianNotificationChannels.generalNotifications;
    }
  }

  static bool isHighPriority(String type) {
    switch (type) {
      case 'new_request_nearby':
      case 'new_instant_booking':
      case 'booking_cancelled':
        return true;
      default:
        return false;
    }
  }
}

// ==========================================
// TECHNICIAN NOTIFICATION HANDLER
// ==========================================

class TechnicianNotificationHandler {
  static final TechnicianNotificationHandler _instance = TechnicianNotificationHandler._();
  factory TechnicianNotificationHandler() => _instance;
  TechnicianNotificationHandler._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();
  
  // Streams
  final StreamController<RemoteMessage> _foregroundMessageController = 
      StreamController<RemoteMessage>.broadcast();
  final StreamController<int> _badgeCountController = 
      StreamController<int>.broadcast();
  
  Stream<RemoteMessage> get foregroundMessageStream => _foregroundMessageController.stream;
  Stream<int> get badgeCountStream => _badgeCountController.stream;

  // ========================================
  // INITIALIZATION
  // ========================================

  Future<void> initialize() async {
    await _createNotificationChannels();
    await _requestPermissions();
    await _setupMessageHandlers();
    await _setupTokenRefreshHandler();
    await _setupBadgeStream();
  }

  // ========================================
  // ANDROID NOTIFICATION CHANNELS
  // ========================================

  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    // Job Alerts Channel - High Priority for technicians
    const jobAlertsChannel = AndroidNotificationChannel(
      TechnicianNotificationChannels.jobAlerts,
      'Job Alerts',
      description: 'New job requests, instant bookings, and cancellations.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // General Notifications Channel
    const generalChannel = AndroidNotificationChannel(
      TechnicianNotificationChannels.generalNotifications,
      'General Notifications',
      description: 'Payout updates, reviews, and other updates.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(jobAlertsChannel);
        
    await _localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);

    debugPrint('[TechNotificationHandler] Android channels created');
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('[TechNotificationHandler] Permission status: ${settings.authorizationStatus}');
  }

  // ========================================
  // MESSAGE HANDLERS
  // ========================================

  Future<void> _setupMessageHandlers() async {
    // Foreground handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background tap handler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Terminated state handler
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[TechNotificationHandler] Foreground: ${message.notification?.title}');

    // Emit to stream
    _foregroundMessageController.add(message);

    // Show local notification
    await _showLocalNotification(message);

    // Save to Firestore
    await _saveNotificationToFirestore(message);
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('[TechNotificationHandler] Opened: ${message.data}');
    _foregroundMessageController.add(message);
    await _navigateFromNotification(message);
  }

  // ========================================
  // TOKEN REFRESH WITH RETRY
  // ========================================

  Future<void> _setupTokenRefreshHandler() async {
    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('[TechNotificationHandler] Token refreshed');
      
      // Retry logic for token save
      await _saveTokenWithRetry(token, maxRetries: 3);
    });
  }

  Future<void> _saveTokenWithRetry(String token, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        await _saveTokenToFirestore(token);
        return;
      } catch (e) {
        attempts++;
        debugPrint('[TechNotificationHandler] Token save attempt $attempts failed: $e');
        if (attempts < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempts));
        }
      }
    }
    debugPrint('[TechNotificationHandler] Token save failed after $maxRetries attempts');
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('saveFcmToken');
      
      await callable.call({
        'token': token,
        'platform': _getPlatform(),
        'userType': 'technician',
      });
      
      debugPrint('[TechNotificationHandler] Token saved');
    } catch (e) {
      debugPrint('[TechNotificationHandler] Cloud Function failed: $e');
      
      // Fallback
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc('${token.hashCode}_${DateTime.now().millisecondsSinceEpoch}')
          .set({
        'token': token,
        'platform': _getPlatform(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'invalidCount': 0,
      });
    }
  }

  // ========================================
  // BADGE COUNT
  // ========================================

  Future<void> _setupBadgeStream() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      _badgeCountController.add(snapshot.docs.length);
    });
  }

  // ========================================
  // LOCAL NOTIFICATIONS
  // ========================================

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final android = message.notification?.android;
    final type = message.data['type'] ?? 'general';
    final channelId = TechnicianNotificationTypeMapper.getChannelId(type);
    final isHighPriority = TechnicianNotificationTypeMapper.isHighPriority(type);

    final notificationId = message.hashCode;
    
    await _localNotif.show(
      notificationId,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _getChannelName(type),
          channelDescription: _getChannelDescription(type),
          icon: '@mipmap/ic_launcher',
          importance: isHighPriority ? Importance.high : Importance.defaultImportance,
          priority: isHighPriority ? Priority.high : Priority.defaultPriority,
          playSound: true,
          enableVibration: isHighPriority,
          showWhen: true,
          when: DateTime.now().millisecondsSinceEpoch,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  String _getChannelName(String type) {
    switch (type) {
      case 'new_request_nearby':
      case 'new_instant_booking':
        return 'New Jobs';
      case 'booking_cancelled':
        return 'Job Cancellations';
      case 'payout_processed':
        return 'Payouts';
      case 'new_review':
        return 'Reviews';
      default:
        return 'General Notifications';
    }
  }

  String _getChannelDescription(String type) {
    switch (type) {
      case 'new_request_nearby':
        return 'New service requests in your area';
      case 'new_instant_booking':
        return 'Instant booking requests';
      case 'booking_cancelled':
        return 'Job cancellation notifications';
      case 'payout_processed':
        return 'Payout processed notifications';
      case 'new_review':
        return 'New customer review notifications';
      default:
        return 'General notifications';
    }
  }

  // ========================================
  // FIRESTORE SAVING
  // ========================================

  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = message.data;
    final type = data['type'] ?? 'general';

    await FirebaseFirestore.instance
        .collection('notifications')
        .add({
      'userId': user.uid,
      'userType': 'technician',
      'title': message.notification?.title ?? 'New Notification',
      'body': message.notification?.body ?? '',
      'type': type,
      'data': data,
      'isRead': false,
      'priority': TechnicianNotificationTypeMapper.isHighPriority(type) ? 'high' : 'normal',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ========================================
  // NAVIGATION
  // ========================================

  Future<void> _navigateFromNotification(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] ?? '';
    debugPrint('[TechNotificationHandler] Navigate: $type');
  }

  // ========================================
  // UTILITIES
  // ========================================

  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  // ========================================
  // PUBLIC API
  // ========================================

  Future<void> removeToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('removeFcmToken');
      
      await callable.call({
        'token': token,
        'userType': 'technician',
      });
    } catch (e) {
      debugPrint('[TechNotificationHandler] Failed to remove token: $e');
    }
  }

  void dispose() {
    _foregroundMessageController.close();
    _badgeCountController.close();
  }
}

// Export singleton
final technicianNotificationHandler = TechnicianNotificationHandler();
