import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ollama_model.dart';

class OllamaApiService {
  static const String defaultBaseUrl = 'https://ollama.com/api';

  Map<String, String> _headers(String apiKey) => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  /// Test the connection by fetching models.
  Future<bool> testConnection(String apiKey, {String? baseUrl}) async {
    final url = baseUrl ?? defaultBaseUrl;
    try {
      final response = await http
          .get(Uri.parse('$url/tags'), headers: _headers(apiKey))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetch available models from the Ollama API.
  Future<List<OllamaModel>> fetchModels(String apiKey, {String? baseUrl}) async {
    final url = baseUrl ?? defaultBaseUrl;
    final response = await http
        .get(Uri.parse('$url/tags'), headers: _headers(apiKey))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch models (${response.statusCode})');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final models = data['models'] as List? ?? [];
    return models
        .map((m) => OllamaModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Send a chat message and stream the response token-by-token.
  ///
  /// Returns a [Stream] of content chunks (strings).
  Stream<String> sendMessageStream({
    required String apiKey,
    required String model,
    required List<Map<String, dynamic>> messages,
    String? baseUrl,
  }) async* {
    final url = baseUrl ?? defaultBaseUrl;
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('$url/chat'));
      request.headers.addAll(_headers(apiKey));
      request.body = json.encode({
        'model': model,
        'messages': messages,
        'stream': true,
      });

      // Allow up to 5 minutes for reasoning models (e.g. DeepSeek-R1)
      // that think before responding.
      final streamedResponse = await client
          .send(request)
          .timeout(const Duration(minutes: 5));

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        throw Exception('API error (${streamedResponse.statusCode}): $body');
      }

      bool gotContent = false;
      String? errorMessage;

      // Ollama streams newline-delimited JSON objects.
      String buffer = '';
      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;
        // Split on newlines — each line is a JSON object.
        while (buffer.contains('\n')) {
          final idx = buffer.indexOf('\n');
          final line = buffer.substring(0, idx).trim();
          buffer = buffer.substring(idx + 1);

          if (line.isEmpty) continue;

          try {
            final obj = json.decode(line) as Map<String, dynamic>;

            // Check for error in the response.
            if (obj.containsKey('error')) {
              errorMessage = obj['error'] as String? ?? 'Unknown API error';
              throw Exception(errorMessage);
            }

            final message = obj['message'] as Map<String, dynamic>?;
            if (message != null) {
              final content = message['content'] as String? ?? '';
              if (content.isNotEmpty) {
                gotContent = true;
                yield content;
              }
            }
            if (obj['done'] == true) {
              if (!gotContent) {
                throw Exception(
                    'Model returned an empty response. This model may not '
                    'be supported or may require a different configuration.');
              }
              return;
            }
          } catch (e) {
            if (e is Exception &&
                (e.toString().contains('API error') ||
                    e.toString().contains('Model returned') ||
                    e.toString().contains(errorMessage ?? ''))) {
              rethrow;
            }
            // Skip malformed JSON lines.
          }
        }
      }

      // Process any remaining data in the buffer.
      if (buffer.trim().isNotEmpty) {
        try {
          final obj = json.decode(buffer.trim()) as Map<String, dynamic>;
          if (obj.containsKey('error')) {
            throw Exception(
                obj['error'] as String? ?? 'Unknown API error');
          }
          final message = obj['message'] as Map<String, dynamic>?;
          if (message != null) {
            final content = message['content'] as String? ?? '';
            if (content.isNotEmpty) {
              gotContent = true;
              yield content;
            }
          }
        } catch (e) {
          if (e is Exception &&
              (e.toString().contains('API error') ||
                  e.toString().contains('Model returned'))) {
            rethrow;
          }
        }
      }

      if (!gotContent) {
        throw Exception(
            'No response received from model "$model". '
            'The model may not support this request or may have timed out.');
      }
    } finally {
      client.close();
    }
  }
}
