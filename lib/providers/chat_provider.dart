import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/ollama_api_service.dart';

class ChatProvider extends ChangeNotifier {
  final OllamaApiService _api = OllamaApiService();
  static const _uuid = Uuid();

  ChatSession? _currentSession;
  bool _isStreaming = false;
  String? _error;

  ChatSession? get currentSession => _currentSession;
  List<ChatMessage> get messages => _currentSession?.messages ?? [];
  bool get isStreaming => _isStreaming;
  String? get error => _error;

  /// Start a fresh chat session.
  void newChat(String model) {
    _currentSession = ChatSession(
      id: _uuid.v4(),
      title: 'New Chat',
      messages: [],
      model: model,
    );
    _error = null;
    notifyListeners();
  }

  /// Load an existing chat session.
  void loadSession(ChatSession session) {
    _currentSession = session;
    _error = null;
    notifyListeners();
  }

  /// Send a user message and stream the assistant response.
  Future<void> sendMessage({
    required String text,
    required String apiKey,
    required String model,
    List<String>? images,
    String? systemPrompt,
    String? baseUrl,
  }) async {
    if (text.trim().isEmpty && (images == null || images.isEmpty)) return;

    // Ensure we have a session.
    if (_currentSession == null) {
      newChat(model);
    }

    // Update model if changed.
    _currentSession!.model = model;

    // Add user message.
    final userMsg = ChatMessage(
      role: 'user',
      content: text.trim(),
      images: images,
    );
    _currentSession!.messages.add(userMsg);

    // Auto-title from first user message.
    if (_currentSession!.messages.where((m) => m.role == 'user').length == 1) {
      _currentSession!.title = text.trim().length > 40
          ? '${text.trim().substring(0, 40)}...'
          : text.trim();
    }

    // Add placeholder assistant message that will be filled via streaming.
    final assistantMsg = ChatMessage(role: 'assistant', content: '');
    _currentSession!.messages.add(assistantMsg);

    _isStreaming = true;
    _error = null;
    notifyListeners();

    try {
      final apiMessages =
          _currentSession!.messages
              .where((m) => m.content.isNotEmpty || m.role == 'user')
              .map((m) => m.toApiPayload())
              .toList();

      // Remove the empty assistant placeholder from API payload.
      if (apiMessages.isNotEmpty && apiMessages.last['role'] == 'assistant') {
        apiMessages.removeLast();
      }

      // Prepend system prompt if configured.
      if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
        apiMessages.insert(0, {
          'role': 'system',
          'content': systemPrompt.trim(),
        });
      }

      await for (final chunk in _api.sendMessageStream(
        apiKey: apiKey,
        model: model,
        messages: apiMessages,
        baseUrl: baseUrl,
      )) {
        assistantMsg.content += chunk;
        notifyListeners();
      }
    } catch (e) {
      String errorMsg = e.toString();
      // Clean up the "Exception: " prefix for readability.
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      _error = errorMsg;
      // Remove the empty assistant message if streaming failed with no content.
      if (assistantMsg.content.isEmpty) {
        _currentSession!.messages.remove(assistantMsg);
      }
    } finally {
      _isStreaming = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
