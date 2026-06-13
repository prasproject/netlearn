/// NetLearn — Quiz Model
/// Supports Pre-Test, Checkpoint, and Final Quiz types.
class QuizModel {
  final String id;
  final QuizType type;
  final String? unitId;
  final String title;
  final int timeLimitSeconds;
  final List<QuizQuestion> questions;
  final int xpReward;

  const QuizModel({
    required this.id,
    required this.type,
    this.unitId,
    required this.title,
    required this.timeLimitSeconds,
    required this.questions,
    this.xpReward = 10,
  });

  int get totalQuestions => questions.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'unitId': unitId,
        'title': title,
        'timeLimitSeconds': timeLimitSeconds,
        'questions': questions.map((q) => q.toJson()).toList(),
        'xpReward': xpReward,
      };

  factory QuizModel.fromJson(Map<String, dynamic> json) => QuizModel(
        id: json['id'] as String,
        type: QuizType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => QuizType.checkpoint,
        ),
        unitId: json['unitId'] as String?,
        title: json['title'] as String,
        timeLimitSeconds: json['timeLimitSeconds'] as int,
        questions: (json['questions'] as List)
            .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
            .toList(),
        xpReward: json['xpReward'] as int? ?? 10,
      );
}

/// A single quiz question with multiple choice options.
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? imageBase64;
  final String? explanation;
  final String? topic;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.imageBase64,
    this.explanation,
    this.topic,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'imageBase64': imageBase64,
        'explanation': explanation,
        'topic': topic,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        question: json['question'] as String,
        options: (json['options'] as List).cast<String>(),
        correctIndex: json['correctIndex'] as int,
        imageBase64: json['imageBase64'] as String?,
        explanation: json['explanation'] as String?,
        topic: json['topic'] as String?,
      );
}

/// Quiz type enum
enum QuizType {
  pretest,
  posttest,
  checkpoint,
  finalQuiz,
}
