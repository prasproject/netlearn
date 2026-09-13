import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/quiz_model.dart';
import '../../domain/providers/quiz_provider.dart';
import '../../domain/providers/audio_provider.dart';
import '../../domain/providers/progress_provider.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/services/ngain_calculator.dart';
import '../../core/widgets/loading_views.dart';

/// Latihan quiz — 5 soal setelah menyelesaikan materi unit.
class PracticeQuizScreen extends ConsumerStatefulWidget {
  final String unitId;
  final String unitTitle;
  final bool popMaterialDetail;

  const PracticeQuizScreen({
    super.key,
    required this.unitId,
    required this.unitTitle,
    this.popMaterialDetail = false,
  });

  @override
  ConsumerState<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends ConsumerState<PracticeQuizScreen> {
  bool _savedScore = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizProvider.notifier).startQuizByType(
            QuizType.practice,
            unitId: widget.unitId,
          );
      ref.read(audioProvider.notifier).playSfx(SoundEffect.quizStart);
    });
  }

  Future<void> _finishFlow(int scorePercent, int totalQuestions, int correctCount) async {
    if (_finishing) return;
    _finishing = true;

    await ref.read(progressProvider.notifier).saveUnitQuizScore(
          unitId: widget.unitId,
          quizType: 'Latihan',
          scorePercent: scorePercent,
        );

    final quiz = ref.read(quizProvider);
    final baseXp = quiz.activeQuiz?.xpReward ?? XPService.quizCompleteXP;
    final earnedXp = XPService.calculateQuizXP(scorePercent, baseXp);
    if (earnedXp > 0) {
      ref.read(authProvider.notifier).addXP(earnedXp);
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppStrings.practiceComplete, style: AppTextStyles.heading),
        content: Text(
          'Kamu menjawab $correctCount dari $totalQuestions soal dengan benar (skor $scorePercent%).',
          style: AppTextStyles.paragraph.copyWith(height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );

    ref.read(quizProvider.notifier).resetQuiz();

    if (!mounted) return;
    context.pop();
    if (widget.popMaterialDetail && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizProvider);
    if (quiz.activeQuiz == null) {
      return Scaffold(body: AppLoader(message: 'Menyiapkan latihan...'));
    }

    if (quiz.isFinished && !_savedScore) {
      _savedScore = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _finishFlow(
          quiz.scorePercent,
          quiz.activeQuiz!.totalQuestions,
          quiz.correctCount,
        );
      });
      return Scaffold(body: AppLoader(message: 'Menyimpan hasilmu...'));
    }

    final q = quiz.activeQuiz!.questions[quiz.currentQuestionIndex];
    final hasAnswer = quiz.answers.containsKey(quiz.currentQuestionIndex);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Keluar latihan?'),
            content: const Text(
              'Selesaikan latihan terlebih dahulu agar bisa lanjut ke refleksi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Lanjutkan'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  ref.read(quizProvider.notifier).resetQuiz();
                  context.pop();
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        body: Column(
          children: [
            Container(
              decoration: const BoxDecoration(color: AppColors.secondaryGreen),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppStrings.practiceQuiz, style: AppTextStyles.sectionTitle),
                                Text(
                                  widget.unitTitle,
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${quiz.currentQuestionIndex + 1} / ${quiz.activeQuiz!.totalQuestions}',
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(quiz.activeQuiz!.totalQuestions, (i) => Expanded(
                              child: Container(
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(99),
                                  color: i < quiz.currentQuestionIndex
                                      ? AppColors.secondaryGreenAccent
                                      : i == quiz.currentQuestionIndex
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryGreenSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(child: Text('📝', style: TextStyle(fontSize: 26))),
                    ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 14),
                    Text(
                      q.question,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 15),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 16),
                    ...List.generate(q.options.length, (i) {
                      final isSelected = quiz.answers[quiz.currentQuestionIndex] == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            if (!hasAnswer) {
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.secondaryGreen : AppColors.secondaryGreenSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.secondaryGreen : AppColors.secondaryGreenAccent,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              q.options[i],
                              style: AppTextStyles.quizOption.copyWith(
                                color: isSelected ? Colors.white : AppColors.secondaryGreen,
                              ),
                            ),
                          ),
                        ).animate().slideX(begin: 0.03, delay: (i * 60).ms, duration: 300.ms).fadeIn(),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GradientButton(
                text: quiz.currentQuestionIndex < quiz.activeQuiz!.totalQuestions - 1
                    ? AppStrings.confirmAnswer
                    : AppStrings.practiceFinish,
                backgroundColor: AppColors.secondaryGreen,
                shadowColor: AppColors.secondaryGreenDark,
                width: double.infinity,
                onPressed: hasAnswer
                    ? () {
                        if (quiz.currentQuestionIndex < quiz.activeQuiz!.totalQuestions - 1) {
                          ref.read(quizProvider.notifier).nextQuestion();
                        } else {
                          ref.read(quizProvider.notifier).submitQuiz();
                        }
                      }
                    : null,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
