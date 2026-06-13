import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_storage/get_storage.dart';
import '../../models/quiz_model.dart';
import '../quiz_repository.dart';
import '../../seed/seed_data.dart';

/// Firebase Realtime Database implementation of QuizRepository.
class RtdbQuizRepository implements QuizRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('quizzes');
  final _storage = GetStorage();

  @override
  Future<QuizModel?> getQuizById(String id) async {
    final all = await getAllQuizzes();
    try {
      return all.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<QuizModel>> getAllQuizzes() async {
    try {
      final snapshot = await _db.get();
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
          return QuizModel.fromJson(map);
        }).toList();
        
        _storage.write('quizzes', list.map((e) => e.toJson()).toList());
        return list;
      }
    } catch (e) {
      // Fallback
    }

    // Offline / Cache
    final localData = _storage.read('quizzes');
    if (localData != null) {
      try {
        return (localData as List).map((e) => QuizModel.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    return SeedData.quizzes;
  }
  
  @override
  Future<QuizModel?> getQuizByUnit(String unitId, QuizType type) async {
    final all = await getAllQuizzes();
    try {
      return all.firstWhere((q) => q.unitId == unitId && q.type == type);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<QuizModel>> getQuizzesByType(QuizType type) async {
    final all = await getAllQuizzes();
    return all.where((q) => q.type == type).toList();
  }

  @override
  Future<void> createQuiz(QuizModel quiz) async {
    await updateQuiz(quiz);
  }

  @override
  Future<void> updateQuiz(QuizModel quiz) async {
    await _db.child(quiz.id).set(quiz.toJson());
    final localData = _storage.read('quizzes');
    if (localData == null) return;
    try {
      final list = (localData as List)
          .map((e) => QuizModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final idx = list.indexWhere((q) => q.id == quiz.id);
      if (idx == -1) {
        list.add(quiz);
      } else {
        list[idx] = quiz;
      }
      _storage.write('quizzes', list.map((e) => e.toJson()).toList());
    } catch (_) {}
  }

  @override
  Future<void> deleteQuiz(String id) async {
    await _db.child(id).remove();
    final localData = _storage.read('quizzes');
    if (localData == null) return;
    try {
      final list = (localData as List)
          .map((e) => QuizModel.fromJson(Map<String, dynamic>.from(e)))
          .where((q) => q.id != id)
          .toList();
      _storage.write('quizzes', list.map((e) => e.toJson()).toList());
    } catch (_) {}
  }
}
