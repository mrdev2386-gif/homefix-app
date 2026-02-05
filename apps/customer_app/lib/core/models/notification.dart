import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // booking, request, proposal, info
  final String? referenceId; // bookingId or requestId
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'info',
      referenceId: data['referenceId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'referenceId': referenceId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}
