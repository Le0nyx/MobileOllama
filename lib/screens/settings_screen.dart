import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/model_selector.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _systemPromptController;
  bool _obscureApiKey = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _systemPromptController = TextEditingController(text: settings.systemPrompt);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final settings = context.read<SettingsProvider>();
    setState(() => _isTesting = true);

    // Save the key first.
    await settings.setApiKey(_apiKeyController.text.trim());

    final success = await settings.testConnection();

    if (!mounted) return;
    setState(() => _isTesting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Connection successful!'
            : 'Connection failed. Check your API key.'),
        backgroundColor: success ? Colors.green[700] : Colors.red[700],
      ),
    );

    if (success) {
      await settings.refreshModels();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF343541) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF343541) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        title: const Text('Settings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- API Key Section ---
          _buildSectionHeader('API Configuration'),
          const SizedBox(height: 8),
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureApiKey,
                  decoration: InputDecoration(
                    labelText: 'Ollama API Key',
                    hintText: 'Enter your API key',
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(_obscureApiKey
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscureApiKey = !_obscureApiKey),
                        ),
                      ],
                    ),
                  ),
                  onChanged: (val) => settings.setApiKey(val.trim()),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.wifi_tethering),
                    label:
                        Text(_isTesting ? 'Testing...' : 'Test Connection'),
                    onPressed: _isTesting ? null : _testConnection,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Model Selection ---
          _buildSectionHeader('Model'),
          const SizedBox(height: 8),
          _buildCard(
            isDark: isDark,
            child: ModelSelector(
              models: settings.availableModels,
              selectedModel: settings.selectedModel,
              isLoading: settings.isLoadingModels,
              onRefresh: () => settings.refreshModels(),
              onChanged: (model) => settings.setSelectedModel(model),
            ),
          ),
          const SizedBox(height: 24),

          // --- System Prompt ---
          _buildSectionHeader('System Prompt'),
          const SizedBox(height: 8),
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This message is sent at the start of every conversation to set the AI\'s behavior.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _systemPromptController,
                  maxLines: 5,
                  minLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g. You are a helpful coding assistant. Always respond concisely.',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => settings.setSystemPrompt(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Theme ---
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 8),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                _buildThemeOption(settings, ThemeMode.system, 'System',
                    Icons.brightness_auto),
                const Divider(height: 1),
                _buildThemeOption(
                    settings, ThemeMode.light, 'Light', Icons.light_mode),
                const Divider(height: 1),
                _buildThemeOption(
                    settings, ThemeMode.dark, 'Dark', Icons.dark_mode),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- About ---
          _buildSectionHeader('About'),
          const SizedBox(height: 8),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('MobileOllama'),
                  subtitle: const Text('v1.0.0'),
                  dense: true,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('API Endpoint'),
                  subtitle: const Text('https://ollama.com/api'),
                  dense: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCard({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF40414F) : const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildThemeOption(
      SettingsProvider settings, ThemeMode mode, String label, IconData icon) {
    final isSelected = settings.themeMode == mode;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () => settings.setThemeMode(mode),
      dense: true,
    );
  }
}
