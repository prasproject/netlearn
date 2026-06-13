import '../models/quiz_model.dart';

/// Abstract quiz repository.
abstract class QuizRepository {
  Future<List<QuizModel>> getAllQuizzes();
  Future<QuizModel?> getQuizById(String id);
  Future<List<QuizModel>> getQuizzesByType(QuizType type);
  Future<QuizModel?> getQuizByUnit(String unitId, QuizType type);
  Future<void> createQuiz(QuizModel quiz);
  Future<void> updateQuiz(QuizModel quiz);
  Future<void> deleteQuiz(String id);
}
