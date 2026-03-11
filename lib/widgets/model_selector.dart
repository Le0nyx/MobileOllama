import 'package:flutter/material.dart';
import '../models/ollama_model.dart';

class ModelSelector extends StatelessWidget {
  final List<OllamaModel> models;
  final String selectedModel;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRefresh;

  const ModelSelector({
    super.key,
    required this.models,
    required this.selectedModel,
    required this.onChanged,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Loading models...'),
        ],
      );
    }

    if (models.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No models available'),
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: onRefresh,
              tooltip: 'Refresh models',
            ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: DropdownButton<String>(
            value: models.any((m) => m.name == selectedModel)
                ? selectedModel
                : null,
            isExpanded: false,
            underline: const SizedBox(),
            items: models
                .map((m) => DropdownMenuItem(
                      value: m.name,
                      child: Text(
                        m.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            hint: const Text('Select model'),
          ),
        ),
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: onRefresh,
            tooltip: 'Refresh models',
          ),
      ],
    );
  }
}
