import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/animated_progress_bar.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/quiz_model.dart';
import '../../domain/providers/quiz_provider.dart';
import '../../domain/providers/audio_provider.dart';
import '../../domain/providers/progress_provider.dart';

/// Pre-Test Screen — Orange themed quiz with timer.
class PretestScreen extends ConsumerStatefulWidget {
  const PretestScreen({super.key});
  @override
  ConsumerState<PretestScreen> createState() => _PretestScreenState();
}

class _PretestScreenState extends ConsumerState<PretestScreen> {
  bool _savedScore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizProvider.notifier).startQuizByType(QuizType.pretest);
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
            unitId: '',
            quizType: 'Pre-Test',
            scorePercent: quiz.scorePercent,
          );
        }
        context.pushReplacement('/feedback', extra: {
          'score': quiz.scorePercent,
          'totalQuestions': quiz.activeQuiz!.totalQuestions,
          'xpEarned': quiz.activeQuiz!.xpReward,
          'quizType': 'Pre-Test',
          'unitTitle': '',
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
            // Orange Header
            Container(
              decoration: const BoxDecoration(color: AppColors.accentOrange),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Pre-Test', style: AppTextStyles.sectionTitle),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(99)),
                            child: Text(quiz.timerDisplay, style: AppTextStyles.pillText.copyWith(color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedProgressBar(
                              progress: progress, height: 4,
                              gradientColors: const [AppColors.accentOrangeWarm, AppColors.accentOrangeWarm],
                            ),
                          ),
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
            // Question Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SOAL ${quiz.currentQuestionIndex + 1} DARI ${quiz.activeQuiz!.totalQuestions}',
                      style: AppTextStyles.eyebrow.copyWith(color: AppColors.accentOrange)),
                    const SizedBox(height: 8),
                    Text(q.question, style: AppTextStyles.bodyMedium.copyWith(fontSize: 15))
                        .animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 16),
                    // Options
                    ...List.generate(q.options.length, (i) {
                      final isSelected = quiz.answers[quiz.currentQuestionIndex] == i;
                      final alreadyAnswered = quiz.answers.containsKey(quiz.currentQuestionIndex);
                      final letters = ['A', 'B', 'C', 'D'];
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.accentOrange : AppColors.accentOrangeSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.accentOrange : AppColors.accentOrangeWarm.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.5),
                                  ),
                                  child: Center(child: Text(letters[i], style: AppTextStyles.pillText.copyWith(
                                    color: isSelected ? Colors.white : AppColors.accentOrangeDark, fontSize: 12,
                                  ))),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(q.options[i], style: AppTextStyles.quizOption.copyWith(
                                  color: isSelected ? Colors.white : AppColors.accentOrangeDark,
                                ))),
                              ],
                            ),
                          ),
                        ).animate().slideX(begin: 0.03, delay: (i * 60).ms, duration: 300.ms).fadeIn(),
                      );
                    }),
                  ],
                ),
              ),
            ),
            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      text: 'Kembali',
                      backgroundColor: AppColors.primaryBlue,
                      shadowColor: AppColors.primaryBlueDark,
                      onPressed: () {
                        ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
                        if (quiz.currentQuestionIndex > 0) {
                          ref.read(quizProvider.notifier).previousQuestion();
                        } else {
                          ref.read(quizProvider.notifier).resetQuiz();
                          context.pop();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Opacity(
                      opacity: quiz.currentQuestionIndex < quiz.activeQuiz!.totalQuestions - 1 ? 1 : 0.45,
                      child: GradientButton(
                        text: 'Lanjut',
                        backgroundColor: AppColors.accentOrange,
                        shadowColor: AppColors.accentOrangeDark,
                        onPressed: quiz.currentQuestionIndex < quiz.activeQuiz!.totalQuestions - 1
                            ? () {
                                ref.read(audioProvider.notifier).playSfx(SoundEffect.slideNext);
                                ref.read(quizProvider.notifier).nextQuestion();
                              }
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GradientButton(
                text: 'Selesai',
                backgroundColor: AppColors.secondaryGreen,
                shadowColor: AppColors.secondaryGreenDark,
                width: double.infinity,
                onPressed: () {
                  ref.read(audioProvider.notifier).playSfx(SoundEffect.quizComplete);
                  ref.read(quizProvider.notifier).submitQuiz();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
