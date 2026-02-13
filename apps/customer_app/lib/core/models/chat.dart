/**
 * Chat Models for HomeFix
 * 
 * Data models for chat and messages following Firestore schema.
 */

import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat metadata stored in chats/{chatId}
class Chat {
  final String id;
  final String bookingId;
  final String customerId;
  final String technicianId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final DateTime? createdAt;
  final bool isActive;

  Chat({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.technicianId,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
    this.createdAt,
    this.isActive = true,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: data['id'] ?? doc.id,
      bookingId: data['bookingId'] ?? '',
      customerId: data['customerId'] ?? '',
      technicianId: data['technicianId'] ?? '',
      lastMessage: data['lastMessage'],
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastSenderId: data['lastSenderId'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'bookingId': bookingId,
      'customerId': customerId,
      'technicianId': technicianId,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : FieldValue.serverTimestamp(),
      'lastSenderId': lastSenderId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }
}

/// Chat message stored in chats/{chatId}/messages/{messageId}
class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderType; // 'customer' | 'technician'
  final String text;
  final String? imageUrl;
  final DateTime? createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderType,
    required this.text,
    this.imageUrl,
    this.createdAt,
    this.isRead = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: data['id'] ?? doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderType: data['senderType'] ?? 'customer',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderType': senderType,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }

  /// Check if message is from current user
  bool isFromUser(String userId) => senderId == userId;
}

/// Result of getOrCreateChat callable
class ChatResult {
  final String chatId;
  final String bookingId;
  final String customerId;
  final String technicianId;
  final bool isNew;

  ChatResult({
    required this.chatId,
    required this.bookingId,
    required this.customerId,
    required this.technicianId,
    required this.isNew,
  });

  factory ChatResult.fromMap(Map<String, dynamic> map) {
    return ChatResult(
      chatId: map['chatId'] ?? '',
      bookingId: map['bookingId'] ?? '',
      customerId: map['customerId'] ?? '',
      technicianId: map['technicianId'] ?? '',
      isNew: map['isNew'] ?? false,
    );
  }
}
