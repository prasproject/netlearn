/// NetLearn — Reflection Model
/// Captures the learner's self-reflection after completing the Post-Test.
enum UnderstandingLevel {
  sangatPaham,
  paham,
  cukupPaham,
  belumPaham;

  String get label {
    switch (this) {
      case UnderstandingLevel.sangatPaham:
        return 'Sangat Paham';
      case UnderstandingLevel.paham:
        return 'Paham';
      case UnderstandingLevel.cukupPaham:
        return 'Cukup Paham';
      case UnderstandingLevel.belumPaham:
        return 'Belum Paham';
    }
  }
}

class ReflectionModel {
  final UnderstandingLevel understandingLevel;
  final String mostUnderstoodTopic;
  final String needsMoreStudyTopic;
  final DateTime submittedAt;

  const ReflectionModel({
    required this.understandingLevel,
    required this.mostUnderstoodTopic,
    required this.needsMoreStudyTopic,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
        'understandingLevel': understandingLevel.name,
        'mostUnderstoodTopic': mostUnderstoodTopic,
        'needsMoreStudyTopic': needsMoreStudyTopic,
        'submittedAt': submittedAt.toIso8601String(),
      };

  factory ReflectionModel.fromJson(Map<String, dynamic> json) => ReflectionModel(
        understandingLevel: UnderstandingLevel.values.firstWhere(
          (e) => e.name == json['understandingLevel'],
          orElse: () => UnderstandingLevel.paham,
        ),
        mostUnderstoodTopic: (json['mostUnderstoodTopic'] as String?) ?? '',
        needsMoreStudyTopic: (json['needsMoreStudyTopic'] as String?) ?? '',
        submittedAt: json['submittedAt'] != null
            ? DateTime.parse(json['submittedAt'] as String)
            : DateTime.now(),
      );
}
