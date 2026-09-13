import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_storage/get_storage.dart';
import '../../models/progress_model.dart';
import '../../models/reflection_model.dart';
import '../progress_repository.dart';
import '../../seed/seed_data.dart';

/// Firebase Realtime Database implementation of ProgressRepository.
class RtdbProgressRepository extends ProgressRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('progress');
  final DatabaseReference _achDb = FirebaseDatabase.instance.ref('achievements');
  final DatabaseReference _reflectionDb = FirebaseDatabase.instance.ref('reflection');
  final _storage = GetStorage();
  static const String _overallUnitId = '__overall__';

  @override
  bool get supportsRealtime => true;

  /// Normalise any RTDB payload (native Map on mobile, JS interop map on web)
  /// into a plain `Map<String, dynamic>`.
  static Map<String, dynamic> _asMap(Object? value) {
    try {
      return Map<String, dynamic>.from(value as Map);
    } catch (_) {
      return Map<String, dynamic>.from(jsonDecode(jsonEncode(value)));
    }
  }

  static List<ProgressModel> _parseProgress(Object? value) {
    final data = _asMap(value);
    return data.entries.map((e) {
      final map = _asMap(e.value);
      map['unitId'] = e.key;
      return ProgressModel.fromJson(map);
    }).toList();
  }

  static List<AchievementModel> _parseAchievements(Object? value) {
    final data = _asMap(value);
    return data.entries.map((e) {
      final map = _asMap(e.value);
      map['id'] = e.key;
      return AchievementModel.fromJson(map);
    }).toList();
  }

  List<ProgressModel> _mergeWithSeedUnits(List<ProgressModel> source) {
    final byId = <String, ProgressModel>{for (final p in source) p.unitId: p};

    // Ensure all curriculum units exist for accurate overall progress.
    final merged = <ProgressModel>[
      for (final m in SeedData.materials)
        () {
          final existing = byId[m.id];
          if (existing == null) {
            return ProgressModel(unitId: m.id, materialsCompleted: 0, totalMaterials: m.totalSlides);
          }
          if (existing.totalMaterials != m.totalSlides) {
            final completed = existing.materialsCompleted.clamp(0, m.totalSlides);
            return existing.copyWith(
              totalMaterials: m.totalSlides,
              materialsCompleted: completed,
              completedAt: completed >= m.totalSlides ? existing.completedAt : null,
            );
          }
          return existing;
        }(),
    ];

    // Preserve special overall quiz meta entry if present.
    final overall = byId[_overallUnitId];
    if (overall != null) merged.add(overall);

    // Also preserve any unknown units (e.g., future content) to avoid dropping data.
    for (final p in source) {
      final isSeedUnit = SeedData.materials.any((m) => m.id == p.unitId);
      if (p.unitId == _overallUnitId) continue;
      if (!isSeedUnit) merged.add(p);
    }

    return merged;
  }

  List<AchievementModel> _mergeAchievementsWithSeed(List<AchievementModel> source) {
    final byId = {for (final a in source) a.id: a};
    return SeedData.achievements
        .map((seed) => SeedData.mergeAchievement(seed, byId[seed.id]))
        .toList();
  }

  void _cacheProgress(String userId, List<ProgressModel> merged) {
    _storage.write('progress_$userId', merged.map((e) => e.toJson()).toList());
  }

  void _cacheAchievements(String userId, List<AchievementModel> merged) {
    _storage.write('achievements_$userId', merged.map((e) => e.toJson()).toList());
  }

  // ─── Realtime streams (database is the source of truth) ───

  @override
  Stream<List<ProgressModel>> watchProgress(String userId) {
    if (userId.trim().isEmpty) return const Stream<List<ProgressModel>>.empty();
    return _db.child(userId).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return _mergeWithSeedUnits(const []);
      }
      final merged = _mergeWithSeedUnits(_parseProgress(snapshot.value));
      _cacheProgress(userId, merged);
      return merged;
    });
  }

  @override
  Stream<List<AchievementModel>> watchAchievements(String userId) {
    if (userId.trim().isEmpty) {
      return const Stream<List<AchievementModel>>.empty();
    }
    return _achDb.child(userId).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return _mergeAchievementsWithSeed(const []);
      }
      final merged = _mergeAchievementsWithSeed(_parseAchievements(snapshot.value));
      _cacheAchievements(userId, merged);
      return merged;
    });
  }

  @override
  Stream<ReflectionModel?> watchReflection(String userId) {
    if (userId.trim().isEmpty) return const Stream<ReflectionModel?>.empty();
    return _reflectionDb.child(userId).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return null;
      final data = _asMap(snapshot.value);
      _storage.write('reflection_$userId', data);
      return ReflectionModel.fromJson(data);
    });
  }

  // ─── One-shot reads (used as the first paint / offline fallback) ───

  @override
  Future<List<ProgressModel>> getProgress(String userId) async {
    try {
      final snapshot = await _db.child(userId).get();
      if (snapshot.exists) {
        final merged = _mergeWithSeedUnits(_parseProgress(snapshot.value));
        _cacheProgress(userId, merged);
        return merged;
      }
    } catch (_) {
      // Fallback to local storage on network error
    }

    // Try reading from local storage (Offline)
    final localData = _storage.read('progress_$userId');
    if (localData != null) {
      try {
        final parsed = (localData as List)
            .map((e) => ProgressModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return _mergeWithSeedUnits(parsed);
      } catch (_) {}
    }

    // If no data in RTDB and no local cache, generate an empty progress state
    return SeedData.materials
        .map(
          (m) => ProgressModel(
            unitId: m.id,
            materialsCompleted: 0,
            totalMaterials: m.totalSlides,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveProgress(String userId, ProgressModel progress) async {
    // `update` (not `set`) so a partially-filled model can never wipe fields
    // written by another flow — e.g. saving slide progress must not erase quiz
    // scores stored on the same unit node.
    await _db.child(userId).child(progress.unitId).update(progress.toUpdateJson());
    await _syncLocalProgress(userId);
  }

  @override
  Future<void> saveQuizScore(String userId, String unitId, {int? pretestScore, int? checkpointScore, int? finalScore, int? practiceScore}) async {
    final ref = _db.child(userId).child(unitId);
    final snapshot = await ref.get();

    Map<String, dynamic> updateData = {};
    if (pretestScore != null) updateData['pretestScore'] = pretestScore;
    if (finalScore != null) updateData['finalScore'] = finalScore;
    if (practiceScore != null) updateData['practiceScore'] = practiceScore;

    // Ensure the record is parseable by `ProgressModel.fromJson` even for `__overall__`.
    // Some paths only store quiz meta and would otherwise miss required fields.
    if (!snapshot.exists) {
      updateData['unitId'] = unitId;
      updateData['materialsCompleted'] = 0;
      updateData['totalMaterials'] = 0;
    } else {
      try {
        final current = _asMap(snapshot.value);
        if (!current.containsKey('totalMaterials')) {
          updateData['totalMaterials'] = 0;
        }
        if (!current.containsKey('materialsCompleted')) {
          updateData['materialsCompleted'] = 0;
        }
        if (!current.containsKey('unitId')) {
          updateData['unitId'] = unitId;
        }
      } catch (_) {
        // If existing data isn't a Map, fall back to writing minimal fields.
        updateData['unitId'] = unitId;
        updateData['materialsCompleted'] = 0;
        updateData['totalMaterials'] = 0;
      }
    }

    if (checkpointScore != null) {
      if (snapshot.exists) {
        final current = _asMap(snapshot.value);
        List<int> scores = (current['checkpointScores'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            <int>[];
        scores.add(checkpointScore);
        updateData['checkpointScores'] = scores;
      } else {
        updateData['checkpointScores'] = [checkpointScore];
      }
    }

    if (updateData.isNotEmpty) {
      // `update` is fine; it will create the node if missing.
      await ref.update(updateData);
      await _syncLocalProgress(userId);
    }
  }

  Future<void> _syncLocalProgress(String userId) async {
    try {
      final snapshot = await _db.child(userId).get();
      if (snapshot.exists) {
        _cacheProgress(userId, _mergeWithSeedUnits(_parseProgress(snapshot.value)));
      }
    } catch (_) {}
  }

  @override
  Future<List<AchievementModel>> getAchievements(String userId) async {
    try {
      final snapshot = await _achDb.child(userId).get();
      if (snapshot.exists) {
        final merged = _mergeAchievementsWithSeed(_parseAchievements(snapshot.value));
        _cacheAchievements(userId, merged);
        return merged;
      }
    } catch (_) {}

    final localData = _storage.read('achievements_$userId');
    if (localData != null) {
      try {
        final local = (localData as List)
            .map((e) => AchievementModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return _mergeAchievementsWithSeed(local);
      } catch (_) {}
    }

    return _mergeAchievementsWithSeed(const []);
  }

  @override
  Future<void> resetAllProgress(String userId) async {
    await _db.child(userId).remove();
    await _achDb.child(userId).remove();
    await _reflectionDb.child(userId).remove();
    await _storage.remove('progress_$userId');
    await _storage.remove('achievements_$userId');
    await _storage.remove('reflection_$userId');
  }

  @override
  Future<void> unlockAchievement(String userId, String achievementId) async {
    final existing = await getAchievements(userId);
    final idx = existing.indexWhere((a) => a.id == achievementId);
    if (idx < 0) return;

    final current = existing[idx];
    if (!current.isUnlocked) {
      existing[idx] = AchievementModel(
        id: current.id,
        name: current.name,
        description: current.description,
        iconEmoji: current.iconEmoji,
        tier: current.tier,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
    }

    final updated = existing[idx];
    await _achDb.child(userId).child(achievementId).set(updated.toJson());
    _cacheAchievements(userId, existing);
  }

  @override
  Future<ReflectionModel?> getReflection(String userId) async {
    try {
      final snapshot = await _reflectionDb.child(userId).get();
      if (snapshot.exists) {
        final data = _asMap(snapshot.value);
        _storage.write('reflection_$userId', data);
        return ReflectionModel.fromJson(data);
      }
    } catch (_) {}

    final localData = _storage.read('reflection_$userId');
    if (localData != null) {
      try {
        return ReflectionModel.fromJson(Map<String, dynamic>.from(localData));
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<void> saveReflection(String userId, ReflectionModel reflection) async {
    await _reflectionDb.child(userId).set(reflection.toJson());
    _storage.write('reflection_$userId', reflection.toJson());
  }
}
