import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_session.dart';
import '../providers/chat_history_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';

class ChatHistoryDrawer extends StatelessWidget {
  const ChatHistoryDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final historyProvider = context.watch<ChatHistoryProvider>();
    final chatProvider = context.read<ChatProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF202123) : const Color(0xFFF9F9F9),
      child: SafeArea(
        child: Column(
          children: [
            // Clear all at the top
            if (historyProvider.sessions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextButton.icon(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red[400], size: 18),
                  label: Text('Clear all chats',
                      style: TextStyle(color: Colors.red[400])),
                  onPressed: () => _showClearConfirmation(context, historyProvider),
                ),
              ),
            const Divider(height: 1),
            // Chat history list — newest at the bottom
            Expanded(
              child: historyProvider.sessions.isEmpty
                  ? Center(
                      child: Text(
                        'No chat history yet',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: historyProvider.sessions.length,
                      itemBuilder: (context, index) {
                        final session = historyProvider.sessions[index];
                        final isActive =
                            chatProvider.currentSession?.id == session.id;

                        return _ChatHistoryTile(
                          session: session,
                          isActive: isActive,
                          onTap: () {
                            chatProvider.loadSession(session);
                            Navigator.pop(context);
                          },
                          onDelete: () {
                            historyProvider.deleteSession(session.id);
                            if (isActive) {
                              chatProvider
                                  .newChat(settingsProvider.selectedModel);
                            }
                          },
                          onRename: () =>
                              _showRenameDialog(context, session, historyProvider),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            // New Chat button at the bottom
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('New Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    side: BorderSide(
                      color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    chatProvider.newChat(settingsProvider.selectedModel);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, ChatSession session,
      ChatHistoryProvider provider) {
    final controller = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Chat title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.renameSession(session.id, controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(
      BuildContext context, ChatHistoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Chats'),
        content:
            const Text('This will permanently delete all chat history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _ChatHistoryTile extends StatelessWidget {
  final ChatSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _ChatHistoryTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      dense: true,
      selected: isActive,
      selectedTileColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
      leading: Icon(
        Icons.chat_bubble_outline,
        size: 18,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      title: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.grey[200] : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        _formatDate(session.createdAt),
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.grey[500] : Colors.grey[500],
        ),
      ),
      onTap: onTap,
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey[500]),
        onPressed: onDelete,
        tooltip: 'Delete chat',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      onLongPress: () => _showContextMenu(context),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                onRename();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
