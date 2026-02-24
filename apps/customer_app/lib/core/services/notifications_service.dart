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
import '../../features/bookings/presentation/booking_detail_screen.dart';
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

  bool get isHighPriority => priority?.toLowerCase() == 'high';

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userType: data['userType'] ?? 'customer',
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

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userType': userType,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': isRead,
      'imageUrl': imageUrl,
      'priority': priority,
      'createdAt': createdAt,
    };
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

  // Initialize notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Android Channels
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await _localNotif
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // 1.5 Initialize Local Notifications for clicks
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
              debugPrint('[NotificationsService] Payload parse error: $e');
            }
          }
        },
      );

      // 2. Request permissions
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // 3. Setup token handlers
      _setupTokenHandlers();
      
      // 4. Setup message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      debugPrint('[NotificationsService] Initialized successfully');
    } catch (e) {
      debugPrint('[NotificationsService] Initialization error: $e');
    }
  }

  void _setupTokenHandlers() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        final token = await _messaging.getToken();
        if (token != null) await _saveToken(token);
        _setupDataStreams(user.uid);
      } else {
        // IMPROVEMENT: Potential cleanup of token on logout for reliability
        try {
          final token = await _messaging.getToken();
          if (token != null) {
            final callable = FirebaseFunctions.instance.httpsCallable('removeFcmToken');
            await callable.call({
              'token': token,
              'userType': 'customer',
            });
            debugPrint('[NotificationsService] Token removed on logout');
          }
        } catch (e) {
          debugPrint('[NotificationsService] Token removal failed or skip: $e');
        }
        
        _notifications = [];
        _unreadCount = 0;
        notifyListeners();
      }
    });

    _messaging.onTokenRefresh.listen((token) => _saveToken(token));
  }

  Future<void> _saveToken(String token) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('saveFcmToken');
      await callable.call({
        'token': token,
        'platform': defaultTargetPlatform.toString().split('.').last,
        'userType': 'customer',
      });
      debugPrint('[NotificationsService] Token saved');
    } catch (e) {
      debugPrint('[NotificationsService] Token save failed: $e');
    }
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[NotificationsService] Foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[NotificationsService] Message opened app');
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
          MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: booking))
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
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
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

  static Stream<List<NotificationModel>> streamNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  static Future<List<NotificationModel>> getNotificationsPaginated(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final QuerySnapshot snapshot = await query.get();
    return snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
  }

  static Future<DocumentSnapshot> getNotification(String notificationId) async {
    return FirebaseFirestore.instance.collection('notifications').doc(notificationId).get();
  }

  // --- Actions ---

  static Future<void> markAsRead(String notificationId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('markNotificationRead');
      await callable.call({'notificationId': notificationId});
    } catch (e) {
      debugPrint('[NotificationsService] Mark as read failed: $e');
    }
  }

  static Future<void> markAllAsRead(String userId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('markAllNotificationsRead');
      await callable.call();
    } catch (e) {
      debugPrint('[NotificationsService] Mark all as read failed: $e');
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('deleteNotificationCallable');
      await callable.call({'notificationId': notificationId});
    } catch (e) {
      debugPrint('[NotificationsService] Delete failed: $e');
    }
  }

  static Future<void> deleteAllNotifications(String userId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('deleteAllNotificationsCallable');
      await callable.call();
    } catch (e) {
      debugPrint('[NotificationsService] Delete all failed: $e');
    }
  }
}
