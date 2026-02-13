import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
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

  // Deep link navigation based on notification type
  String get deepLink {
    final screen = data['screen'] ?? '';
    final bookingId = data['bookingId'] ?? '';
    final requestId = data['requestId'] ?? '';

    switch (type) {
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'job_completed':
        return '/booking/$bookingId';
      case 'technician_en_route':
      case 'technician_arrived':
        return '/booking/$bookingId/tracking';
      case 'payment_success':
      case 'payment_failed':
        return '/payment/$bookingId';
      case 'new_request_nearby':
      case 'new_instant_booking':
        return '/requests/new';
      case 'payout_processed':
        return '/technician/wallet';
      case 'new_review':
        return '/reviews';
      case 'custom_request_accepted':
        return '/requests/$requestId';
      default:
        return screen.isNotEmpty ? '/$screen' : '/notifications';
    }
  }

  bool get isHighPriority => priority == 'high';
}

// ==========================================
// FCM SERVICE
// ==========================================

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  // Platform detection
  static String _getPlatform() {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'unknown';
  }

  // Initialize FCM
  static Future<void> initialize() async {
    // Android Notification Channel
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
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

    // Request permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('[FCM] User granted permission');
    } else {
      debugPrint('[FCM] User denied permission');
    }

    // Setup handlers
    _setupTokenHandlers();
    _setupMessageHandlers();
  }

  // Setup token handlers
  static void _setupTokenHandlers() {
    // On login
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await _saveToken(user.uid);
      }
    });

    // On token refresh
    _messaging.onTokenRefresh.listen((token) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _saveToken(user.uid, token: token);
      }
    });
  }

  // Save token to Firestore via Cloud Function
  static Future<void> _saveToken(String userId, {String? token}) async {
    try {
      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken == null) {
        debugPrint('[FCM] No token available');
        return;
      }

      // Call Cloud Function to save token
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('saveFcmToken');
      
      await callable.call({
        'token': fcmToken,
        'platform': _getPlatform(),
        'userType': 'customer',
      });

      debugPrint('[FCM] Token saved successfully');
    } catch (e) {
      debugPrint('[FCM] Failed to save token: $e');
      // Fallback to direct write
      await _fallbackSaveToken(userId, token!);
    }
  }

  // Fallback direct write
  static Future<void> _fallbackSaveToken(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('customers')
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
      debugPrint('[FCM] Token saved via fallback');
    } catch (e) {
      debugPrint('[FCM] Fallback also failed: $e');
    }
  }

  // Remove token on logout
  static Future<void> removeToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('removeFcmToken');
      
      await callable.call({
        'token': token,
        'userType': 'customer',
      });

      debugPrint('[FCM] Token removed');
    } catch (e) {
      debugPrint('[FCM] Failed to remove token: $e');
    }
  }

  // Remove all tokens on complete logout
  static Future<void> removeAllTokens(String userId) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('removeAllFcmTokens');
      
      await callable.call({
        'userType': 'customer',
      });

      debugPrint('[FCM] All tokens removed');
    } catch (e) {
      debugPrint('[FCM] Failed to remove all tokens: $e');
    }
  }

  // Setup message handlers
  static void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      
      // Show local notification
      if (!kIsWeb) {
        _showLocalNotification(message);
      }
      
      // Save to Firestore
      _saveNotificationToFirestore(message);
    });

    // Background/terminated tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Terminated state
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  // Show local notification
  static void _showLocalNotification(RemoteMessage message) {
    if (kIsWeb) return;

    final notification = message.notification;
    final android = message.notification?.android;

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

  // Save notification to unified Firestore collection
  static Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = message.data;
    
    await FirebaseFirestore.instance
        .collection('notifications')
        .add({
      'id': '', // Will be set by Firestore
      'userId': user.uid,
      'userType': 'customer',
      'title': message.notification?.title ?? 'New Notification',
      'body': message.notification?.body ?? '',
      'type': data['type'] ?? 'general',
      'data': data,
      'isRead': false,
      'imageUrl': message.notification?.android?.imageUrl,
      'priority': data['priority'] ?? 'normal',
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('[NOTIFICATION] Saved to unified collection');
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final screen = data['screen'] ?? '';
    final bookingId = data['bookingId'] ?? '';
    
    debugPrint('[FCM] Notification tapped: $type');

    // Emit event for navigation
    // This would typically use a state management solution
  }
}

// ==========================================
// NOTIFICATIONS SERVICE
// ==========================================

class NotificationsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream notifications from unified collection
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

  // Stream unread count
  static Stream<int> streamUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark as read
  static Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Mark all as read
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

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // Delete all notifications
  static Future<void> deleteAllNotifications(String userId) async {
    final snapshots = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    
    if (snapshots.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  // Get notification by ID
  static Future<NotificationModel?> getNotification(String notificationId) async {
    final doc = await _firestore
        .collection('notifications')
        .doc(notificationId)
        .get();

    if (!doc.exists) return null;
    return NotificationModel.fromFirestore(doc);
  }

  // Pagination support
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

// ==========================================
// NOTIFICATION BLoC / PROVIDER
// ==========================================

class NotificationProvider with ChangeNotifier {
  final List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _unreadSubscription;

  // Initialize
  void initialize(String userId) {
    _setupStreams(userId);
  }

  void _setupStreams(String userId) {
    // Notifications stream
    _notificationsSubscription = NotificationsService.streamNotifications(userId)
        .listen((notifications) {
      _notifications.clear();
      _notifications.addAll(notifications);
      notifyListeners();
    });

    // Unread count stream
    _unreadSubscription = NotificationsService.streamUnreadCount(userId)
        .listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await NotificationsService.markAsRead(notificationId);
      _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await NotificationsService.markAllAsRead(userId);
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await NotificationsService.deleteNotification(notificationId);
      final notification = _notifications.firstWhere((n) => n.id == notificationId);
      if (!notification.isRead) {
        _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
      }
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Dispose
  void dispose() {
    _notificationsSubscription?.cancel();
    _unreadSubscription?.cancel();
    super.dispose();
  }
}
