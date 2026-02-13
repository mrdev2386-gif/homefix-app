import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

// ==========================================
// NOTIFICATION CHANNEL CONSTANTS
// ==========================================

class NotificationChannels {
  // Customer App Channels
  static const String bookingUpdates = 'booking_updates';
  static const String generalNotifications = 'general_notifications';
  
  // Technician App Channels
  static const String jobAlerts = 'job_alerts';
}

// ==========================================
// NOTIFICATION TYPES MAPPING
// ==========================================

class NotificationTypeMapper {
  static String getChannelId(String type) {
    switch (type) {
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'technician_en_route':
      case 'technician_arrived':
      case 'job_completed':
      case 'chat_message':
        return NotificationChannels.bookingUpdates;
      
      case 'payment_success':
      case 'payment_failed':
      case 'new_review':
      case 'custom_request_accepted':
      default:
        return NotificationChannels.generalNotifications;
    }
  }

  static bool isHighPriority(String type) {
    switch (type) {
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'technician_en_route':
      case 'technician_arrived':
      case 'payment_failed':
      case 'chat_message':
        return true;
      default:
        return false;
    }
  }
}

// ==========================================
// NOTIFICATION HANDLER SERVICE
// ==========================================

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._();
  factory NotificationHandler() => _instance;
  NotificationHandler._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();
  
  // Streams for real-time updates
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
    if (defaultTargetPlatform != TargetPlatform.android) return;

    // Booking Updates Channel - High Priority
    const bookingChannel = AndroidNotificationChannel(
      NotificationChannels.bookingUpdates,
      'Booking Updates',
      description: 'Real-time updates about your bookings, technician arrival, and job status.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // General Notifications Channel - Default Priority
    const generalChannel = AndroidNotificationChannel(
      NotificationChannels.generalNotifications,
      'General Notifications',
      description: 'Payment confirmations, reviews, and other updates.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(bookingChannel);
        
    await _localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);

    debugPrint('[NotificationHandler] Android channels created');
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('[NotificationHandler] Permission status: ${settings.authorizationStatus}');
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
    debugPrint('[NotificationHandler] Foreground message: ${message.notification?.title}');

    // Emit to stream for real-time UI updates
    _foregroundMessageController.add(message);

    // Show local notification (only on Android)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _showLocalNotification(message);
    }

    // Save to Firestore for history
    await _saveNotificationToFirestore(message);
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('[NotificationHandler] Message opened app: ${message.data}');
    
    // Emit to stream
    _foregroundMessageController.add(message);
    
    // Navigate based on notification data
    await _navigateFromNotification(message);
  }

  // ========================================
  // TOKEN REFRESH HANDLING
  // ========================================

  Future<void> _setupTokenRefreshHandler() async {
    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('[NotificationHandler] Token refreshed');
      await _saveTokenToFirestore(token);
    });
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Try Cloud Function first
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('saveFcmToken');
      
      await callable.call({
        'token': token,
        'platform': _getPlatform(),
        'userType': 'customer',
      });
      
      debugPrint('[NotificationHandler] Token saved via Cloud Function');
    } catch (e) {
      debugPrint('[NotificationHandler] Cloud Function failed, using fallback: $e');
      
      // Fallback to direct write
      try {
        await FirebaseFirestore.instance
            .collection('customers')
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
        debugPrint('[NotificationHandler] Token saved via fallback');
      } catch (fallbackError) {
        debugPrint('[NotificationHandler] Fallback also failed: $fallbackError');
      }
    }
  }

  // ========================================
  // BADGE COUNT STREAM
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
    final channelId = NotificationTypeMapper.getChannelId(type);
    final isHighPriority = NotificationTypeMapper.isHighPriority(type);

    // Check if notification already shown (prevent duplicate)
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
          largeIcon: android?.imageUrl,
          largeIconBitmapSource: android?.imageUrl != null 
              ? BitmapSource.fromUrl 
              : BitmapSource.defaultSource,
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
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'technician_en_route':
      case 'technician_arrived':
      case 'job_completed':
        return 'Booking Updates';
      case 'chat_message':
        return 'Messages';
      case 'payment_success':
      case 'payment_failed':
        return 'Payment Updates';
      case 'new_review':
        return 'Reviews';
      default:
        return 'General Notifications';
    }
  }

  String _getChannelDescription(String type) {
    switch (type) {
      case 'booking_confirmed':
        return 'Notifications about booking confirmations';
      case 'booking_cancelled':
        return 'Notifications about cancelled bookings';
      case 'technician_en_route':
        return 'Technician is on the way notifications';
      case 'technician_arrived':
        return 'Technician has arrived notifications';
      case 'job_completed':
        return 'Job completion notifications';
      case 'chat_message':
        return 'Chat messages from technicians';
      case 'payment_success':
        return 'Payment success notifications';
      case 'payment_failed':
        return 'Payment failed notifications';
      case 'new_review':
        return 'New review notifications';
      default:
        return 'General app notifications';
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
      'userType': 'customer',
      'title': message.notification?.title ?? 'New Notification',
      'body': message.notification?.body ?? '',
      'type': type,
      'data': data,
      'isRead': false,
      'priority': NotificationTypeMapper.isHighPriority(type) ? 'high' : 'normal',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ========================================
  // NAVIGATION
  // ========================================

  Future<void> _navigateFromNotification(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] ?? '';
    final bookingId = data['bookingId'] ?? '';
    final requestId = data['requestId'] ?? '';
    final chatId = data['chatId'] ?? '';

    // Navigation would be handled by the app's navigator
    // This is a placeholder that emits the navigation event
    debugPrint('[NotificationHandler] Should navigate to: $type, booking: $bookingId, chat: $chatId');
  }

  // ========================================
  // UTILITIES
  // ========================================

  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
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
        'userType': 'customer',
      });
    } catch (e) {
      debugPrint('[NotificationHandler] Failed to remove token: $e');
    }
  }

  void dispose() {
    _foregroundMessageController.close();
    _badgeCountController.close();
  }
}

// Export singleton instance
final notificationHandler = NotificationHandler();
