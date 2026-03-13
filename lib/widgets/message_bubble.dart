import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  bool get _isUser => message.role == 'user';

  Future<void> _copyMessageAsMarkdown(BuildContext context) async {
    final roleTitle = _isUser ? 'User' : 'Assistant';
    final markdown = StringBuffer()
      ..writeln('### $roleTitle')
      ..writeln()
      ..writeln(message.content.trim());

    if (message.images != null && message.images!.isNotEmpty) {
      markdown
        ..writeln()
        ..writeln('_Attached images: ${message.images!.length}_');
    }

    await Clipboard.setData(ClipboardData(text: markdown.toString().trim()));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message copied as Markdown')),
      );
    }
  }

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
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => _copyMessageAsMarkdown(context),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    splashRadius: 18,
                    tooltip: 'Copy markdown',
                    visualDensity: VisualDensity.compact,
                  ),
                ),
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
                // Render content: markdown for assistant, plain text for user
                _isUser
                    ? SelectableText(
                        message.content,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                      )
                    : _buildMarkdownContent(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyLarge?.copyWith(
          height: 1.6,
          color: isDark ? Colors.grey[200] : Colors.grey[900],
        ),
        h1: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
        h2: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
        h3: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: isDark ? const Color(0xFFE06C75) : const Color(0xFFC7254E),
          backgroundColor:
              isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF0F0F0),
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        codeblockAlign: WrapAlignment.start,
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              width: 3,
            ),
          ),
        ),
        blockquotePadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        listBullet: theme.textTheme.bodyLarge?.copyWith(
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
        tableHead: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
        tableBody: TextStyle(
          color: isDark ? Colors.grey[200] : Colors.grey[900],
        ),
        tableBorder: TableBorder.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
        ),
        a: TextStyle(
          color: isDark ? const Color(0xFF82AAFF) : const Color(0xFF1976D2),
          decoration: TextDecoration.underline,
        ),
        strong: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
        em: TextStyle(
          fontStyle: FontStyle.italic,
          color: isDark ? Colors.grey[200] : Colors.grey[800],
        ),
      ),
    );
  }
}
