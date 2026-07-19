import '../../models/progress_model.dart';
import '../../models/reflection_model.dart';
import '../../seed/seed_data.dart';
import '../progress_repository.dart';

/// Mock progress repository — uses SeedData.
class MockProgressRepository implements ProgressRepository {
  final List<ProgressModel> _progress = List.from(SeedData.demoProgress);
  final List<AchievementModel> _achievements = List.from(SeedData.achievements);
  ReflectionModel? _reflection;

  @override
  Future<List<ProgressModel>> getProgress(String userId) async => _progress;

  @override
  Future<void> saveProgress(String userId, ProgressModel progress) async {
    final idx = _progress.indexWhere((p) => p.unitId == progress.unitId);
    if (idx >= 0) {
      _progress[idx] = progress;
    } else {
      _progress.add(progress);
    }
  }

  @override
  Future<void> saveQuizScore(String userId, String unitId,
      {int? pretestScore, int? checkpointScore, int? finalScore, int? practiceScore}) async {
    final idx = _progress.indexWhere((p) => p.unitId == unitId);
    if (idx >= 0) {
      var p = _progress[idx];
      if (pretestScore != null) p = p.copyWith(pretestScore: pretestScore);
      if (checkpointScore != null) {
        p = p.copyWith(checkpointScores: [...p.checkpointScores, checkpointScore]);
      }
      if (finalScore != null) p = p.copyWith(finalScore: finalScore);
      if (practiceScore != null) p = p.copyWith(practiceScore: practiceScore);
      _progress[idx] = p;
    }
  }

  @override
  Future<List<AchievementModel>> getAchievements(String userId) async => _achievements;

  @override
  Future<void> resetAllProgress(String userId) async {
    _progress
      ..clear()
      ..addAll(
        SeedData.materials.map(
          (m) => ProgressModel(unitId: m.id, totalMaterials: m.totalSlides),
        ),
      );
    _achievements
      ..clear()
      ..addAll(SeedData.achievements);
    _reflection = null;
  }

  @override
  Future<void> unlockAchievement(String userId, String achievementId) async {
    final idx = _achievements.indexWhere((a) => a.id == achievementId);
    if (idx < 0) return;
    final current = _achievements[idx];
    if (current.isUnlocked) return;
    _achievements[idx] = AchievementModel(
      id: current.id,
      name: current.name,
      description: current.description,
      iconEmoji: current.iconEmoji,
      tier: current.tier,
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
  }

  @override
  Future<ReflectionModel?> getReflection(String userId) async => _reflection;

  @override
  Future<void> saveReflection(String userId, ReflectionModel reflection) async {
    _reflection = reflection;
  }
}
