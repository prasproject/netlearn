import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_motion.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/widgets/animated_progress_bar.dart';
import '../../core/widgets/loading_views.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/student_icon.dart';
import '../../core/widgets/surface_card.dart';
import '../../core/widgets/pill_widgets.dart';
import '../../data/models/progress_model.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/progress_provider.dart';
import '../../domain/providers/material_provider.dart';
import '../../domain/providers/tutorial_provider.dart';
import '../../domain/services/learning_progress_helper.dart';

/// Home Dashboard Screen
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final progress = ref.watch(progressProvider);
    final user = auth.user;
    final hasPretestScore = progress.hasCompletedPretest;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: AppLoader(message: 'Menyiapkan beranda...'),
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
            user.xp,
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
                  SectionHeader(
                    title: AppStrings.continueLearning,
                    icon: Icons.play_circle_fill_rounded,
                  ).animate().fadeIn(duration: 300.ms),
                  _buildContinueCard(
                    context,
                    ref,
                    hasPretestScore,
                  ).animate().slideX(begin: -0.05, duration: 400.ms).fadeIn(),
                  const SizedBox(height: 20),
                  // Menu Grid
                  SectionHeader(
                    title: AppStrings.mainMenu,
                    icon: Icons.grid_view_rounded,
                  ).animate().fadeIn(delay: 100.ms),
                  _buildMenuGrid(
                    context,
                    ref,
                    hasPretestScore,
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: 20),
                  // Badge Carousel
                  SectionHeader(
                    title: AppStrings.badgeCollection,
                    icon: Icons.military_tech_rounded,
                    color: AppColors.gold,
                  ).animate().fadeIn(delay: 300.ms),
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

  /// Panduan hub: replay the full welcome tour or just the menu spotlight.
  void _showGuideSheet(WidgetRef ref) {
    final context = ref.context;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Butuh panduan?', style: AppTextStyles.heading),
              const SizedBox(height: 4),
              Text(
                'Pilih panduan yang ingin kamu lihat lagi.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _guideOption(
                icon: Icons.auto_stories_rounded,
                color: AppColors.primaryBlue,
                title: 'Panduan Awal',
                subtitle: 'Kenalan ulang dengan alur belajar, simulasi, dan XP',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/onboarding');
                },
              ),
              const SizedBox(height: 10),
              _guideOption(
                icon: Icons.touch_app_rounded,
                color: AppColors.accentOrange,
                title: 'Tur Menu',
                subtitle: 'Sorot satu per satu menu di bagian bawah layar',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ref.read(tutorialTriggerProvider.notifier).state++;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guideOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitleDark),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    WidgetRef ref,
    String name,
    String initials,
    int xp,
    int streak,
    double progress,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.brandGradient,
          stops: AppColors.brandGradientStops,
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white38, width: 2),
                              color: AppColors.primaryBlueLight,
                            ),
                            child: Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryBlueAccent,
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: AppTextStyles.pillText.copyWith(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // XP & streak pills
                  Row(
                    children: [
                      XpPill(xp: xp),
                      const SizedBox(width: 8),
                      StreakPill(days: streak),
                    ],
                  ),
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
                            Text(
                              AppStrings.progressThisWeek,
                              style: AppTextStyles.labelSmall.copyWith(color: Colors.white70),
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: AppTextStyles.pillText.copyWith(
                                color: AppColors.primaryBlueAccent,
                              ),
                            ),
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

    final target = LearningProgressHelper.resolveContinueTarget(
      materials: matState.materials,
      progress: progress.unitProgress,
    );

    final targetUnitId = target?.unitId ?? 'unit-1';
    final title = target?.title ?? 'Unit 1';
    final subtitle = target?.subtitle ?? 'Mulai belajar';
    final resumeSlide = target?.slideIndex ?? 0;

    return SurfaceCard(
      accent: AppColors.primaryBlue,
      raised: true,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryBlueSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.primaryBlueLight, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasPretestScore ? subtitle : 'Kerjakan Pre-Test untuk membuka menu',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Pressable(
            onTap: () {
              if (!hasPretestScore) {
                context.push('/pretest');
                return;
              }
              ref
                  .read(materialProvider.notifier)
                  .setActiveUnit(targetUnitId, slideIndex: resumeSlide);
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

  Widget _buildMenuGrid(BuildContext context, WidgetRef ref, bool hasPretestScore) {
    final cards = <Widget>[
      _menuCard(
        'Panduan',
        'Cara memakai aplikasi',
        AppColors.info,
        StudentPose.guide,
        onTap: () => _showGuideSheet(ref),
      ),
      _menuCard(
        'Kompetensi Pembelajaran',
        'Kompetensi & tujuan belajar',
        AppColors.progressTeal,
        StudentPose.goal,
        onTap: () => context.push('/capaian'),
      ),
      _menuCard(
        'Pre Test',
        hasPretestScore ? 'Sudah kamu kerjakan' : 'Tes awal sebelum belajar',
        AppColors.accentOrange,
        StudentPose.pretest,
        hijab: true,
        // Pre-Test hanya boleh sekali supaya skor awal N-Gain tetap sahih.
        enabled: !hasPretestScore,
        lockedLabel: 'Selesai',
        lockedIcon: Icons.check_circle_rounded,
        lockedMessage:
            'Pre-Test hanya bisa dikerjakan sekali. Untuk mengulang, reset data '
            'belajar di Profil > Pengaturan.',
        onTap: () => context.push('/pretest'),
      ),
      _menuCard(
        'Materi',
        '5 unit tersedia',
        AppColors.primaryBlue,
        StudentPose.reading,
        hijab: true,
        badge: 'Baru',
        enabled: hasPretestScore,
        onTap: () => context.push('/materials'),
      ),
      _menuCard(
        'Simulasi',
        'IP & Routing interaktif',
        AppColors.secondaryGreen,
        StudentPose.building,
        enabled: hasPretestScore,
        onTap: () => context.push('/simulation'),
      ),
      _menuCard(
        'Post Test',
        'Tes akhir setelah belajar',
        AppColors.postDark,
        StudentPose.posttest,
        enabled: hasPretestScore,
        onTap: () => context.push('/posttest'),
      ),
      _menuCard(
        'Refleksi',
        'Refleksikan pemahamanmu',
        AppColors.quizPink,
        StudentPose.reflecting,
        hijab: true,
        enabled: hasPretestScore,
        onTap: () => context.push('/reflection'),
      ),
      _menuCard(
        'Progress',
        'Nilai & pencapaianmu',
        AppColors.purple,
        StudentPose.achievement,
        enabled: hasPretestScore,
        onTap: () => context.push('/progress'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.95,
      children: [
        // Cards drop in one after another instead of the whole grid at once.
        for (var i = 0; i < cards.length; i++)
          cards[i]
              .animate()
              .fadeIn(delay: AppMotion.stagger * i, duration: AppMotion.normal)
              .slideY(begin: 0.12, curve: AppMotion.enter),
      ],
    );
  }

  Widget _menuCard(
    String title,
    String subtitle,
    Color color,
    StudentPose pose, {
    String? badge,
    bool enabled = true,
    bool hijab = false,
    String? lockedMessage,
    String lockedLabel = 'Terkunci',
    IconData lockedIcon = Icons.lock_rounded,
    VoidCallback? onTap,
  }) {
    return Builder(
      builder: (context) => Pressable(
        // A locked card still answers the tap — it says what unlocks it,
        // instead of feeling like a broken button.
        onTap: enabled ? onTap : () => _explainLocked(context, title, lockedMessage),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final s = (size.shortestSide.isFinite ? size.shortestSide : 160.0);

            final padding = (s * 0.11).clamp(14.0, 20.0);
            final iconBox = (s * 0.35).clamp(60.0, 90.0);

            final titleSize = (s * 0.155).clamp(17.0, 24.0);
            final subtitleSize = (s * 0.10).clamp(12.0, 16.0);

            return Opacity(
              opacity: enabled ? 1 : 0.6,
              child: Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  // Soft vertical gradient + matching glow: same palette, but the
                  // tiles read as raised surfaces rather than flat colour blocks.
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(color, Colors.white, 0.12)!,
                      Color.lerp(color, Colors.black, 0.10)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  boxShadow: enabled ? AppShadows.glow(color, alpha: 0.22) : null,
                ),
                child: Stack(
                  children: [
                    Positioned(bottom: -20, right: -20, child: _decoCircle(60, 0.06)),
                    Positioned(top: -10, right: 20, child: _decoCircle(35, 0.06)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The student mascot instead of a generic glyph: each
                        // menu is introduced by someone the learner recognises.
                        SizedBox(
                          width: iconBox,
                          height: iconBox,
                          child: StudentIcon(
                            pose: pose,
                            size: iconBox,
                            accent: color,
                            hijab: hijab,
                          ),
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
                              Icon(lockedIcon, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                lockedLabel,
                                style: AppTextStyles.labelTiny.copyWith(color: Colors.white),
                              ),
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
      ),
    );
  }

  /// Tell the student what a locked menu is waiting for.
  void _explainLocked(BuildContext context, String title, [String? message]) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          duration: const Duration(seconds: 4),
          action: message == null
              ? null
              : SnackBarAction(
                  label: 'Profil',
                  textColor: Colors.white,
                  onPressed: () => context.push('/profile'),
                ),
          content: Row(
            children: [
              Icon(
                message == null ? Icons.lock_rounded : Icons.info_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message ?? 'Menu $title terbuka setelah kamu mengerjakan Pre-Test.',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildBadgeCarousel(List<AchievementModel> badges) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Center(
                  child: Opacity(
                    opacity: isUnlocked ? 1.0 : 0.4,
                    child: Text(badge.iconEmoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 52,
                child: Text(
                  badge.name,
                  style: AppTextStyles.badgeName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _decoCircle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
}
