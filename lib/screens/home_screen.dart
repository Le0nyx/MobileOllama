import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/chat_history_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final historyProvider = context.read<ChatHistoryProvider>();

    // Scroll to bottom whenever messages change.
    if (chatProvider.messages.isNotEmpty) {
      _scrollToBottom();
    }

    // Show error if any.
    if (chatProvider.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chatProvider.error!),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        chatProvider.clearError();
      });
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF343541) : Colors.white,
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.5,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF343541) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text(
          settings.selectedModel.isNotEmpty
              ? settings.selectedModel
              : 'MobileOllama',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      drawer: const ChatHistoryDrawer(),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: chatProvider.messages.isEmpty
                ? _buildWelcomeState(context, isDark)
                : _buildMessageList(chatProvider),
          ),
          // Input
          ChatInput(
            isStreaming: chatProvider.isStreaming,
            enabled: settings.hasApiKey,
            onSend: (text, images) async {
              await chatProvider.sendMessage(
                text: text,
                apiKey: settings.apiKey,
                model: settings.selectedModel,
                images: images,
                systemPrompt: settings.systemPrompt,
              );
              // Auto-save session to history.
              if (chatProvider.currentSession != null) {
                historyProvider.saveSession(chatProvider.currentSession!);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatProvider chatProvider) {
    // Filter out the empty assistant placeholder while streaming.
    final visibleMessages = chatProvider.messages
        .where((m) =>
            m.role != 'assistant' ||
            m.content.isNotEmpty ||
            !chatProvider.isStreaming)
        .toList();

    // Show typing indicator when streaming and assistant has no content yet.
    final showTyping = chatProvider.isStreaming &&
        chatProvider.messages.isNotEmpty &&
        chatProvider.messages.last.role == 'assistant' &&
        chatProvider.messages.last.content.isEmpty;

    return ListView.builder(
      controller: _scrollController,
      itemCount: visibleMessages.length + (showTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= visibleMessages.length) {
          return const TypingIndicator();
        }
        return MessageBubble(message: visibleMessages[index]);
      },
    );
  }

  Widget _buildWelcomeState(BuildContext context, bool isDark) {
    final settings = context.read<SettingsProvider>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 64,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'MobileOllama',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              settings.hasApiKey
                  ? 'Start a conversation by typing a message below.'
                  : 'Set your API key in Settings to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[500],
              ),
            ),
            if (!settings.hasApiKey) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
