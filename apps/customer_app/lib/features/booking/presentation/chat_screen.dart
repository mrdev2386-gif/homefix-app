/**
 * Chat Screen for HomeFix Customer App
 * 
 * Real-time chat interface between customer and technician.
 * Only accessible after booking is accepted.
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/models/chat.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String? technicianName;
  final String? serviceName;

  const ChatScreen({
    super.key,
    required this.bookingId,
    this.technicianName,
    this.serviceName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  String? _chatId;
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  List<ChatMessage> _messages = [];
  bool _hasMoreMessages = true;
  DateTime? _lastMessageDate;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get or create chat
      final chatResult = await _chatService.getOrCreateChat(widget.bookingId);
      
      setState(() {
        _chatId = chatResult.chatId;
        _isLoading = false;
      });

      // Mark messages as read
      if (_chatId != null) {
        await _chatService.markMessagesRead(_chatId!);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatId == null || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendMessage(_chatId!, text);
      _messageController.clear();
      
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_chatId == null || _hasMoreMessages == false || _lastMessageDate == null) {
      return;
    }

    try {
      final olderMessages = await _chatService.loadMoreMessages(
        _chatId!,
        _lastMessageDate!,
      );

      setState(() {
        if (olderMessages.isEmpty) {
          _hasMoreMessages = false;
        } else {
          _messages.addAll(olderMessages);
          _lastMessageDate = olderMessages.last.createdAt;
        }
      });
    } catch (e) {
      // Silent fail for pagination
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.technicianName ?? 'Chat',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (widget.serviceName != null)
              Text(
                widget.serviceName!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show chat options
            },
          ),
        ],
      ),
      body: _buildBody(userId),
    );
  }

  Widget _buildBody(String? userId) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to open chat',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeChat,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_chatId == null) {
      return const Center(
        child: Text('Chat not available'),
      );
    }

    return Column(
      children: [
        // Messages list
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: _chatService.getMessagesStream(_chatId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final messages = snapshot.data ?? [];
              
              // Update state for pagination
              if (messages.isNotEmpty && _lastMessageDate == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _messages = messages;
                    _lastMessageDate = messages.last.createdAt;
                  });
                });
              }

              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start the conversation!',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification) {
                    _onScroll();
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.isFromUser(userId ?? '');
                    final showDate = _shouldShowDate(messages, index);

                    return Column(
                      children: [
                        if (showDate) _buildDateSeparator(message.createdAt),
                        _MessageBubble(
                          message: message,
                          isMe: isMe,
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),

        // Input area
        _buildMessageInput(),
      ],
    );
  }

  bool _shouldShowDate(List<ChatMessage> messages, int index) {
    if (index == messages.length - 1) return true;
    
    final current = messages[index].createdAt;
    final previous = messages[index + 1].createdAt;
    
    if (current == null || previous == null) return false;
    
    return !_isSameDay(current, previous);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateSeparator(DateTime? date) {
    if (date == null) return const SizedBox.shrink();

    final now = DateTime.now();
    String dateText;

    if (_isSameDay(date, now)) {
      dateText = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: IconButton.filled(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }
}

/// Message bubble widget
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: RepaintBoundary(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isMe
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
