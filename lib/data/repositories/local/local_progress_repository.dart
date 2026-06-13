import 'package:get_storage/get_storage.dart';
import '../../models/progress_model.dart';
import '../progress_repository.dart';

import '../../seed/seed_data.dart';

/// GetStorage (GetX Local Storage) implementation of ProgressRepository
/// Used for offline caching.
class LocalProgressRepository implements ProgressRepository {
  final GetStorage _box = GetStorage();
  
  // Storage keys
  static const String _keyProgress = 'netlearn_progress_';
  static const String _keyAchievements = 'netlearn_achievements_';

  @override
  Future<List<ProgressModel>> getProgress(String userId) async {
    final List<dynamic>? dataList = _box.read('$_keyProgress$userId');
    if (dataList == null) {
      // Seed initial data if empty
      await _box.write('$_keyProgress$userId', SeedData.demoProgress.map((p) => p.toJson()).toList());
      return SeedData.demoProgress;
    }
    
    return dataList
        .map((json) => ProgressModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  @override
  Future<void> saveProgress(String userId, ProgressModel progress) async {
    final List<ProgressModel> currentProgress = await getProgress(userId);
    
    final index = currentProgress.indexWhere((p) => p.unitId == progress.unitId);
    if (index >= 0) {
      currentProgress[index] = progress;
    } else {
      currentProgress.add(progress);
    }

    await _box.write(
      '$_keyProgress$userId', 
      currentProgress.map((p) => p.toJson()).toList(),
    );
  }

  @override
  Future<void> saveQuizScore(
    String userId,
    String unitId, {
    int? pretestScore,
    int? checkpointScore,
    int? finalScore,
  }) async {
    final List<ProgressModel> currentProgress = await getProgress(userId);
    final index = currentProgress.indexWhere((p) => p.unitId == unitId);
    
    if (index >= 0) {
      var p = currentProgress[index];
      if (pretestScore != null) p = p.copyWith(pretestScore: pretestScore);
      if (checkpointScore != null) {
        p = p.copyWith(checkpointScores: [...p.checkpointScores, checkpointScore]);
      }
      if (finalScore != null) p = p.copyWith(finalScore: finalScore);
      currentProgress[index] = p;
    } else {
      // Fallback if not started yet
      currentProgress.add(
        ProgressModel(
          unitId: unitId,
          totalMaterials: 5, // fallback
          pretestScore: pretestScore,
          checkpointScores: checkpointScore != null ? [checkpointScore] : [],
          finalScore: finalScore,
        )
      );
    }

    await _box.write(
      '$_keyProgress$userId', 
      currentProgress.map((p) => p.toJson()).toList(),
    );
  }

  @override
  Future<List<AchievementModel>> getAchievements(String userId) async {
    final List<dynamic>? dataList = _box.read('$_keyAchievements$userId');
    if (dataList == null) {
      // Seed initial data
      await _box.write('$_keyAchievements$userId', SeedData.achievements.map((a) => a.toJson()).toList());
      return SeedData.achievements;
    }
    
    return dataList
        .map((json) => AchievementModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  @override
  Future<void> resetAllProgress(String userId) async {
    final freshProgress = SeedData.materials
        .map((m) => ProgressModel(unitId: m.id, totalMaterials: m.totalSlides))
        .toList();
    await _box.write(
      '$_keyProgress$userId',
      freshProgress.map((p) => p.toJson()).toList(),
    );
    await _box.write(
      '$_keyAchievements$userId',
      SeedData.achievements.map((a) => a.toJson()).toList(),
    );
  }

  @override
  Future<void> unlockAchievement(String userId, String achievementId) async {
    final List<AchievementModel> current = await getAchievements(userId);
    final index = current.indexWhere((a) => a.id == achievementId);
    
    if (index >= 0) {
      final updated = AchievementModel(
        id: current[index].id,
        name: current[index].name,
        description: current[index].description,
        iconEmoji: current[index].iconEmoji,
        tier: current[index].tier,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      current[index] = updated;
      
      await _box.write(
        '$_keyAchievements$userId', 
        current.map((a) => a.toJson()).toList(),
      );
    }
  }
}
