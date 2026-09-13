import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_motion.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/widgets/header_back_button.dart';
import '../../core/widgets/loading_views.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/models/material_model.dart';
import '../../domain/providers/material_provider.dart';
import '../../domain/providers/progress_provider.dart';
import '../../domain/services/learning_progress_helper.dart';
import '../../data/models/progress_model.dart';

/// Material List Screen — Shows all units with lock/progress status.
class MaterialListScreen extends ConsumerWidget {
  const MaterialListScreen({super.key});

  bool _isUnitLocked({
    required int unitIndex,
    required List<MaterialModel> orderedUnits,
    required List<ProgressModel> progress,
  }) {
    return !LearningProgressHelper.isUnitUnlocked(
      unitIndex: unitIndex,
      orderedUnits: orderedUnits,
      progress: progress,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matState = ref.watch(materialProvider);
    final progress = ref.watch(progressProvider);
    final units = LearningProgressHelper.sortedUnits(matState.materials);
    final hasPretestScore = progress.hasCompletedPretest;
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
                          Text(
                            'Materi Pembelajaran',
                            style: AppTextStyles.screenTitle.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${units.length} unit + video pembelajaran',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
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
            child: units.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      // Shape-matched placeholders keep the layout steady while
                      // the units arrive from Firebase.
                      SkeletonCard(lines: 3),
                      SizedBox(height: 12),
                      SkeletonCard(lines: 3),
                      SizedBox(height: 12),
                      SkeletonCard(lines: 3),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: units.length + 1,
                    itemBuilder: (context, index) {
                      if (index == units.length) {
                        final isVideoLocked = !hasPretestScore;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child:
                              Pressable(
                                    enabled: !isVideoLocked,
                                    onTap: isVideoLocked
                                        ? null
                                        : () => context.push('/material/learning-video'),
                                    child: SurfaceCard(
                                      accent: videoColor,
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: videoColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: const Icon(
                                              Icons.play_circle_filled_rounded,
                                              color: videoColor,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Video',
                                                  style: AppTextStyles.eyebrow.copyWith(
                                                    color: videoColor,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  'Video Pembelajaran',
                                                  style: AppTextStyles.heading.copyWith(
                                                    fontSize: 17,
                                                  ),
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
                                            isVideoLocked
                                                ? Icons.lock_rounded
                                                : Icons.chevron_right_rounded,
                                            color: isVideoLocked
                                                ? AppColors.textDisabled
                                                : videoColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(
                                    delay: AppMotion.stagger * index,
                                    duration: AppMotion.normal,
                                  )
                                  .slideY(begin: 0.1, curve: AppMotion.enter),
                        );
                      }

                      final unit = units[index];
                      final unitProgress =
                          LearningProgressHelper.progressFor(unit.id, progress.unitProgress) ??
                          ProgressModel(unitId: unit.id, totalMaterials: unit.totalSlides);
                      final isLocked = _isUnitLocked(
                        unitIndex: index,
                        orderedUnits: units,
                        progress: progress.unitProgress,
                      );
                      final doneSlides = LearningProgressHelper.completedSlides(unitProgress, unit);
                      final pct = unit.totalSlides > 0 ? doneSlides / unit.totalSlides : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Pressable(
                          enabled: !isLocked,
                          onTap: isLocked
                              ? null
                              : () {
                                  final resumeSlide = LearningProgressHelper.resumeSlideIndex(
                                    unitProgress,
                                    unit,
                                  );
                                  ref
                                      .read(materialProvider.notifier)
                                      .setActiveUnit(unit.id, slideIndex: resumeSlide);
                                  context.push('/material/${unit.id}');
                                },
                          child:
                              Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                                      border: Border.all(
                                        color: isLocked
                                            ? AppColors.cardBorder
                                            : _unitColor(index).withValues(alpha: 0.18),
                                      ),
                                      boxShadow: isLocked ? null : AppShadows.card,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: _unitColor(index).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Center(
                                            child: Text(
                                              unit.iconEmoji ?? '📚',
                                              style: const TextStyle(fontSize: 22),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Unit ${unit.unitNumber}',
                                                style: AppTextStyles.eyebrow.copyWith(
                                                  color: _unitColor(index),
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                unit.title,
                                                style: AppTextStyles.heading.copyWith(fontSize: 17),
                                              ),
                                              const SizedBox(height: 4),
                                              // Progress bar
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(99),
                                                      // Animates when progress changes
                                                      // instead of snapping to the new value.
                                                      child: TweenAnimationBuilder<double>(
                                                        tween: Tween(begin: 0, end: pct),
                                                        duration: AppMotion.slow,
                                                        curve: AppMotion.enter,
                                                        builder: (context, value, _) =>
                                                            LinearProgressIndicator(
                                                              value: value,
                                                              minHeight: 5,
                                                              backgroundColor: Colors.grey.shade200,
                                                              valueColor: AlwaysStoppedAnimation(
                                                                _unitColor(index),
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${(pct * 100).round()}%',
                                                    style: AppTextStyles.labelTiny.copyWith(
                                                      color: _unitColor(index),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          isLocked
                                              ? Icons.lock_rounded
                                              : Icons.chevron_right_rounded,
                                          color: isLocked
                                              ? AppColors.textDisabled
                                              : _unitColor(index),
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(
                                    delay: AppMotion.stagger * index,
                                    duration: AppMotion.normal,
                                  )
                                  .slideY(begin: 0.1, curve: AppMotion.enter),
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
    const colors = [
      AppColors.primaryBlue,
      AppColors.accentOrange,
      AppColors.secondaryGreen,
      AppColors.purple,
      AppColors.quizPink,
    ];
    return colors[index % colors.length];
  }
}
