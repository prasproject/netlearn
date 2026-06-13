import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/header_back_button.dart';
import '../../data/models/material_model.dart';
import '../../domain/providers/material_provider.dart';
import '../../domain/providers/progress_provider.dart';
import '../../data/models/progress_model.dart';

/// Material List Screen — Shows all units with lock/progress status.
class MaterialListScreen extends ConsumerWidget {
  const MaterialListScreen({super.key});

  bool _isUnitLocked({
    required int unitIndex,
    required List<MaterialModel> orderedUnits,
    required List<ProgressModel> progress,
  }) {
    if (unitIndex <= 0) return false; // Unit 1 selalu terbuka
    final prevUnit = orderedUnits[unitIndex - 1];
    final prevProgress =
        progress.where((p) => p.unitId == prevUnit.id).cast<ProgressModel?>().firstWhere(
              (p) => p != null,
              orElse: () => null,
            ) ??
            ProgressModel(unitId: prevUnit.id, totalMaterials: prevUnit.totalSlides);
    // Unlock unit berikutnya cukup dengan menyelesaikan materi unit sebelumnya.
    // Checkpoint (jika ada) bersifat opsional dan tidak boleh mengunci progres materi.
    return !prevProgress.isCompleted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matState = ref.watch(materialProvider);
    final progress = ref.watch(progressProvider);
    final units = List<MaterialModel>.from(matState.materials)
      ..sort((a, b) {
        final o = a.order.compareTo(b.order);
        if (o != 0) return o;
        return a.unitNumber.compareTo(b.unitNumber);
      });
    final hasPretestScore = progress.overallPretestScore > 0;
    const videoColor = Color(0xFFC62828);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: AppColors.primaryBlue),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HeaderBackButton(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Materi Pembelajaran', style: AppTextStyles.screenTitle.copyWith(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(
                            '${units.length} unit + video pembelajaran',
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.white60, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Unit List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: units.length + 1,
              itemBuilder: (context, index) {
                if (index == units.length) {
                  final isVideoLocked = !hasPretestScore;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: isVideoLocked
                          ? null
                          : () => context.push('/material/learning-video'),
                      child: Opacity(
                        opacity: isVideoLocked ? 0.5 : 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: const Border(left: BorderSide(color: videoColor, width: 4)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: videoColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.play_circle_filled_rounded, color: videoColor, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Video',
                                      style: AppTextStyles.eyebrow.copyWith(color: videoColor, fontSize: 13),
                                    ),
                                    Text(
                                      'Video Pembelajaran',
                                      style: AppTextStyles.heading.copyWith(fontSize: 17),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isVideoLocked
                                          ? 'Terkunci — kerjakan Pre-Test dulu'
                                          : 'Streaming YouTube',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isVideoLocked ? Icons.lock_rounded : Icons.chevron_right_rounded,
                                color: isVideoLocked ? Colors.grey : videoColor,
                              ),
                            ],
                          ),
                        ).animate().slideX(begin: 0.05, delay: (index * 80).ms, duration: 400.ms).fadeIn(),
                      ),
                    ),
                  );
                }

                final unit = units[index];
                final unitProgress = progress.unitProgress.cast<ProgressModel?>().firstWhere(
                      (p) => p?.unitId == unit.id,
                      orElse: () => null,
                    ) ??
                    ProgressModel(unitId: unit.id, totalMaterials: unit.totalSlides);
                final isLocked = _isUnitLocked(
                  unitIndex: index,
                  orderedUnits: units,
                  progress: progress.unitProgress,
                );
                final pct = unitProgress.materialProgress;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: isLocked ? null : () {
                      ref.read(materialProvider.notifier).setActiveUnit(unit.id);
                      context.push('/material/${unit.id}');
                    },
                    child: Opacity(
                      opacity: isLocked ? 0.5 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: _unitColor(index).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(child: Text(unit.iconEmoji ?? '📚', style: const TextStyle(fontSize: 22))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Unit ${unit.unitNumber}',
                                    style: AppTextStyles.eyebrow.copyWith(color: _unitColor(index), fontSize: 13),
                                  ),
                                  Text(unit.title, style: AppTextStyles.heading.copyWith(fontSize: 17)),
                                  const SizedBox(height: 4),
                                  // Progress bar
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(99),
                                          child: LinearProgressIndicator(
                                            value: pct, minHeight: 4,
                                            backgroundColor: Colors.grey.shade200,
                                            valueColor: AlwaysStoppedAnimation(_unitColor(index)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${(pct * 100).round()}%', style: AppTextStyles.labelTiny.copyWith(color: _unitColor(index))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLocked ? Icons.lock_rounded : Icons.chevron_right_rounded,
                              color: isLocked ? Colors.grey : _unitColor(index),
                            ),
                          ],
                        ),
                      ).animate().slideX(begin: 0.05, delay: (index * 80).ms, duration: 400.ms).fadeIn(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _unitColor(int index) {
    const colors = [AppColors.primaryBlue, AppColors.accentOrange, AppColors.secondaryGreen, AppColors.purple, AppColors.quizPink];
    return colors[index % colors.length];
  }
}
