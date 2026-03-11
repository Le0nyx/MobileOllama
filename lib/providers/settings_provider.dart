import 'package:flutter/material.dart';
import '../models/ollama_model.dart';
import '../services/ollama_api_service.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final OllamaApiService _api = OllamaApiService();

  String _apiKey = '';
  String _selectedModel = '';
  String _systemPrompt = '';
  ThemeMode _themeMode = ThemeMode.dark;
  List<OllamaModel> _availableModels = [];
  bool _isLoadingModels = false;

  String get apiKey => _apiKey;
  String get selectedModel => _selectedModel;
  String get systemPrompt => _systemPrompt;
  ThemeMode get themeMode => _themeMode;
  List<OllamaModel> get availableModels => _availableModels;
  bool get isLoadingModels => _isLoadingModels;
  bool get hasApiKey => _apiKey.isNotEmpty;

  Future<void> init() async {
    _apiKey = await _storage.loadApiKey() ?? '';
    _selectedModel = await _storage.loadSelectedModel() ?? '';
    _systemPrompt = await _storage.loadSystemPrompt();
    _themeMode = await _storage.loadThemeMode();
    notifyListeners();

    if (_apiKey.isNotEmpty) {
      await refreshModels();
    }
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key;
    await _storage.saveApiKey(key);
    notifyListeners();
  }

  Future<void> setSelectedModel(String model) async {
    _selectedModel = model;
    await _storage.saveSelectedModel(model);
    notifyListeners();
  }

  Future<void> setSystemPrompt(String prompt) async {
    _systemPrompt = prompt;
    await _storage.saveSystemPrompt(prompt);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> refreshModels() async {
    if (_apiKey.isEmpty) return;
    _isLoadingModels = true;
    notifyListeners();

    try {
      _availableModels = await _api.fetchModels(_apiKey);
      // If no model is selected yet, pick the first one.
      if (_selectedModel.isEmpty && _availableModels.isNotEmpty) {
        _selectedModel = _availableModels.first.name;
        await _storage.saveSelectedModel(_selectedModel);
      }
    } catch (_) {
      // Models fetch failed — keep existing list.
    } finally {
      _isLoadingModels = false;
      notifyListeners();
    }
  }

  Future<bool> testConnection() async {
    if (_apiKey.isEmpty) return false;
    return _api.testConnection(_apiKey);
  }
}
