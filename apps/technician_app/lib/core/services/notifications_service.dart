import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_functions/cloud_functions.dart';

// ==========================================
// NOTIFICATION MODEL
// ==========================================

class NotificationModel {
  final String id;
  final String userId;
  final String userType;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final String? imageUrl;
  final String? priority;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.userType,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    this.imageUrl,
    this.priority,
    this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userType: data['userType'] ?? 'technician',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'general',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      isRead: data['isRead'] ?? false,
      imageUrl: data['imageUrl'],
      priority: data['priority'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }

  bool get isHighPriority => priority == 'high';

  String get deepLink {
    final screen = data['screen'] ?? '';
    final bookingId = data['bookingId'] ?? '';
    final requestId = data['requestId'] ?? '';

    switch (type) {
      case 'new_request_nearby':
      case 'new_instant_booking':
        return '/requests/$requestId';
      case 'payout_processed':
        return '/wallet';
      case 'new_review':
        return '/reviews';
      default:
        return screen.isNotEmpty ? '/$screen' : '/notifications';
    }
  }
}

// ==========================================
// FCM SERVICE
// ==========================================

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  static String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  static Future<void> initialize() async {
    // Android Notification Channel
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'job_alerts_channel',
        'Job Alerts',
        description: 'New job requests and status updates.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotif
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Setup handlers
    _setupTokenHandlers();
    _setupMessageHandlers();
  }

  static void _setupTokenHandlers() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await _saveToken(user.uid);
      }
    });

    _messaging.onTokenRefresh.listen((token) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _saveToken(user.uid, token: token);
      }
    });
  }

  static Future<void> _saveToken(String userId, {String? token}) async {
    try {
      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken == null) return;

      // Call Cloud Function to save token
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('saveFcmToken');
      
      await callable.call({
        'token': fcmToken,
        'platform': _getPlatform(),
        'userType': 'technician',
      });

      debugPrint('[FCM] Token saved for technician');
    } catch (e) {
      debugPrint('[FCM] Failed to save token: $e');
      // Fallback
      await _fallbackSaveToken(userId, token!);
    }
  }

  static Future<void> _fallbackSaveToken(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(userId)
          .collection('fcmTokens')
          .doc('${token.hashCode}_${DateTime.now().millisecondsSinceEpoch}')
          .set({
        'token': token,
        'platform': _getPlatform(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'invalidCount': 0,
      });
    } catch (e) {
      debugPrint('[FCM] Fallback failed: $e');
    }
  }

  static Future<void> removeToken(String userId) async {
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
      debugPrint('[FCM] Failed to remove token: $e');
    }
  }

  static void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title}');
      _showLocalNotification(message);
      _saveNotificationToFirestore(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotif.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
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

  static Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = message.data;
    
    await FirebaseFirestore.instance
        .collection('notifications')
        .add({
      'userId': user.uid,
      'userType': 'technician',
      'title': message.notification?.title ?? 'New Notification',
      'body': message.notification?.body ?? '',
      'type': data['type'] ?? 'general',
      'data': data,
      'isRead': false,
      'imageUrl': message.notification?.android?.imageUrl,
      'priority': data['priority'] ?? 'normal',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    debugPrint('[FCM] Technician tapped: $type');
  }
}

// ==========================================
// NOTIFICATIONS SERVICE
// ==========================================

class NotificationsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  static Stream<int> streamUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  static Future<void> markAllAsRead(String userId) async {
    final snapshots = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    if (snapshots.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  static Future<List<NotificationModel>> getNotificationsPaginated(
    String userId, {
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList();
  }
}
