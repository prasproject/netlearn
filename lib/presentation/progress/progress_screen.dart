import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/header_back_button.dart';
import '../../domain/providers/material_provider.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/progress_provider.dart';

/// Progress Screen — Learning stats, unit bars, charts, N-Gain card.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final user = ref.watch(authProvider).user;
    final hasPretestScore = progress.overallPretestScore > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Teal Header
          Container(
            decoration: const BoxDecoration(color: AppColors.progressTeal),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const HeaderBackButton(),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Progress Belajar', style: AppTextStyles.screenTitle)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statCard('${progress.completedUnits}', 'Unit Selesai'),
                        const SizedBox(width: 8),
                        _statCard('${(progress.overallProgress * 100).round()}%', 'Progress'),
                        const SizedBox(width: 8),
                        _statCard('${user?.xp ?? 0}', 'Total XP'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Unit Progress List ──
                  Text('UNIT BELAJAR', style: AppTextStyles.eyebrow.copyWith(color: AppColors.progressTeal)),
                  const SizedBox(height: 10),
                  ...List.generate(progress.unitProgress.length, (i) {
                    final p = progress.unitProgress[i];
                    final materials = ref.watch(materialProvider).materials;
                    final unitTitle = materials.isNotEmpty 
                        ? materials.firstWhere((m) => m.id == p.unitId, orElse: () => materials.first).title 
                        : 'Memuat...';
                    final pct = p.materialProgress;
                    final statusColor = p.isCompleted ? AppColors.progressTealLight
                        : p.isInProgress ? AppColors.gold : Colors.grey.shade400;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(unitTitle,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: p.isCompleted || p.isInProgress ? AppColors.textPrimary : AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: pct, minHeight: 5,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(statusColor),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: (i * 80).ms),
                    );
                  }),

                  const SizedBox(height: 24),

                  // ── Bar Chart: Skor Per Unit ──
                  Text('SKOR PER UNIT', style: AppTextStyles.eyebrow.copyWith(color: AppColors.progressTeal)),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                    ),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => AppColors.progressTeal,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final label = rodIndex == 0 ? 'Pre' : 'Post';
                              return BarTooltipItem(
                                '$label: ${rod.toY.toInt()}',
                                AppTextStyles.labelTiny.copyWith(color: Colors.white),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final labels = ['U1', 'U2', 'U3', 'U4', 'U5'];
                                final idx = value.toInt();
                                if (idx < 0 || idx >= labels.length) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(labels[idx],
                                    style: AppTextStyles.labelTiny.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                                );
                              },
                              reservedSize: 24,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true, reservedSize: 30, interval: 25,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}',
                                  style: AppTextStyles.statLabel.copyWith(color: AppColors.textMuted, fontSize: 11));
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true, drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.shade200, strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: _buildBarGroups(progress),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                  const SizedBox(height: 8),
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendDot(AppColors.accentOrange, 'Pre-Test'),
                      const SizedBox(width: 16),
                      _legendDot(AppColors.progressTealAccent, 'Post-Test'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Pie Chart: Penyelesaian Keseluruhan ──
                  Text('PENYELESAIAN MATERI', style: AppTextStyles.eyebrow.copyWith(color: AppColors.progressTeal)),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 32,
                              sections: _buildPieSections(progress),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _legendDot(AppColors.progressTealAccent, 'Selesai'),
                            const SizedBox(height: 8),
                            _legendDot(AppColors.gold, 'Sedang Berjalan'),
                            const SizedBox(height: 8),
                            _legendDot(Colors.grey.shade300, 'Belum Mulai'),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

                  const SizedBox(height: 24),

                  // ── N-Gain Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.progressTealSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: const Border(left: BorderSide(color: AppColors.progressTealAccent, width: 4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('N-GAIN SEMENTARA', style: AppTextStyles.eyebrow.copyWith(color: AppColors.progressTeal)),
                        const SizedBox(height: 4),
                        Text('Pre: ${progress.overallPretestScore} → Post parsial: ${progress.overallPosttestScore}',
                          style: AppTextStyles.bodySmall),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(progress.nGain.toStringAsFixed(2),
                              style: AppTextStyles.scoreMedium.copyWith(color: AppColors.progressTeal)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.progressTealPale, borderRadius: BorderRadius.circular(99)),
                              child: Text(progress.nGainCategory,
                                style: AppTextStyles.chip.copyWith(color: AppColors.progressTealAccent)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.1, delay: 600.ms).fadeIn(),
                  const SizedBox(height: 20),
                  // View Post-Test button
                  GestureDetector(
                    onTap: hasPretestScore ? () => context.push('/post-test') : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: hasPretestScore ? AppColors.progressTeal : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [const BoxShadow(color: Color(0xFF004D40), offset: Offset(0, 4))],
                      ),
                      child: Text(
                        hasPretestScore ? 'Lihat Analisis Post-Test' : 'Terkunci — kerjakan Pre-Test dulu',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.buttonPrimary),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build grouped bar chart data — Pre vs Post per unit
  List<BarChartGroupData> _buildBarGroups(ProgressState progress) {
    return List.generate(progress.unitProgress.length, (i) {
      final p = progress.unitProgress[i];
      final pre = p.pretestScore?.toDouble() ?? 0;
      final post = (p.finalScore ?? p.checkpointAverage)?.toDouble() ?? 0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: pre, color: AppColors.accentOrange,
            width: 10, borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: post, color: AppColors.progressTealAccent,
            width: 10, borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  /// Build pie chart sections — completed vs in-progress vs not-started
  List<PieChartSectionData> _buildPieSections(ProgressState progress) {
    final completed = progress.unitProgress.where((p) => p.isCompleted).length;
    final inProgress = progress.unitProgress.where((p) => p.isInProgress).length;
    final notStarted = progress.unitProgress.where((p) => !p.isCompleted && !p.isInProgress).length;
    final total = progress.unitProgress.length;

    if (total == 0) return [];

    return [
      if (completed > 0)
        PieChartSectionData(
          value: completed.toDouble(), color: AppColors.progressTealAccent,
          radius: 28, title: '$completed', titleStyle: AppTextStyles.pillText.copyWith(color: Colors.white, fontSize: 12),
        ),
      if (inProgress > 0)
        PieChartSectionData(
          value: inProgress.toDouble(), color: AppColors.gold,
          radius: 28, title: '$inProgress', titleStyle: AppTextStyles.pillText.copyWith(color: Colors.white, fontSize: 12),
        ),
      if (notStarted > 0)
        PieChartSectionData(
          value: notStarted.toDouble(), color: Colors.grey.shade300,
          radius: 28, title: '$notStarted', titleStyle: AppTextStyles.pillText.copyWith(color: AppColors.textMuted, fontSize: 12),
        ),
    ];
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.statValue),
            Text(label, style: AppTextStyles.statLabel.copyWith(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}
