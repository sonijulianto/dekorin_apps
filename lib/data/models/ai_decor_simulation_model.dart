/// Model hasil simulasi warna dekorasi AI dengan defensive null-safe parsing.
class AiDecorSimulationModel {
  const AiDecorSimulationModel({
    required this.id,
    this.originalUrl = '',
    this.resultUrl = '',
    this.modelName = '',
    this.fabricColor = '',
    this.flowerColor = '',
    this.nuance = '',
    this.notes = '',
    this.aiNote = '',
    this.createdAt = '',
  });

  final String id;
  final String originalUrl;
  final String resultUrl;
  final String modelName;
  final String fabricColor;
  final String flowerColor;
  final String nuance;
  final String notes;
  final String aiNote;
  final String createdAt;

  factory AiDecorSimulationModel.fromJson(Map<String, dynamic> json) {
    return AiDecorSimulationModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      originalUrl: json['original_url'] as String? ?? '',
      resultUrl: json['result_url'] as String? ?? '',
      modelName: json['model_name'] as String? ?? '',
      fabricColor: json['fabric_color'] as String? ?? '',
      flowerColor: json['flower_color'] as String? ?? '',
      nuance: json['nuance'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      aiNote: json['ai_note'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'original_url': originalUrl,
      'result_url': resultUrl,
      'model_name': modelName,
      'fabric_color': fabricColor,
      'flower_color': flowerColor,
      'nuance': nuance,
      'notes': notes,
      'ai_note': aiNote,
      'created_at': createdAt,
    };
  }
}
