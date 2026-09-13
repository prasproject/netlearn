/// NetLearn — Progress Model
/// Tracks per-unit learning progress and quiz scores.
class ProgressModel {
  final String unitId;
  final int materialsCompleted;
  final int totalMaterials;
  final int? pretestScore;
  final List<int> checkpointScores;
  final int? finalScore;
  final DateTime? completedAt;
  final List<int> bookmarkedSlides;
  final int? practiceScore;

  const ProgressModel({
    required this.unitId,
    this.materialsCompleted = 0,
    required this.totalMaterials,
    this.pretestScore,
    this.checkpointScores = const [],
    this.finalScore,
    this.completedAt,
    this.bookmarkedSlides = const [],
    this.practiceScore,
  });

  /// Whether all materials in this unit are completed
  bool get isCompleted => materialsCompleted >= totalMaterials;

  /// Apakah latihan quiz unit ini sudah dikerjakan.
  bool get hasPracticeCompleted => practiceScore != null;

  /// Whether user has completed at least one checkpoint attempt for this unit.
  bool get hasCheckpointAttempt => checkpointScores.isNotEmpty;

  /// Material completion percentage (0.0 to 1.0)
  double get materialProgress =>
      totalMaterials > 0 ? materialsCompleted / totalMaterials : 0.0;

  /// Whether the unit is in-progress (started but not completed)
  bool get isInProgress => materialsCompleted > 0 && !isCompleted;

  /// Average checkpoint score (nullable)
  int? get checkpointAverage {
    if (checkpointScores.isEmpty) return null;
    return checkpointScores.reduce((a, b) => a + b) ~/ checkpointScores.length;
  }

  /// Sentinel so `copyWith` can tell "not passed" apart from an explicit `null`.
  /// Without this, a score or completion date can never be cleared and the UI
  /// keeps showing a stale value after a reset.
  static const Object _unset = Object();

  ProgressModel copyWith({
    int? materialsCompleted,
    int? totalMaterials,
    Object? pretestScore = _unset,
    List<int>? checkpointScores,
    Object? finalScore = _unset,
    Object? completedAt = _unset,
    List<int>? bookmarkedSlides,
    Object? practiceScore = _unset,
  }) {
    return ProgressModel(
      unitId: unitId,
      materialsCompleted: materialsCompleted ?? this.materialsCompleted,
      totalMaterials: totalMaterials ?? this.totalMaterials,
      pretestScore: identical(pretestScore, _unset)
          ? this.pretestScore
          : pretestScore as int?,
      checkpointScores: checkpointScores ?? this.checkpointScores,
      finalScore:
          identical(finalScore, _unset) ? this.finalScore : finalScore as int?,
      completedAt: identical(completedAt, _unset)
          ? this.completedAt
          : completedAt as DateTime?,
      bookmarkedSlides: bookmarkedSlides ?? this.bookmarkedSlides,
      practiceScore: identical(practiceScore, _unset)
          ? this.practiceScore
          : practiceScore as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'unitId': unitId,
        'materialsCompleted': materialsCompleted,
        'totalMaterials': totalMaterials,
        'pretestScore': pretestScore,
        'checkpointScores': checkpointScores,
        'finalScore': finalScore,
        'completedAt': completedAt?.toIso8601String(),
        'bookmarkedSlides': bookmarkedSlides,
        'practiceScore': practiceScore,
      };

  /// Payload for a partial (`update`) write.
  ///
  /// Quiz scores are only included when this model actually carries them, so
  /// saving slide progress from a possibly-stale copy can never delete scores
  /// that another flow already wrote to the same node.
  Map<String, dynamic> toUpdateJson() {
    final data = <String, dynamic>{
      'unitId': unitId,
      'materialsCompleted': materialsCompleted,
      'totalMaterials': totalMaterials,
      // `null` deletes the key in RTDB, which is exactly what "not completed"
      // and "no bookmarks" should mean.
      'completedAt': completedAt?.toIso8601String(),
      'bookmarkedSlides': bookmarkedSlides.isEmpty ? null : bookmarkedSlides,
    };
    if (pretestScore != null) data['pretestScore'] = pretestScore;
    if (finalScore != null) data['finalScore'] = finalScore;
    if (practiceScore != null) data['practiceScore'] = practiceScore;
    if (checkpointScores.isNotEmpty) data['checkpointScores'] = checkpointScores;
    return data;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    return switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v) ?? fallback,
      _ => fallback,
    };
  }

  static List<int> _asIntList(dynamic value) {
    if (value is List) {
      return value.map((e) => _asInt(e, fallback: 0)).toList();
    }
    return const [];
  }

  factory ProgressModel.fromJson(Map<String, dynamic> json) => ProgressModel(
        unitId: (json['unitId'] as String?) ?? '',
        materialsCompleted: _asInt(json['materialsCompleted'], fallback: 0),
        // `__overall__` (pre/post-test) entries may not carry material totals.
        totalMaterials: _asInt(json['totalMaterials'], fallback: 0),
        pretestScore: json['pretestScore'] == null ? null : _asInt(json['pretestScore']),
        checkpointScores: _asIntList(json['checkpointScores']),
        finalScore: json['finalScore'] == null ? null : _asInt(json['finalScore']),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        bookmarkedSlides: _asIntList(json['bookmarkedSlides']),
        practiceScore: json['practiceScore'] == null ? null : _asInt(json['practiceScore']),
      );
}

/// NetLearn — Achievement Model
class AchievementModel {
  final String id;
  final String name;
  final String description;
  final String iconEmoji;
  final AchievementTier tier;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    this.iconEmoji = '🏆',
    this.tier = AchievementTier.bronze,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'iconEmoji': iconEmoji,
        'tier': tier.name,
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory AchievementModel.fromJson(Map<String, dynamic> json) =>
      AchievementModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        iconEmoji: json['iconEmoji'] as String? ?? '🏆',
        tier: AchievementTier.values.firstWhere(
          (t) => t.name == json['tier'],
          orElse: () => AchievementTier.bronze,
        ),
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        unlockedAt: json['unlockedAt'] != null
            ? DateTime.parse(json['unlockedAt'] as String)
            : null,
      );
}

enum AchievementTier { bronze, silver, gold, platinum }

/// NetLearn — Certificate Model
class CertificateModel {
  final String id;
  final String userId;
  final String studentName;
  final int finalScore;
  final double nGain;
  final int totalXp;
  final DateTime completionDate;
  final String? pdfUrl;

  const CertificateModel({
    required this.id,
    required this.userId,
    required this.studentName,
    required this.finalScore,
    required this.nGain,
    required this.totalXp,
    required this.completionDate,
    this.pdfUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'studentName': studentName,
        'finalScore': finalScore,
        'nGain': nGain,
        'totalXp': totalXp,
        'completionDate': completionDate.toIso8601String(),
        'pdfUrl': pdfUrl,
      };

  factory CertificateModel.fromJson(Map<String, dynamic> json) =>
      CertificateModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        studentName: json['studentName'] as String,
        finalScore: json['finalScore'] as int,
        nGain: (json['nGain'] as num).toDouble(),
        totalXp: json['totalXp'] as int,
        completionDate: DateTime.parse(json['completionDate'] as String),
        pdfUrl: json['pdfUrl'] as String?,
      );
}

/// NetLearn — Leaderboard Entry
class LeaderboardModel {
  final String userId;
  final String displayName;
  final int score;
  final int xp;
  final DateTime updatedAt;

  const LeaderboardModel({
    required this.userId,
    required this.displayName,
    required this.score,
    required this.xp,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'score': score,
        'xp': xp,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) =>
      LeaderboardModel(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String,
        score: json['score'] as int,
        xp: json['xp'] as int,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
