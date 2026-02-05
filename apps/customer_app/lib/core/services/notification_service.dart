import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initialize(String userId) async {
    // Request permission for iOS/Web
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS) {
      await _fcm.requestPermission();
    }

    // Get the token and save it to the user document
    String? token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToDatabase(userId, token);
    }

    // Listen to token refresh
    _fcm.onTokenRefresh.listen((token) {
      _saveTokenToDatabase(userId, token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Message received: ${message.notification?.title}");
      // Optionally create a local notification or add to Firestore
      // Usually Cloud Functions will create the Notification document in Firestore
    });
  }

  Future<void> _saveTokenToDatabase(String userId, String token) async {
    await _db.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  Stream<int> streamUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshots = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    
    final batch = _db.batch();
    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
