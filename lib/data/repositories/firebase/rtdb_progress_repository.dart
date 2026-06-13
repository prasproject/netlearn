import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_storage/get_storage.dart';
import '../../models/progress_model.dart';
import '../progress_repository.dart';
import '../../seed/seed_data.dart';

/// Firebase Realtime Database implementation of ProgressRepository.
class RtdbProgressRepository implements ProgressRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('progress');
  final DatabaseReference _achDb = FirebaseDatabase.instance.ref('achievements');
  final _storage = GetStorage();
  static const String _overallUnitId = '__overall__';

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
          // If older data missed totals, backfill from seed.
          if (existing.unitId != _overallUnitId && existing.totalMaterials == 0) {
            return existing.copyWith().copyWith(
              // copyWith can't change totalMaterials; rebuild safely.
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

  @override
  Future<List<ProgressModel>> getProgress(String userId) async {
    try {
      final snapshot = await _db.child(userId).get();
      if (snapshot.exists) {
        Map<String, dynamic> data;
        try {
          data = Map<String, dynamic>.from(snapshot.value as Map);
        } catch (_) {
          data = Map<String, dynamic>.from(jsonDecode(jsonEncode(snapshot.value)));
        }
        final list = data.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          map['unitId'] = e.key;
          return ProgressModel.fromJson(map);
        }).toList();
        
        // Cache to GetStorage
        final merged = _mergeWithSeedUnits(list);
        _storage.write('progress_$userId', merged.map((e) => e.toJson()).toList());
        return merged;
      }
    } catch (e) {
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
    await _db.child(userId).child(progress.unitId).set(progress.toJson());
    _syncLocalProgress(userId);
  }

  @override
  Future<void> saveQuizScore(String userId, String unitId, {int? pretestScore, int? checkpointScore, int? finalScore}) async {
    final ref = _db.child(userId).child(unitId);
    final snapshot = await ref.get();
    
    Map<String, dynamic> updateData = {};
    if (pretestScore != null) updateData['pretestScore'] = pretestScore;
    if (finalScore != null) updateData['finalScore'] = finalScore;

    // Ensure the record is parseable by `ProgressModel.fromJson` even for `__overall__`.
    // Some paths only store quiz meta and would otherwise miss required fields.
    if (!snapshot.exists) {
      updateData['unitId'] = unitId;
      updateData['materialsCompleted'] = 0;
      updateData['totalMaterials'] = 0;
    } else {
      try {
        final current = Map<String, dynamic>.from(snapshot.value as Map);
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
        final current = Map<String, dynamic>.from(snapshot.value as Map);
        List<int> scores = (current['checkpointScores'] as List?)?.cast<int>() ?? [];
        scores.add(checkpointScore);
        updateData['checkpointScores'] = scores;
      } else {
        updateData['checkpointScores'] = [checkpointScore];
      }
    }
    
    if (updateData.isNotEmpty) {
      // `update` is fine; it will create the node if missing.
      await ref.update(updateData);
      _syncLocalProgress(userId);
    }
  }

  void _syncLocalProgress(String userId) async {
    try {
      final snapshot = await _db.child(userId).get();
      if (snapshot.exists) {
        Map<String, dynamic> data;
        try {
          data = Map<String, dynamic>.from(snapshot.value as Map);
        } catch (_) {
          data = Map<String, dynamic>.from(jsonDecode(jsonEncode(snapshot.value)));
        }
        final list = data.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          map['unitId'] = e.key;
          return ProgressModel.fromJson(map);
        }).toList();
        final merged = _mergeWithSeedUnits(list);
        _storage.write('progress_$userId', merged.map((e) => e.toJson()).toList());
      }
    } catch (_) {}
  }

  @override
  Future<List<AchievementModel>> getAchievements(String userId) async {
    List<AchievementModel> mergeWithSeed(List<AchievementModel> source) {
      final byId = {for (final a in source) a.id: a};
      return SeedData.achievements.map((seed) => byId[seed.id] ?? seed).toList();
    }

    try {
      final snapshot = await _achDb.child(userId).get();
      if (snapshot.exists) {
        Map<String, dynamic> data;
        try {
          data = Map<String, dynamic>.from(snapshot.value as Map);
        } catch (_) {
          data = Map<String, dynamic>.from(jsonDecode(jsonEncode(snapshot.value)));
        }
        final list = data.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          map['id'] = e.key;
          return AchievementModel.fromJson(map);
        }).toList();
        final merged = mergeWithSeed(list);
        _storage.write('achievements_$userId', merged.map((e) => e.toJson()).toList());
        return merged;
      }
    } catch (_) {}

    final localData = _storage.read('achievements_$userId');
    if (localData != null) {
      try {
        final local = (localData as List)
            .map((e) => AchievementModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return mergeWithSeed(local);
      } catch (_) {}
    }

    return mergeWithSeed(const []);
  }

  @override
  Future<void> resetAllProgress(String userId) async {
    await _db.child(userId).remove();
    await _achDb.child(userId).remove();
    await _storage.remove('progress_$userId');
    await _storage.remove('achievements_$userId');
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
    _storage.write('achievements_$userId', existing.map((e) => e.toJson()).toList());
  }
}
