import '../../models/quiz_model.dart';
import '../../seed/seed_data.dart';
import '../quiz_repository.dart';

/// Mock quiz repository — uses SeedData.
class MockQuizRepository implements QuizRepository {
  final List<QuizModel> _quizzes = List<QuizModel>.from(SeedData.quizzes);

  @override
  Future<List<QuizModel>> getAllQuizzes() async => List<QuizModel>.from(_quizzes);

  @override
  Future<QuizModel?> getQuizById(String id) async {
    try {
      return _quizzes.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<QuizModel>> getQuizzesByType(QuizType type) async {
    return _quizzes.where((q) => q.type == type).toList();
  }

  @override
  Future<QuizModel?> getQuizByUnit(String unitId, QuizType type) async {
    try {
      return _quizzes.firstWhere(
        (q) => q.unitId == unitId && q.type == type,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createQuiz(QuizModel quiz) async {
    _quizzes.add(quiz);
  }

  @override
  Future<void> updateQuiz(QuizModel quiz) async {
    final idx = _quizzes.indexWhere((q) => q.id == quiz.id);
    if (idx == -1) {
      _quizzes.add(quiz);
      return;
    }
    _quizzes[idx] = quiz;
  }

  @override
  Future<void> deleteQuiz(String id) async {
    _quizzes.removeWhere((q) => q.id == id);
  }
}
