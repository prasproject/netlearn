import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

/// Warna & ikon satu opsi jawaban setelah siswa menjawab.
///
/// Dipakai bersama oleh layar Latihan dan Post-Test supaya umpan baliknya
/// konsisten: jawaban benar selalu ditandai hijau, meski siswa salah memilih.
class AnswerOptionStyle {
  const AnswerOptionStyle({
    required this.background,
    required this.border,
    required this.foreground,
    this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData? icon;
}

/// Menentukan tampilan opsi ke-[index] berdasarkan status jawaban.
///
/// Sebelum dijawab, opsi memakai gaya netral [baseColor]/[baseSurface];
/// setelah dijawab, opsi benar jadi hijau dan pilihan salah jadi merah.
AnswerOptionStyle resolveAnswerOptionStyle({
  required int index,
  required int correctIndex,
  required int? selectedIndex,
  required bool answered,
  required Color baseColor,
  required Color baseSurface,
}) {
  final isSelected = selectedIndex == index;

  if (!answered) {
    return AnswerOptionStyle(
      background: isSelected ? baseColor : baseSurface,
      border: baseColor,
      foreground: isSelected ? Colors.white : baseColor,
    );
  }

  if (index == correctIndex) {
    return const AnswerOptionStyle(
      background: AppColors.success,
      border: AppColors.success,
      foreground: Colors.white,
      icon: Icons.check_circle_rounded,
    );
  }

  if (isSelected) {
    return const AnswerOptionStyle(
      background: AppColors.error,
      border: AppColors.error,
      foreground: Colors.white,
      icon: Icons.cancel_rounded,
    );
  }

  return AnswerOptionStyle(
    background: baseSurface.withValues(alpha: 0.5),
    border: baseColor.withValues(alpha: 0.25),
    foreground: baseColor.withValues(alpha: 0.55),
  );
}

/// Kartu pembahasan yang muncul setelah siswa menjawab: benar/salah, kunci
/// jawaban lengkap dengan hurufnya, dan penjelasan soal bila tersedia.
class AnswerFeedbackCard extends StatelessWidget {
  const AnswerFeedbackCard({
    super.key,
    required this.isCorrect,
    required this.correctIndex,
    required this.correctAnswer,
    this.explanation,
  });

  final bool isCorrect;
  final int correctIndex;
  final String correctAnswer;
  final String? explanation;

  static const _letters = ['A', 'B', 'C', 'D', 'E'];

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.success : AppColors.error;
    final letter = correctIndex >= 0 && correctIndex < _letters.length
        ? _letters[correctIndex]
        : '-';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Jawabanmu benar!' : 'Jawabanmu belum tepat',
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Jawaban benar: $letter. $correctAnswer',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (explanation != null && explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              explanation!,
              style: AppTextStyles.paragraph.copyWith(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.08);
  }
}
