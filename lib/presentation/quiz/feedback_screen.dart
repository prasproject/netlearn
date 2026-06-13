import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/gradient_button.dart';
import '../../domain/providers/audio_provider.dart';
import 'package:lottie/lottie.dart';

/// Feedback Screen — Animated score result with XP, badge, and win/lose audio.
class FeedbackScreen extends ConsumerStatefulWidget {
  final int score;
  final int totalQuestions;
  final int xpEarned;
  final String quizType;
  final String unitTitle;

  const FeedbackScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.xpEarned,
    required this.quizType,
    required this.unitTitle,
  });

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  @override
  void initState() {
    super.initState();
    // Play win/lose sound based on score
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audio = ref.read(audioProvider.notifier);
      if (widget.score >= 90) {
        audio.playSfx(SoundEffect.excellent);
      } else if (widget.score >= 70) {
        audio.playSfx(SoundEffect.win);
      } else {
        audio.playSfx(SoundEffect.lose);
      }
      // XP gain sound after delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) audio.playSfx(SoundEffect.xpGained);
      });
      // Badge unlock sound
      if (widget.quizType == 'Quiz' || widget.quizType == 'Checkpoint') {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) audio.playSfx(SoundEffect.badgeUnlock);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = AppStrings.getFeedbackTitle(widget.score);
    final message = AppStrings.getFeedbackMessage(widget.score);
    final showBadge = widget.quizType == 'Quiz' || widget.quizType == 'Checkpoint';
    final isWin = widget.score >= 70;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Lottie animation (Win/Lose)
              SizedBox(
                width: 150, height: 150,
                child: Lottie.asset(
                  isWin ? 'assets/lottie/win.json' : 'assets/lottie/lose.json',
                  repeat: false,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isWin ? AppColors.goldSurface : Colors.grey.shade100,
                      border: Border.all(color: isWin ? AppColors.gold : Colors.grey.shade400, width: 2),
                    ),
                    child: Icon(
                      isWin ? Icons.star_rounded : Icons.sentiment_dissatisfied_rounded,
                      size: 40, color: isWin ? AppColors.gold : Colors.grey.shade500,
                    ),
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              // Score Ring
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isWin ? AppColors.gold : AppColors.accentOrange, width: 5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${widget.score}', style: AppTextStyles.scoreLarge.copyWith(
                      color: isWin ? AppColors.secondaryGreen : AppColors.accentOrange)),
                    Text('/ 100', style: AppTextStyles.pillText.copyWith(color: AppColors.accentOrangeGold)),
                  ],
                ),
              ).animate().scale(delay: 300.ms, duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              // Title — changes based on win/lose
              Text(title, style: AppTextStyles.screenTitle.copyWith(
                color: isWin ? AppColors.secondaryGreen : AppColors.accentOrange, fontSize: 20,
              )).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 8),
              Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.paragraph.copyWith(fontSize: 13),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 16),
              // XP Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColors.secondaryGreenSurface, borderRadius: BorderRadius.circular(99)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 18, color: AppColors.secondaryGreen),
                    const SizedBox(width: 6),
                    Text('+${widget.xpEarned} XP didapat!', style: AppTextStyles.pillText.copyWith(color: AppColors.secondaryGreen)),
                  ],
                ),
              ).animate().slideY(begin: 0.2, delay: 700.ms).fadeIn(),
              const SizedBox(height: 20),
              // Badge unlock (only for high scores)
              if (showBadge)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.goldSurface, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.star_rounded, size: 20, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🏆 Badge Baru: Badge Quiz!', style: AppTextStyles.pillText.copyWith(color: AppColors.accentOrange)),
                            Text('Kamu sudah menyelesaikan quiz unit.', style: AppTextStyles.labelSmall.copyWith(color: AppColors.accentOrangeGold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.2, delay: 900.ms).fadeIn(),
              const SizedBox(height: 30),
              // Continue button
              GradientButton(
                text: isWin ? 'Lanjut ke Unit Berikutnya' : 'Coba Lagi',
                backgroundColor: isWin ? AppColors.secondaryGreen : AppColors.accentOrange,
                shadowColor: isWin ? AppColors.secondaryGreenDark : AppColors.accentOrangeDark,
                width: double.infinity,
                onPressed: () {
                  ref.read(audioProvider.notifier).playSfx(SoundEffect.buttonTap);
                  context.go('/home');
                },
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}
