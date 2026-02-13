import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

class NotificationsService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Android Notification Channel (Heads-up notifications)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotif
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 2. Request permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    }

    // 3. Setup Token Handlers
    _setupTokenHandlers();

    // 4. Foreground Listening
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM Foreground: ${message.notification?.title}');
      if (!kIsWeb) {
        _showLocalNotification(message);
      }
      saveNotification(message);
    });

    // 5. Background tap handler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
    
    // 6. Terminated state - getInitialMessage
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationClick(message);
      }
    });
  }

  static void _setupTokenHandlers() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        try {
          String? token;
          if (kIsWeb) {
            debugPrint("FCM token retrieval skipped on web (requires vapidKey & service worker)");
          } else {
            token = await _messaging.getToken();
          }
          
          if (token != null) {
            await _saveTokenToFirestore(token);
          }
        } catch (e) {
          debugPrint("Failed to get FCM token: $e");
        }
      }
    });

    _messaging.onTokenRefresh.listen((token) async {
      try {
        await _saveTokenToFirestore(token);
      } catch (e) {
        debugPrint("Failed to save refreshed token: $e");
      }
    });
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String platform = 'web';
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) platform = 'android';
      else if (defaultTargetPlatform == TargetPlatform.iOS) platform = 'ios';
    }

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('saveFCMToken');
      await callable.call({
        'token': token,
        'platform': platform,
      });
      debugPrint('FCM token saved via callable function');
    } catch (e) {
      debugPrint('Failed to save FCM token via callable: $e');
      _fallbackTokenWrite(user.uid, token, platform);
    }
  }

  /// Fallback direct write - ONLY use for development/debugging
  static Future<void> _fallbackTokenWrite(String uid, String token, String platform) async {
    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token.hashCode.toString())
          .set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': platform,
      });
      debugPrint('FCM token saved via fallback direct write (development only)');
    } catch (e) {
      debugPrint('Fallback FCM token write also failed: $e');
    }
  }

  static void _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      _localNotif.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: android != null ? const AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ) : null,
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  static void _handleNotificationClick(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final referenceId = data['bookingId'] ?? data['id'];

    debugPrint('Notification clicked: $type -> $referenceId');
    // Logic for deep linking goes here - handle based on 'type'
  }

  static Future<void> saveNotification(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': message.notification?.title ?? 'New Notification',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'type': message.data['type'] ?? 'general',
      });
    }
  }

  static Stream<int> streamUnreadCount(String userId) {
    return FirebaseFirestore.instance
        .collection('customers').doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Stream<List<Map<String, dynamic>>> streamNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('customers').doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  static Future<void> markAsRead(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  static Future<void> markAllAsRead(String userId) async {
    final snapshots = await FirebaseFirestore.instance
        .collection('customers').doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
