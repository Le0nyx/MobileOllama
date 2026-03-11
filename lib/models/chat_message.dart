class ChatMessage {
  final String role; // 'user', 'assistant', 'system'
  String content;
  final List<String>? images; // base64 encoded images
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    this.images,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        if (images != null && images!.isNotEmpty) 'images': images,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] as String,
        content: json['content'] as String,
        images: json['images'] != null
            ? List<String>.from(json['images'] as List)
            : null,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  /// Build the payload for the Ollama API (no timestamp).
  Map<String, dynamic> toApiPayload() => {
        'role': role,
        'content': content,
        if (images != null && images!.isNotEmpty) 'images': images,
      };
}
