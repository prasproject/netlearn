import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/progress_model.dart';
import '../../seed/seed_data.dart';
import '../progress_repository.dart';

/// Firebase Firestore implementation of ProgressRepository.
class FirestoreProgressRepository implements ProgressRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<ProgressModel>> getProgress(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .get();

    return snapshot.docs.map((doc) => ProgressModel.fromJson(doc.data())).toList();
  }

  @override
  Future<void> saveProgress(String userId, ProgressModel progress) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(progress.unitId)
        .set(progress.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> saveQuizScore(
    String userId,
    String unitId, {
    int? pretestScore,
    int? checkpointScore,
    int? finalScore,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(unitId);

    // Use a transaction or field values to safely append checkpoint scores
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      
      if (!doc.exists) {
        // Fallback: If progress doc doesn't exist, we can't fully construct it without knowing totalMaterials,
        // but for safety, we create a minimal version. Usually `saveProgress` is called first.
        transaction.set(docRef, {
          'unitId': unitId,
          'materialsCompleted': 0,
          'totalMaterials': 5, // arbitrary default fallback
          if (pretestScore != null) 'pretestScore': pretestScore,
          if (checkpointScore != null) 'checkpointScores': [checkpointScore],
          if (finalScore != null) 'finalScore': finalScore,
        });
        return;
      }

      final updates = <String, dynamic>{};

      if (pretestScore != null) updates['pretestScore'] = pretestScore;
      if (finalScore != null) updates['finalScore'] = finalScore;
      
      if (checkpointScore != null) {
        // Append to array
        updates['checkpointScores'] = FieldValue.arrayUnion([checkpointScore]);
      }

      if (updates.isNotEmpty) {
        transaction.update(docRef, updates);
      }
    });
  }

  @override
  Future<List<AchievementModel>> getAchievements(String userId) async {
    List<AchievementModel> mergeWithSeed(List<AchievementModel> source) {
      final byId = {for (final a in source) a.id: a};
      return SeedData.achievements.map((seed) => byId[seed.id] ?? seed).toList();
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .get();

    final fromDb =
        snapshot.docs.map((doc) => AchievementModel.fromJson(doc.data())).toList();
    return mergeWithSeed(fromDb);
  }

  @override
  Future<void> resetAllProgress(String userId) async {
    final progressSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .get();
    for (final doc in progressSnap.docs) {
      await doc.reference.delete();
    }

    final achievementsSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .get();
    for (final doc in achievementsSnap.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<void> unlockAchievement(String userId, String achievementId) async {
    final existing = await getAchievements(userId);
    final item = existing.cast<AchievementModel?>().firstWhere(
          (a) => a?.id == achievementId,
          orElse: () => null,
        );
    if (item == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .doc(achievementId)
        .set({
      'id': item.id,
      'name': item.name,
      'description': item.description,
      'iconEmoji': item.iconEmoji,
      'tier': item.tier.name,
      'isUnlocked': true,
      'unlockedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
