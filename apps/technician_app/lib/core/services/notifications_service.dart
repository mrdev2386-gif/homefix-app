import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Android Notification Channel
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'job_alerts_channel',
        'Job Alerts',
        description: 'New job requests and status updates.',
        importance: Importance.max,
      );

      await _localNotif
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 2. Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Setup Token Handlers
    _setupTokenHandlers();

    // 4. Foreground Listening
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
      _saveInternalNotification(message);
    });

    // 5. Interaction Handlers
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
  }

  static void _setupTokenHandlers() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        String? token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(token);
        }
      }
    });

    _messaging.onTokenRefresh.listen((token) async {
      await _saveTokenToFirestore(token);
    });
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('technicians')
        .doc(user.uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': Platform.isAndroid ? 'android' : 'ios',
    });
    
    // Legacy support
    await FirebaseFirestore.instance.collection('technicians').doc(user.uid).update({
      'fcmToken': token,
    });
  }

  static void _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotif.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'job_alerts_channel',
            'Job Alerts',
            channelDescription: 'New job requests and status updates.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  static void _handleNotificationClick(RemoteMessage message) {
    debugPrint('Technician clicked notification: ${message.data}');
    // Add logic to navigate to Job Details
  }

  static Future<void> _saveInternalNotification(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': message.notification?.title ?? 'New Job Update',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'type': message.data['type'] ?? 'job_update',
      });
    }
  }
}
