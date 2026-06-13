import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/animated_progress_bar.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/quiz_model.dart';
import '../../domain/providers/quiz_provider.dart';
import '../../domain/providers/audio_provider.dart';
import '../../domain/providers/progress_provider.dart';

/// Final Quiz Screen — Pink themed with score tracking.
class QuizScreen extends ConsumerStatefulWidget {
  final String unitId;
  const QuizScreen({super.key, required this.unitId});
  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _savedScore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizProvider.notifier).startQuizByType(QuizType.finalQuiz, unitId: widget.unitId);
      ref.read(audioProvider.notifier).playSfx(SoundEffect.quizStart);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizProvider);
    if (quiz.activeQuiz == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (quiz.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_savedScore) {
          _savedScore = true;
          ref.read(progressProvider.notifier).saveUnitQuizScore(
            unitId: widget.unitId,
            quizType: 'Quiz',
            scorePercent: quiz.scorePercent,
          );
        }
        context.pushReplacement('/feedback', extra: {
          'score': quiz.scorePercent, 'totalQuestions': quiz.activeQuiz!.totalQuestions,
          'xpEarned': quiz.activeQuiz!.xpReward, 'quizType': 'Quiz', 'unitTitle': quiz.activeQuiz!.title,
        });
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = quiz.activeQuiz!.questions[quiz.currentQuestionIndex];
    final progress = (quiz.currentQuestionIndex + 1) / quiz.activeQuiz!.totalQuestions;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              decoration: const BoxDecoration(color: AppColors.quizPink),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(quiz.activeQuiz!.title, style: AppTextStyles.sectionTitle),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(99)),
                            child: Text(quiz.timerDisplay, style: AppTextStyles.pillText.copyWith(color: AppColors.quizPinkAccent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: AnimatedProgressBar(progress: progress, height: 4,
                            gradientColors: const [AppColors.quizPinkAccent, AppColors.quizPinkAccent])),
                          const SizedBox(width: 8),
                          Text('${quiz.currentQuestionIndex + 1} / ${quiz.activeQuiz!.totalQuestions}',
                            style: AppTextStyles.labelTiny.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Score tracker
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _scoreBox('Benar', '${quiz.correctCount}', AppColors.secondaryGreen),
                  const SizedBox(width: 8),
                  _scoreBox('Salah', '${quiz.incorrectCount}', AppColors.accentOrange),
                  const SizedBox(width: 8),
                  _scoreBox('Sisa', '${quiz.remainingQuestions}', AppColors.quizPink),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.question, style: AppTextStyles.bodyMedium.copyWith(fontSize: 15)).animate().fadeIn(),
                    if (q.imageBase64 != null && q.imageBase64!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _QuizBase64Image(base64Text: q.imageBase64!),
                    ],
                    const SizedBox(height: 14),
                    ...List.generate(q.options.length, (i) {
                      final isSelected = quiz.answers[quiz.currentQuestionIndex] == i;
                      final alreadyAnswered = quiz.answers.containsKey(quiz.currentQuestionIndex);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            if (!alreadyAnswered) {
                              final isCorrect = i == q.correctIndex;
                              ref.read(audioProvider.notifier).playSfx(
                                isCorrect ? SoundEffect.correct : SoundEffect.incorrect,
                              );
                            }
                            ref.read(quizProvider.notifier).selectAnswer(i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.quizPink : AppColors.quizPinkSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? AppColors.quizPink : AppColors.quizPinkAccent, width: 1.5),
                            ),
                            child: Text(q.options[i], style: AppTextStyles.quizOption.copyWith(
                              color: isSelected ? Colors.white : AppColors.quizPink)),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GradientButton(
                text: quiz.currentQuestionIndex < quiz.activeQuiz!.totalQuestions - 1 ? 'Kirim Jawaban' : 'Selesai',
                backgroundColor: AppColors.quizPink, shadowColor: AppColors.quizPinkDark, width: double.infinity,
                onPressed: () {
                  if (quiz.currentQuestionIndex < quiz.activeQuiz!.totalQuestions - 1) {
                    ref.read(quizProvider.notifier).nextQuestion();
                  } else {
                    ref.read(quizProvider.notifier).submitQuiz();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: AppColors.quizPinkSurface, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.statLabel.copyWith(color: AppColors.quizPinkLight)),
            Text(value, style: AppTextStyles.statValue.copyWith(color: color, fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

class _QuizBase64Image extends StatelessWidget {
  final String base64Text;

  const _QuizBase64Image({required this.base64Text});

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(base64Text.trim());
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(bytes, height: 140, width: double.infinity, fit: BoxFit.cover),
      );
    } catch (_) {
      return const Text('Gambar Base64 tidak valid', style: TextStyle(color: Colors.red));
    }
  }
}
