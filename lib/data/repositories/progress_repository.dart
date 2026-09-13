import '../models/progress_model.dart';
import '../models/reflection_model.dart';

/// Abstract progress repository.
abstract class ProgressRepository {
  Future<List<ProgressModel>> getProgress(String userId);
  Future<void> saveProgress(String userId, ProgressModel progress);
  Future<void> saveQuizScore(String userId, String unitId, {int? pretestScore, int? checkpointScore, int? finalScore, int? practiceScore});
  Future<List<AchievementModel>> getAchievements(String userId);
  Future<void> unlockAchievement(String userId, String achievementId);
  Future<void> resetAllProgress(String userId);
  Future<ReflectionModel?> getReflection(String userId);
  Future<void> saveReflection(String userId, ReflectionModel reflection);

  /// Live stream of unit progress straight from the backing store.
  ///
  /// Implementations that support realtime (RTDB) override this so the UI can
  /// mirror the database instead of relying on optimistic local state.
  /// Non-realtime implementations keep the default empty stream.
  Stream<List<ProgressModel>> watchProgress(String userId) =>
      const Stream<List<ProgressModel>>.empty();

  /// Live stream of achievements. See [watchProgress].
  Stream<List<AchievementModel>> watchAchievements(String userId) =>
      const Stream<List<AchievementModel>>.empty();

  /// Live stream of the reflection entry. See [watchProgress].
  Stream<ReflectionModel?> watchReflection(String userId) =>
      const Stream<ReflectionModel?>.empty();

  /// Whether this implementation emits realtime updates.
  bool get supportsRealtime => false;
}
