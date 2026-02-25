import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import '../models/booking.dart';
import 'booking_service.dart';
import '../../screens/job_details_screen.dart';
import '../../main.dart';

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
}

// ==========================================
// NOTIFICATIONS SERVICE (SINGLETON)
// ==========================================

class NotificationsService extends ChangeNotifier {
  static final NotificationsService _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isInitialized = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Android Channels
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'job_alerts_channel',
          'Job Alerts',
          description: 'New job requests and status updates.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await _localNotif
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // 1.5 Local Notif Click Support
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotif.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null) {
            try {
              final data = jsonDecode(response.payload!);
              _handleNotificationClick(data);
            } catch (e) {
              debugPrint('[Notifications] Payload error: $e');
            }
          }
        },
      );

      // 2. Request permissions
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Setup handlers
      _setupTokenHandlers();
      _setupMessageHandlers();

      _isInitialized = true;
    } catch (e) {
      debugPrint('[Notifications] Init error: $e');
    }
  }

  void _setupTokenHandlers() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        // Save token with retry logic
        await _saveTokenWithRetry();
        _setupDataStreams(user.uid);
      } else {
        // Cleanup token on logout
        await _removeTokenOnLogout();

        _notifications = [];
        _unreadCount = 0;
        notifyListeners();
      }
    });

    _messaging.onTokenRefresh.listen((token) async {
      await _saveTokenWithRetry();
    });
  }

  Future<void> _saveTokenWithRetry() async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final token = await _messaging.getToken();
        if (token != null) {
          await _saveToken(token);
          debugPrint('[Notifications] Token saved successfully on attempt $attempt');
          return;
        }
      } catch (e) {
        debugPrint('[Notifications] Token save attempt $attempt failed: $e');
        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }
    debugPrint('[Notifications] Failed to save token after $maxRetries attempts');
  }

  Future<void> _removeTokenOnLogout() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        final callable = FirebaseFunctions.instance.httpsCallable('removeFcmToken');
        await callable.call({
          'token': token,
          'userType': 'technician',
        });
        debugPrint('[Notifications] Token removed on logout');
      }
    } catch (e) {
      debugPrint('[Notifications] Token removal skip: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('saveFcmToken');
      await callable.call({
        'token': token,
        'platform': defaultTargetPlatform.toString().split('.').last,
        'userType': 'technician',
      });
    } catch (e) {
      debugPrint('[Notifications] Token save error: $e');
      // Don't rethrow - token save failure shouldn't break the app
    }
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationClick(message.data);
    });
  }

  Future<void> _handleNotificationClick(Map<String, dynamic> data) async {
    final type = data['type'];
    final bookingId = data['bookingId'];

    if (bookingId != null) {
      final booking = await BookingService().getBooking(bookingId);
      if (booking != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(builder: (_) => JobDetailsScreen(booking: booking))
        );
      }
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    if (kIsWeb) return;
    final notification = message.notification;
    if (notification != null) {
      _localNotif.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'job_alerts_channel',
            'Job Alerts',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _setupDataStreams(String userId) {
    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      _notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    });
  }

  static Stream<int> streamUnreadCount(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // --- Actions ---

  Future<void> markAsRead(String notificationId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('markNotificationRead');
      await callable.call({'notificationId': notificationId});
    } catch (e) {
      debugPrint('[Notifications] Mark read error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('markAllNotificationsRead');
      await callable.call();
    } catch (e) {
      debugPrint('[Notifications] Mark all read error: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('deleteNotificationCallable');
      await callable.call({'notificationId': notificationId});
    } catch (e) {
      debugPrint('[Notifications] Delete error: $e');
    }
  }
}
