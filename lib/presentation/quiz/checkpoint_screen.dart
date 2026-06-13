import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/quiz_model.dart';
import '../../domain/providers/quiz_provider.dart';
import '../../domain/providers/audio_provider.dart';
import '../../domain/providers/progress_provider.dart';

/// Checkpoint Screen — Purple themed mini quiz after a material section.
class CheckpointScreen extends ConsumerStatefulWidget {
  final String unitId;
  const CheckpointScreen({super.key, required this.unitId});
  @override
  ConsumerState<CheckpointScreen> createState() => _CheckpointScreenState();
}

class _CheckpointScreenState extends ConsumerState<CheckpointScreen> {
  bool _savedScore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizProvider.notifier).startQuizByType(QuizType.checkpoint, unitId: widget.unitId);
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
            quizType: 'Checkpoint',
            scorePercent: quiz.scorePercent,
          );
        }
        context.pushReplacement('/feedback', extra: {
          'score': quiz.scorePercent, 'totalQuestions': quiz.activeQuiz!.totalQuestions,
          'xpEarned': quiz.activeQuiz!.xpReward, 'quizType': 'Checkpoint', 'unitTitle': quiz.activeQuiz!.title,
        });
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = quiz.activeQuiz!.questions[quiz.currentQuestionIndex];

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: AppColors.purple),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(width: 32, height: 32,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.15)),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Checkpoint', style: AppTextStyles.sectionTitle),
                        const Spacer(),
                        Text('${quiz.currentQuestionIndex + 1} / ${quiz.activeQuiz!.totalQuestions}',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(quiz.activeQuiz!.totalQuestions, (i) => Expanded(
                        child: Container(
                          height: 6, margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(99),
                            color: i < quiz.currentQuestionIndex ? AppColors.purpleAccent
                              : i == quiz.currentQuestionIndex ? Colors.white : Colors.white.withValues(alpha: 0.25)),
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
                  // Mascot
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: AppColors.purpleSurface, borderRadius: BorderRadius.circular(14)),
                    child: const Center(child: Text('🤖', style: TextStyle(fontSize: 26))),
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 14),
                  Text(q.question, textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 15)).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 16),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.purple : AppColors.purpleSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? AppColors.purple : AppColors.purpleAccent, width: 1.5),
                          ),
                          child: Text(q.options[i], style: AppTextStyles.quizOption.copyWith(
                            color: isSelected ? Colors.white : AppColors.purple)),
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
              text: quiz.currentQuestionIndex < quiz.activeQuiz!.totalQuestions - 1 ? 'Konfirmasi Jawaban' : 'Selesai',
              backgroundColor: AppColors.purple, shadowColor: AppColors.purpleDark, width: double.infinity,
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
    );
  }
}
