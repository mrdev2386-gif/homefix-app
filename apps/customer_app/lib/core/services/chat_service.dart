/// Chat Service for HomeFix Customer App
/// 
/// Handles all chat-related operations:
/// - Get or create chat for a booking
/// - Send messages
/// - Mark messages as read
/// - Stream messages in real-time
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';
import 'functions_helper.dart';

class ChatService {
  static final ChatService _instance = ChatService._();
  factory ChatService() => _instance;
  ChatService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Debounce tracker for markMessagesRead
  final Map<String, DateTime> _readDebounceMap = {};
  static const _READ_DEBOUNCE_MS = 500; // 500ms debounce

  String? get _userId => _auth.currentUser?.uid;

  // ==========================================
  // GET OR CREATE CHAT
  // ==========================================

  /// Gets existing chat or creates new one for a booking.
  /// Only works when booking status is 'accepted' and technician is assigned.
  /// 
  /// Returns ChatResult containing chatId and participant info.
  /// 
  /// Throws HttpsError with:
  /// - 'failed-precondition' if booking not accepted or no technician assigned
  /// - 'permission-denied' if user is not a participant
  Future<ChatResult> getOrCreateChat(String bookingId) async {
    try {
      final callable = await FunctionsHelper.getCallable('getOrCreateChat');
      final result = await callable.call({'bookingId': bookingId});
      
      final data = result.data as Map<String, dynamic>;
      return ChatResult.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      throw _handleFunctionError(e);
    }
  }

  // ==========================================
  // SEND MESSAGE
  // ==========================================

  /// Sends a message to a chat.
  /// 
  /// Returns messageId on success.
  /// 
  /// Throws HttpsError with:
  /// - 'resource-exhausted' if rate limited
  /// - 'permission-denied' if user not a participant
  Future<String> sendMessage(String chatId, String text, {String? imageUrl}) async {
    try {
      final callable = await FunctionsHelper.getCallable('sendChatMessage');
      final result = await callable.call({
        'chatId': chatId,
        'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
      });
      
      final data = result.data as Map<String, dynamic>;
      return data['messageId'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw _handleFunctionError(e);
    }
  }

  // ==========================================
  // MARK MESSAGES READ
  // ==========================================

  /// Marks unread messages in a chat as read.
  /// Only marks messages sent by the other party.
  /// Uses debouncing to prevent rapid-fire calls.
  Future<int> markMessagesRead(String chatId) async {
    final now = DateTime.now();
    final lastCall = _readDebounceMap[chatId];
    
    // Debounce: skip if called within 500ms
    if (lastCall != null && now.difference(lastCall).inMilliseconds < _READ_DEBOUNCE_MS) {
      return 0;
    }
    
    _readDebounceMap[chatId] = now;
    
    try {
      final callable = await FunctionsHelper.getCallable('markMessagesRead');
      final result = await callable.call({'chatId': chatId});
      
      final data = result.data as Map<String, dynamic>;
      return data['markedCount'] as int? ?? 0;
    } on FirebaseFunctionsException catch (e) {
      throw _handleFunctionError(e);
    }
  }

  // ==========================================
  // GET CHAT DETAILS
  // ==========================================

  /// Gets chat details including booking info.
  Future<Map<String, dynamic>> getChatDetails(String chatId) async {
    try {
      final callable = await FunctionsHelper.getCallable('getChatDetails');
      final result = await callable.call({'chatId': chatId});
      
      return result.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      throw _handleFunctionError(e);
    }
  }

  // ==========================================
  // REAL-TIME MESSAGE STREAM
  // ==========================================

  /// Creates a stream of messages for a chat.
  /// Uses Firestore snapshots for real-time updates.
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  /// Loads older messages for pagination.
  Future<List<ChatMessage>> loadMoreMessages(
    String chatId,
    DateTime beforeDate,
  ) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .startAfter([beforeDate])
        .limit(30)
        .get();

    return snapshot.docs
        .map((doc) => ChatMessage.fromFirestore(doc))
        .toList();
  }

  // ==========================================
  // CHAT LIST (For future ChatListScreen)
  // ==========================================

  /// Gets all chats for the current user.
  Stream<List<Chat>> getChatsStream() {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        .where('customerId', isEqualTo: _userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Chat.fromFirestore(doc))
          .toList();
    });
  }

  // ==========================================
  // ERROR HANDLING
  // ==========================================

  Exception _handleFunctionError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'failed-precondition':
        return Exception(e.message ?? 'Chat is not available yet');
      case 'permission-denied':
        return Exception('You are not authorized to access this chat');
      case 'resource-exhausted':
        return Exception('Too many messages. Please wait a moment.');
      case 'not-found':
        return Exception('Chat not found');
      default:
        return Exception('Failed to perform chat operation');
    }
  }
}
