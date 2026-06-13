import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/quiz_repository.dart';
import 'repository_providers.dart';

/// Active quiz session state
class QuizState {
  final QuizModel? activeQuiz;
  final int currentQuestionIndex;
  final Map<int, int> answers; // questionIndex -> selectedOptionIndex
  final int remainingSeconds;
  final bool isFinished;
  final bool isSubmitted;
  final int correctCount;

  const QuizState({
    this.activeQuiz,
    this.currentQuestionIndex = 0,
    this.answers = const {},
    this.remainingSeconds = 0,
    this.isFinished = false,
    this.isSubmitted = false,
    this.correctCount = 0,
  });

  QuizState copyWith({
    QuizModel? activeQuiz,
    int? currentQuestionIndex,
    Map<int, int>? answers,
    int? remainingSeconds,
    bool? isFinished,
    bool? isSubmitted,
    int? correctCount,
  }) {
    return QuizState(
      activeQuiz: activeQuiz ?? this.activeQuiz,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isFinished: isFinished ?? this.isFinished,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      correctCount: correctCount ?? this.correctCount,
    );
  }

  /// Score as percentage
  int get scorePercent {
    if (activeQuiz == null) return 0;
    return ((correctCount / activeQuiz!.totalQuestions) * 100).round();
  }

  String get timerDisplay {
    final min = remainingSeconds ~/ 60;
    final sec = remainingSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  int get incorrectCount {
    if (activeQuiz == null) return 0;
    return answers.length - correctCount;
  }

  int get remainingQuestions {
    if (activeQuiz == null) return 0;
    return activeQuiz!.totalQuestions - answers.length;
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  final QuizRepository _repo;

  QuizNotifier(this._repo) : super(const QuizState());
  Timer? _timer;

  Future<List<QuizModel>> getAllQuizzes() async {
    return _repo.getAllQuizzes();
  }

  /// Start a quiz session by ID
  Future<void> startQuiz(String quizId) async {
    final quiz = await _repo.getQuizById(quizId);
    if (quiz == null) return;
    _startWithQuiz(quiz);
  }

  /// Start quiz by type + unit
  Future<void> startQuizByType(QuizType type, {String? unitId}) async {
    QuizModel? quiz;
    if (unitId != null) {
      quiz = await _repo.getQuizByUnit(unitId, type);
    }
    quiz ??= (await _repo.getQuizzesByType(type)).firstOrNull;
    if (quiz == null) {
      final all = await _repo.getAllQuizzes();
      if (all.isEmpty) return;
      quiz = all.first;
    }
    _startWithQuiz(quiz);
  }

  void _startWithQuiz(QuizModel quiz) {
    // Shuffle questions for randomization
    final shuffledQuestions = List<QuizQuestion>.from(quiz.questions)..shuffle();
    final shuffledQuiz = QuizModel(
      id: quiz.id, type: quiz.type, unitId: quiz.unitId,
      title: quiz.title, timeLimitSeconds: quiz.timeLimitSeconds,
      questions: shuffledQuestions, xpReward: quiz.xpReward,
    );

    state = QuizState(
      activeQuiz: shuffledQuiz,
      remainingSeconds: quiz.timeLimitSeconds,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 1) {
        timer.cancel();
        _autoSubmit();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void _autoSubmit() {
    _calculateScore();
    state = state.copyWith(isFinished: true, isSubmitted: true, remainingSeconds: 0);
  }

  /// Select an answer for the current question
  void selectAnswer(int optionIndex) {
    if (state.isFinished) return;
    final answers = Map<int, int>.from(state.answers);
    answers[state.currentQuestionIndex] = optionIndex;
    state = state.copyWith(answers: answers);
  }

  /// Move to next question
  void nextQuestion() {
    if (state.activeQuiz == null) return;
    if (state.currentQuestionIndex < state.activeQuiz!.totalQuestions - 1) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
    }
  }

  /// Move to previous question
  void previousQuestion() {
    if (state.activeQuiz == null) return;
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1);
    }
  }

  /// Submit quiz and calculate score
  void submitQuiz() {
    _timer?.cancel();
    _calculateScore();
    state = state.copyWith(isFinished: true, isSubmitted: true);
  }

  void _calculateScore() {
    if (state.activeQuiz == null) return;
    int correct = 0;
    state.answers.forEach((qIndex, selectedIndex) {
      if (qIndex < state.activeQuiz!.questions.length) {
        if (state.activeQuiz!.questions[qIndex].correctIndex == selectedIndex) {
          correct++;
        }
      }
    });
    state = state.copyWith(correctCount: correct);
  }

  /// Reset quiz state
  void resetQuiz() {
    _timer?.cancel();
    state = const QuizState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> createQuiz(QuizModel quiz) async {
    await _repo.createQuiz(quiz);
  }

  Future<void> updateQuiz(QuizModel quiz) async {
    await _repo.updateQuiz(quiz);
  }

  Future<void> deleteQuiz(String id) async {
    await _repo.deleteQuiz(id);
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(ref.watch(quizRepositoryProvider));
});
