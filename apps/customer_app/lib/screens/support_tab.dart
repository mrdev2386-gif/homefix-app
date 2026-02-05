import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../core/services/gemini_service.dart';
import '../core/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'ticket_screen.dart';

class SupportTab extends StatefulWidget {
  const SupportTab({super.key});

  @override
  State<SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<SupportTab> {
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'text': 'Hi! I am your HomeFix Assistant. How can I help you today?',
      'time': DateTime.now(),
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'text': text,
        'time': DateTime.now(),
      });
      _isTyping = true;
    });

    _controller.clear();

    final user = Provider.of<AuthProvider>(context, listen: false).customer;
    final contextStr = user != null ? "User: ${user.name}, Email: ${user.email}" : null;

    final response = await _geminiService.sendMessage(text, context: contextStr);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'role': 'assistant',
          'text': response,
          'time': DateTime.now(),
        });
      });
    }
  }

  Future<void> _callHelpline() async {
    final Uri url = Uri.parse('tel:9508322397');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Support", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketScreen())),
            icon: const Icon(Icons.support_agent),
            tooltip: "Create Ticket",
          ),
          TextButton.icon(
            onPressed: _callHelpline,
            icon: const Icon(Icons.call, size: 18),
            label: const Text("Call"),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return _buildMessageBubble(msg['text'], isUser, msg['time']);
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Text("Assistant is typing...", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser, DateTime time) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: GoogleFonts.outfit(color: isUser ? Colors.white : AppTheme.textColor, fontSize: 15)),
            const SizedBox(height: 4),
            Text(DateFormat('hh:mm a').format(time), style: GoogleFonts.outfit(color: isUser ? Colors.white70 : Colors.grey[500], fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                fillColor: Colors.grey[100],
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
