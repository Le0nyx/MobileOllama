import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: _isUser
          ? (isDark ? const Color(0xFF2A2B32) : Colors.white)
          : (isDark ? const Color(0xFF343541) : const Color(0xFFF7F7F8)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _isUser
                  ? theme.colorScheme.primary
                  : const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _isUser ? Icons.person : Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show images if present
                if (message.images != null && message.images!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.images!.map((img) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(img),
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.broken_image,
                              size: 48,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                // Text content with basic code block highlighting
                _buildContent(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final text = message.content;

    // Simple code block detection: split on ``` markers
    final codeBlockPattern = RegExp(r'```(\w*)\n?([\s\S]*?)```');
    final matches = codeBlockPattern.allMatches(text).toList();

    if (matches.isEmpty) {
      return SelectableText(
        text,
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
      );
    }

    final widgets = <Widget>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Text before code block
      if (match.start > lastEnd) {
        widgets.add(SelectableText(
          text.substring(lastEnd, match.start),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
        ));
      }

      // Code block
      final lang = match.group(1) ?? '';
      final code = match.group(2) ?? '';
      widgets.add(_buildCodeBlock(context, code.trimRight(), lang));

      lastEnd = match.end;
    }

    // Text after last code block
    if (lastEnd < text.length) {
      widgets.add(SelectableText(
        text.substring(lastEnd),
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildCodeBlock(BuildContext context, String code, String language) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D2D2D)
                    : const Color(0xFFE8E8E8),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Text(
                language,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
