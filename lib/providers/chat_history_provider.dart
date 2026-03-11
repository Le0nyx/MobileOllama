import 'package:flutter/material.dart';
import '../models/chat_session.dart';
import '../services/storage_service.dart';

class ChatHistoryProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<ChatSession> _sessions = [];

  List<ChatSession> get sessions => _sessions;

  Future<void> init() async {
    _sessions = await _storage.loadChatSessions();
    // Sort newest first.
    _sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> saveSession(ChatSession session) async {
    final idx = _sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      _sessions[idx] = session;
    } else {
      _sessions.insert(0, session);
    }
    await _storage.saveChatSessions(_sessions);
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    await _storage.saveChatSessions(_sessions);
    notifyListeners();
  }

  Future<void> renameSession(String id, String newTitle) async {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      _sessions[idx].title = newTitle;
      await _storage.saveChatSessions(_sessions);
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    _sessions.clear();
    await _storage.clearChatSessions();
    notifyListeners();
  }
}
