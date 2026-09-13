import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../domain/providers/progress_provider.dart';

/// Persist a finished quiz **before** moving on to the feedback screen.
///
/// Previously the score was written fire-and-forget while navigation happened
/// immediately, so a failed write left the user looking at a result the
/// database never received (and menus that stayed locked). Here the write is
/// awaited; if it fails the user is asked to retry instead of losing the score.
Future<void> saveQuizResultThenContinue({
  required BuildContext context,
  required WidgetRef ref,
  required String unitId,
  required String quizType,
  required int scorePercent,
  required Map<String, dynamic> feedbackExtra,
}) async {
  final notifier = ref.read(progressProvider.notifier);

  Future<bool> attempt() async {
    notifier.clearSyncError();
    await notifier.saveUnitQuizScore(
      unitId: unitId,
      quizType: quizType,
      scorePercent: scorePercent,
    );
    return ref.read(progressProvider).syncError == null;
  }

  var saved = await attempt();

  while (!saved) {
    if (!context.mounted) return;
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Nilai belum tersimpan', style: AppTextStyles.cardTitleDark)),
          ],
        ),
        content: Text(
          'Koneksi ke server bermasalah sehingga nilai $quizType belum tersimpan. '
          'Pastikan internet aktif, lalu coba simpan lagi.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Lanjut dulu',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );

    if (retry != true) break;
    saved = await attempt();
  }

  if (!context.mounted) return;
  notifier.clearSyncError();
  context.pushReplacement('/feedback', extra: feedbackExtra);
}
