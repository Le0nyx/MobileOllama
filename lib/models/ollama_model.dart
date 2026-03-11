class OllamaModel {
  final String name;
  final String? size;
  final String? modifiedAt;

  OllamaModel({
    required this.name,
    this.size,
    this.modifiedAt,
  });

  factory OllamaModel.fromJson(Map<String, dynamic> json) => OllamaModel(
        name: json['name'] as String? ?? json['model'] as String,
        size: json['size']?.toString(),
        modifiedAt: json['modified_at'] as String?,
      );

  @override
  String toString() => name;
}
