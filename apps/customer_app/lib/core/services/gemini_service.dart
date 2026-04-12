import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  // SECURITY FIX: API key moved to environment variable
  // Set GEMINI_API_KEY in your environment or use Firebase Remote Config
  final String _apiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Empty default - service will fail gracefully
  );
  late final GenerativeModel? _model;
  ChatSession? _chat;

  GeminiService() {
    if (_apiKey.isEmpty) {
      debugPrint('⚠️ [Gemini] API key not configured. Set GEMINI_API_KEY environment variable.');
      _model = null;
    } else {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );
    }
  }

  Future<String> sendMessage(String message, {String? context}) async {
    // Check if service is configured
    if (_model == null) {
      debugPrint('[Gemini] Service not configured - API key missing');
      return "AI chat is currently unavailable. Please contact support.";
    }
    
    try {
      _chat ??= _model!.startChat();
      
      String prompt = message;
      if (context != null) {
        prompt = "Context: $context\n\nUser Message: $message";
      }

      final response = await _chat!.sendMessage(Content.text(prompt));
      return response.text ?? "I'm sorry, I couldn't understand that.";
    } catch (e) {
      debugPrint("Gemini Error: $e");
      return "I'm having some trouble connecting. Please try again later.";
    }
  }

  void resetChat() {
    _chat = null;
  }
}
