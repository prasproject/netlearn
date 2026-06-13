/// NetLearn — Material Model
/// Represents a learning unit with slides, each containing rich content.
class MaterialModel {
  final String id;
  final int unitNumber;
  final String title;
  final String description;
  final List<MaterialSlide> slides;
  final int order;
  final bool isLocked;
  final String? iconEmoji;

  const MaterialModel({
    required this.id,
    required this.unitNumber,
    required this.title,
    required this.description,
    required this.slides,
    this.order = 0,
    this.isLocked = false,
    this.iconEmoji,
  });

  int get totalSlides => slides.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'unitNumber': unitNumber,
        'title': title,
        'description': description,
        'slides': slides.map((s) => s.toJson()).toList(),
        'order': order,
        'isLocked': isLocked,
        'iconEmoji': iconEmoji,
      };

  factory MaterialModel.fromJson(Map<String, dynamic> json) => MaterialModel(
        id: json['id'] as String,
        unitNumber: json['unitNumber'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
        slides: (json['slides'] as List)
            .map((s) => MaterialSlide.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList(),
        order: json['order'] as int? ?? 0,
        isLocked: json['isLocked'] as bool? ?? false,
        iconEmoji: json['iconEmoji'] as String?,
      );
}

/// A single slide within a material unit.
class MaterialSlide {
  final String title;
  final String content;
  final String? imageBase64;
  final String? imageDescription;
  final String? videoUrl;
  final String? audioUrl;
  final List<String> keywords;

  const MaterialSlide({
    required this.title,
    required this.content,
    this.imageBase64,
    this.imageDescription,
    this.videoUrl,
    this.audioUrl,
    this.keywords = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'imageBase64': imageBase64,
        'imageDescription': imageDescription,
        'videoUrl': videoUrl,
        'audioUrl': audioUrl,
        'keywords': keywords,
      };

  factory MaterialSlide.fromJson(Map<String, dynamic> json) => MaterialSlide(
        title: json['title'] as String,
        content: json['content'] as String,
        imageBase64: json['imageBase64'] as String?,
        imageDescription: json['imageDescription'] as String?,
        videoUrl: json['videoUrl'] as String?,
        audioUrl: json['audioUrl'] as String?,
        keywords: (json['keywords'] as List?)?.cast<String>() ?? [],
      );
}
