import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/animated_progress_bar.dart';
import '../../core/widgets/pill_widgets.dart';
import '../../data/models/progress_model.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/progress_provider.dart';
import '../../domain/providers/material_provider.dart';
import '../../domain/providers/tutorial_provider.dart';

/// Home Dashboard Screen
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final progress = ref.watch(progressProvider);
    final user = auth.user;
    final hasPretestScore = progress.overallPretestScore > 0;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──
          _buildHeader(
            ref,
            user.displayName.split(' ').first,
            user.initials,
            user.streak,
            progress.overallProgress,
          ),
          // ── Body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Continue Learning
                  Text(AppStrings.continueLearning,
                    style: AppTextStyles.labelUppercase.copyWith(color: AppColors.primaryBlueLight),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 8),
                  _buildContinueCard(context, ref, hasPretestScore).animate().slideX(begin: -0.05, duration: 400.ms).fadeIn(),
                  const SizedBox(height: 20),
                  // Menu Grid
                  Text(AppStrings.mainMenu,
                    style: AppTextStyles.labelUppercase.copyWith(color: AppColors.primaryBlueLight),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 8),
                  _buildMenuGrid(context, hasPretestScore).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: 20),
                  // Badge Carousel
                  Text(AppStrings.badgeCollection,
                    style: AppTextStyles.labelUppercase.copyWith(color: AppColors.primaryBlueLight),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 8),
                  _buildBadgeCarousel(progress.achievements).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    WidgetRef ref,
    String name,
    String initials,
    int streak,
    double progress,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [AppColors.primaryBlue, Color(0xFF0A3575)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Stack(
            children: [
              // Decoration circles
              Positioned(top: -40, right: -20, child: _decoCircle(120, 0.06)),
              Positioned(bottom: -10, left: 20, child: _decoCircle(70, 0.04)),
              Column(
                children: [
                  // Top row: greeting + avatar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.welcomeBack, style: AppTextStyles.greeting),
                          Text('${AppStrings.hello}, $name 👋', style: AppTextStyles.greetingName),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.18),
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: IconButton(
                              tooltip: 'Tutorial',
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              color: Colors.white,
                              onPressed: () {
                                ref.read(tutorialTriggerProvider.notifier).state++;
                              },
                              icon: const Icon(Icons.help_outline_rounded),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white38, width: 2),
                              color: AppColors.primaryBlueLight,
                            ),
                            child: Center(
                              child: Container(
                                width: 32, height: 32,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryBlueAccent),
                                child: Center(child: Text(initials, style: AppTextStyles.pillText.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w900))),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Streak pill
                  Row(children: [StreakPill(days: streak)]),
                  const SizedBox(height: 12),
                  // Progress bar
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppStrings.progressThisWeek, style: AppTextStyles.labelSmall.copyWith(color: Colors.white70)),
                            Text('${(progress * 100).round()}%', style: AppTextStyles.pillText.copyWith(color: AppColors.primaryBlueAccent)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        AnimatedProgressBar(progress: progress, height: 5),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueCard(BuildContext context, WidgetRef ref, bool hasPretestScore) {
    final matState = ref.watch(materialProvider);
    final progress = ref.watch(progressProvider);
    
    String targetUnitId = 'unit-1';
    String title = 'Unit 1';
    String subtitle = 'Mulai belajar';
    
    if (matState.materials.isNotEmpty) {
      final units = List.of(matState.materials)
        ..sort((a, b) {
          final o = a.order.compareTo(b.order);
          if (o != 0) return o;
          return a.unitNumber.compareTo(b.unitNumber);
        });

      bool isUnlockedIndex(int i) {
        if (i <= 0) return true;
        final prev = units[i - 1];
        final prevP = progress.unitProgress.where((p) => p.unitId == prev.id).cast<ProgressModel?>().firstWhere(
              (p) => p != null,
              orElse: () => null,
            ) ??
            ProgressModel(unitId: prev.id, totalMaterials: prev.totalSlides);
        // Lanjut ke unit berikutnya cukup dengan menyelesaikan materi unit sebelumnya.
        // Checkpoint tidak lagi mengunci akses materi.
        return prevP.isCompleted;
      }

      final activeIdx = units.indexWhere((u) => u.id == (matState.activeUnitId ?? ''));
      var firstUnlockedIdx = 0;
      for (var i = 0; i < units.length; i++) {
        if (isUnlockedIndex(i)) {
          firstUnlockedIdx = i;
          break;
        }
      }

      final idx = (activeIdx >= 0 && isUnlockedIndex(activeIdx)) ? activeIdx : firstUnlockedIdx;

      final resolvedIdx = idx >= 0 ? idx : 0;
      targetUnitId = units[resolvedIdx].id;
      final targetUnit = units[resolvedIdx];
      title = 'Unit ${targetUnit.unitNumber} — ${targetUnit.title}';
      
      try {
        final p = progress.unitProgress.firstWhere((p) => p.unitId == targetUnitId);
        subtitle = '${p.materialsCompleted}/${p.totalMaterials} Materi Selesai';
      } catch (_) {
        subtitle = '0/${targetUnit.totalSlides} Materi Selesai';
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: AppColors.primaryBlue, width: 4)),
        boxShadow: [BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.1), blurRadius: 12)],
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primaryBlueSurface, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.primaryBlueLight, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  hasPretestScore ? subtitle : 'Kerjakan Pre-Test untuk membuka menu',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (!hasPretestScore) {
                context.push('/pretest');
                return;
              }
              ref.read(materialProvider.notifier).setActiveUnit(targetUnitId);
              context.push('/material/$targetUnitId');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: hasPretestScore ? AppColors.primaryBlue : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: hasPretestScore ? AppColors.primaryBlueDark : Colors.grey.shade500,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                hasPretestScore ? AppStrings.continueButton : 'Pre-Test',
                style: AppTextStyles.buttonSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context, bool hasPretestScore) {
    return GridView.count(
      crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10,
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.95,
      children: [
        _menuCard(
          'Materi',
          '5 unit tersedia',
          AppColors.primaryBlue,
          Icons.menu_book_rounded,
          badge: 'Baru',
          enabled: hasPretestScore,
          onTap: () => context.push('/materials'),
        ),
        _menuCard(
          'Simulasi',
          'IP & Routing interaktif',
          AppColors.secondaryGreen,
          Icons.hub_rounded,
          enabled: hasPretestScore,
          onTap: () => context.push('/simulation'),
        ),
        _menuCard('Test', 'Pre-Test & Post-Test', AppColors.accentOrange, Icons.quiz_rounded, badge: '2 mode',
          onTap: () => context.push('/test')),
        _menuCard(
          'Progress',
          'Nilai & pencapaianmu',
          AppColors.purple,
          Icons.star_rounded,
          enabled: hasPretestScore,
          onTap: () => context.push('/progress'),
        ),
      ],
    );
  }

  Widget _menuCard(
    String title,
    String subtitle,
    Color color,
    IconData icon, {
    String? badge,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final s = (size.shortestSide.isFinite ? size.shortestSide : 160.0);

          final padding = (s * 0.11).clamp(14.0, 20.0);
          final iconBox = (s * 0.35).clamp(60.0, 90.0);
          final iconSize = (iconBox * 0.58).clamp(30.0, 50.0);

          final titleSize = (s * 0.155).clamp(17.0, 24.0);
          final subtitleSize = (s * 0.10).clamp(12.0, 16.0);

          return Opacity(
            opacity: enabled ? 1 : 0.55,
            child: Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
              child: Stack(
                children: [
                  Positioned(bottom: -20, right: -20, child: _decoCircle(60, 0.06)),
                  Positioned(top: -10, right: 20, child: _decoCircle(35, 0.06)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: iconBox,
                        height: iconBox,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: Colors.white, size: iconSize),
                      ),
                      SizedBox(height: (s * 0.08).clamp(10.0, 14.0)),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(fontSize: titleSize),
                      ),
                      SizedBox(height: (s * 0.03).clamp(4.0, 8.0)),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                          fontSize: subtitleSize,
                        ),
                      ),
                    ],
                  ),
                  if (!enabled)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text('Terkunci', style: AppTextStyles.labelTiny.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  if (badge != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          badge,
                          style: AppTextStyles.labelTiny.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgeCarousel(List<AchievementModel> badges) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal, itemCount: badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final badge = badges[index];
          final isUnlocked = badge.isUnlocked;
          Color borderColor;
          Color bgColor;
          if (badge.tier == AchievementTier.gold && isUnlocked) {
            borderColor = AppColors.gold;
            bgColor = AppColors.goldSurface;
          } else if (isUnlocked) {
            borderColor = AppColors.primaryBlue;
            bgColor = AppColors.primaryBlueSurface;
          } else {
            borderColor = Colors.grey.shade400;
            bgColor = Colors.grey.shade100;
          }
          return Column(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor, border: Border.all(color: borderColor, width: 2)),
                child: Center(
                  child: Opacity(opacity: isUnlocked ? 1.0 : 0.4, child: Text(badge.iconEmoji, style: const TextStyle(fontSize: 20))),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 52,
                child: Text(badge.name, style: AppTextStyles.badgeName, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _decoCircle(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
  );
}
