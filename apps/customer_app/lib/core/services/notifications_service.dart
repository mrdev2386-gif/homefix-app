import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

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
      );

      await _localNotif
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 2. Request permissions
    // On web, this requests browser permission
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

    // 5. Interaction Handlers
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
    
    // Background handling of initial message
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
          // getToken() requires a vapidKey on web or a service worker file
          // If we don't have it, we skip to avoid crash
          String? token;
          if (kIsWeb) {
            // token = await _messaging.getToken(vapidKey: '...');
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

    await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': platform,
    });
    
    // Also update legacy field for backward compatibility if needed
    await FirebaseFirestore.instance.collection('customers').doc(user.uid).update({
      'fcmToken': token,
    });
  }

  static void _showLocalNotification(RemoteMessage message) async {
    // Skip local notifications on web for now as they are handled by browser/worker
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
          ) : null,
          iOS: const DarwinNotificationDetails(),
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
    // Logic for deep linking goes here
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
