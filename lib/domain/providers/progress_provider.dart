import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/progress_model.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/seed/seed_data.dart';
import '../services/ngain_calculator.dart';
import 'auth_provider.dart';
import 'repository_providers.dart';

/// Progress tracking state
class ProgressState {
  final List<ProgressModel> unitProgress;
  final int overallPretestScore;
  final int overallPosttestScore;
  final List<AchievementModel> achievements;

  const ProgressState({
    this.unitProgress = const [],
    this.overallPretestScore = 0,
    this.overallPosttestScore = 0,
    this.achievements = const [],
  });

  /// Total units completed
  int get completedUnits => unitProgress.where((p) => p.isCompleted).length;

  /// Overall completion percentage
  double get overallProgress {
    if (unitProgress.isEmpty) return 0;
    final total = unitProgress.fold<int>(0, (sum, p) => sum + p.totalMaterials);
    final done = unitProgress.fold<int>(0, (sum, p) => sum + p.materialsCompleted);
    return total > 0 ? done / total : 0;
  }

  /// N-Gain calculation
  double get nGain => NGainCalculator.calculate(
    preScore: overallPretestScore,
    postScore: overallPosttestScore,
  );

  String get nGainCategory => NGainCalculator.getCategory(nGain);

  ProgressState copyWith({
    List<ProgressModel>? unitProgress,
    int? overallPretestScore,
    int? overallPosttestScore,
    List<AchievementModel>? achievements,
  }) {
    return ProgressState(
      unitProgress: unitProgress ?? this.unitProgress,
      overallPretestScore: overallPretestScore ?? this.overallPretestScore,
      overallPosttestScore: overallPosttestScore ?? this.overallPosttestScore,
      achievements: achievements ?? this.achievements,
    );
  }
}

class ProgressNotifier extends StateNotifier<ProgressState> {
  final ProgressRepository _repo;
  final String _userId;
  static const String _overallUnitId = '__overall__';
  static const String _badgeQuiz = 'badge-quiz';
  static const String _badgeSimulation = 'badge-simulasi';

  ProgressNotifier(this._repo, this._userId) : super(const ProgressState()) {
    // Don't load or write progress without a valid authenticated user id.
    if (_userId.trim().isEmpty) return;
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    if (_userId.trim().isEmpty) return;
    final all = await _repo.getProgress(_userId);
    final achievements = await _repo.getAchievements(_userId);

    // Extract overall quiz meta (pre/post) stored under a special unitId.
    final overall = all.cast<ProgressModel?>().firstWhere(
          (p) => p?.unitId == _overallUnitId,
          orElse: () => null,
        );

    final unitProgress = all.where((p) => p.unitId != _overallUnitId).toList();

    state = state.copyWith(
      unitProgress: unitProgress,
      overallPretestScore: overall?.pretestScore ?? state.overallPretestScore,
      // Use `finalScore` as persisted overall post-test score.
      overallPosttestScore: overall?.finalScore ?? state.overallPosttestScore,
      achievements: achievements,
    );

    await _syncUnitBadgesFromProgress(unitProgress);
  }

  void updateUnitProgress(String unitId, ProgressModel progress) {
    if (_userId.trim().isEmpty) return;
    final updated = state.unitProgress.map((p) {
      if (p.unitId == unitId) return progress;
      return p;
    }).toList();
    state = state.copyWith(unitProgress: updated);
    _repo.saveProgress(_userId, progress);
  }

  void completeMaterial(String unitId) {
    _completeMaterial(unitId);
  }

  Future<void> _completeMaterial(String unitId) async {
    if (_userId.trim().isEmpty) return;
    ProgressModel? changed;
    final updated = state.unitProgress.map((p) {
      if (p.unitId != unitId) return p;
      if (p.materialsCompleted >= p.totalMaterials) return p;

      final nextCompleted = p.materialsCompleted + 1;
      final becameCompleted = nextCompleted >= p.totalMaterials && !p.isCompleted;
      changed = p.copyWith(
        materialsCompleted: nextCompleted,
        completedAt: becameCompleted ? DateTime.now() : p.completedAt,
      );
      return changed!;
    }).toList();

    state = state.copyWith(unitProgress: updated);
    if (changed != null) {
      await _repo.saveProgress(_userId, changed!);
      if (changed!.isCompleted) {
        await _unlockBadge(_badgeUnitForUnitId(unitId));
      }
    }
  }

  void savePretestScore(int score) {
    if (_userId.trim().isEmpty) return;
    state = state.copyWith(overallPretestScore: score);
    _repo.saveQuizScore(_userId, _overallUnitId, pretestScore: score);
  }

  void savePosttestScore(int score) {
    if (_userId.trim().isEmpty) return;
    state = state.copyWith(overallPosttestScore: score);
    _repo.saveQuizScore(_userId, _overallUnitId, finalScore: score);
  }

  Future<void> saveUnitQuizScore({
    required String unitId,
    required String quizType,
    required int scorePercent,
  }) async {
    if (_userId.trim().isEmpty) return;
    // Persist to DB first (authoritative record).
    if (quizType == 'Pre-Test') {
      await _repo.saveQuizScore(_userId, _overallUnitId, pretestScore: scorePercent);
      state = state.copyWith(overallPretestScore: scorePercent);
      return;
    }

    if (quizType == 'Post-Test') {
      await _repo.saveQuizScore(_userId, _overallUnitId, finalScore: scorePercent);
      state = state.copyWith(overallPosttestScore: scorePercent);
      return;
    }

    if (quizType == 'Checkpoint') {
      await _repo.saveQuizScore(_userId, unitId, checkpointScore: scorePercent);
    } else {
      // Treat everything else as a final quiz score.
      await _repo.saveQuizScore(_userId, unitId, finalScore: scorePercent);
    }

    // Update local state to match the write without re-fetching.
    final updated = state.unitProgress.map((p) {
      if (p.unitId != unitId) return p;
      if (quizType == 'Checkpoint') {
        return p.copyWith(checkpointScores: [...p.checkpointScores, scorePercent]);
      }
      return p.copyWith(finalScore: scorePercent);
    }).toList();
    state = state.copyWith(unitProgress: updated);

    if (quizType == 'Quiz' || quizType == 'Checkpoint') {
      await _unlockBadge(_badgeQuiz);
    }
  }

  void completeSimulation() {
    _unlockBadge(_badgeSimulation);
  }

  String _badgeUnitForUnitId(String unitId) {
    final map = <String, String>{
      'unit-1': 'badge-materi-1',
      'unit-2': 'badge-materi-2',
      'unit-3': 'badge-materi-3',
      'unit-4': 'badge-materi-4',
      'unit-5': 'badge-materi-5',
    };
    return map[unitId] ?? '';
  }

  Future<void> _syncUnitBadgesFromProgress(List<ProgressModel> unitProgress) async {
    for (final p in unitProgress) {
      if (!p.isCompleted) continue;
      final badgeId = _badgeUnitForUnitId(p.unitId);
      if (badgeId.isEmpty) continue;
      await _unlockBadge(badgeId);
    }
  }

  /// Hapus semua progress & badge, kembali ke kondisi akun baru.
  Future<void> resetAllLearningData() async {
    if (_userId.trim().isEmpty) return;
    await _repo.resetAllProgress(_userId);
    await _loadProgress();
  }

  /// Buka semua kunci menu (Pre-Test, Materi, Simulasi, Progress, Post-Test, semua unit).
  Future<void> unlockAllMenus() async {
    if (_userId.trim().isEmpty) return;

    await _repo.saveQuizScore(_userId, _overallUnitId, pretestScore: 100);
    await _repo.saveQuizScore(_userId, _overallUnitId, finalScore: 100);

    final now = DateTime.now();
    for (final m in SeedData.materials) {
      await _repo.saveProgress(
        _userId,
        ProgressModel(
          unitId: m.id,
          materialsCompleted: m.totalSlides,
          totalMaterials: m.totalSlides,
          completedAt: now,
        ),
      );
    }

    final achievements = await _repo.getAchievements(_userId);
    for (final a in achievements) {
      if (!a.isUnlocked) {
        await _repo.unlockAchievement(_userId, a.id);
      }
    }

    await _loadProgress();
  }

  Future<void> _unlockBadge(String badgeId) async {
    if (_userId.trim().isEmpty) return;
    if (badgeId.isEmpty) return;
    final idx = state.achievements.indexWhere((a) => a.id == badgeId);
    if (idx < 0) return;
    if (state.achievements[idx].isUnlocked) return;

    final now = DateTime.now();
    final current = List<AchievementModel>.from(state.achievements);
    final existing = current[idx];
    current[idx] = AchievementModel(
      id: existing.id,
      name: existing.name,
      description: existing.description,
      iconEmoji: existing.iconEmoji,
      tier: existing.tier,
      isUnlocked: true,
      unlockedAt: now,
    );
    state = state.copyWith(achievements: current);
    await _repo.unlockAchievement(_userId, badgeId);
  }
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, ProgressState>((ref) {
  final userId = ref.watch(authProvider).user?.id ?? '';
  return ProgressNotifier(ref.watch(progressRepositoryProvider), userId);
});
