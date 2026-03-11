import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';

class StorageService {
  static const _keyApiKey = 'api_key';
  static const _keySelectedModel = 'selected_model';
  static const _keyThemeMode = 'theme_mode';
  static const _keyChatSessions = 'chat_sessions';
  static const _keySystemPrompt = 'system_prompt';

  // --- Settings ---

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, apiKey);
  }

  Future<String?> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey);
  }

  Future<void> saveSelectedModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedModel, model);
  }

  Future<String?> loadSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedModel);
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.name);
  }

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_keyThemeMode);
    return ThemeMode.values.firstWhere(
      (m) => m.name == val,
      orElse: () => ThemeMode.dark,
    );
  }

  // --- Chat Sessions ---

  Future<void> saveChatSessions(List<ChatSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_keyChatSessions, json.encode(jsonList));
  }

  Future<List<ChatSession>> loadChatSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyChatSessions);
    if (raw == null || raw.isEmpty) return [];
    final list = json.decode(raw) as List;
    return list
        .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearChatSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyChatSessions);
  }

  // --- System Prompt ---

  Future<void> saveSystemPrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySystemPrompt, prompt);
  }

  Future<String> loadSystemPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySystemPrompt) ?? '';
  }
}
