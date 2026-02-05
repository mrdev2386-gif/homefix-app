import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  final String _apiKey = 'AIzaSyBdSr_SrTpNmAlYyxeiPq_b8kA9FzZ6Xgg';
  late final GenerativeModel _model;
  ChatSession? _chat;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<String> sendMessage(String message, {String? context}) async {
    try {
      _chat ??= _model.startChat();
      
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
