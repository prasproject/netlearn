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
}
