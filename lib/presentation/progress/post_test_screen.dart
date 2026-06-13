import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/gradient_button.dart';
import '../../domain/providers/progress_provider.dart';
import '../../domain/services/ngain_calculator.dart';
import '../../domain/providers/material_provider.dart';

/// Post-Test Analysis Screen — Pre vs Post comparison, N-Gain, radar + bar charts.
class PostTestScreen extends ConsumerWidget {
  const PostTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final hasPretestScore = progress.overallPretestScore > 0;
    final nGain = progress.nGain;
    final materials = ref.watch(materialProvider).materials;
    final unitTitleById = {for (final m in materials) m.id: m.title};

    if (!hasPretestScore) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Container(
              decoration: const BoxDecoration(color: AppColors.postDark),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Hasil Post-Test', style: AppTextStyles.screenTitle),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, size: 34, color: AppColors.postDark),
                        const SizedBox(height: 8),
                        Text(
                          'Post-Test masih terkunci',
                          style: AppTextStyles.sectionTitle.copyWith(color: AppColors.postDark),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Kerjakan Pre-Test dulu untuk membuka menu Materi, Simulasi, Progress, dan Post-Test.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        GradientButton(
                          text: 'Mulai Pre-Test',
                          icon: Icons.fact_check_rounded,
                          backgroundColor: AppColors.accentOrange,
                          shadowColor: AppColors.accentOrangeDark,
                          width: double.infinity,
                          onPressed: () => context.push('/pretest'),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.98, 0.98)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final topicColors = <Color>[
      AppColors.primaryBlue,
      AppColors.progressTealAccent,
      AppColors.secondaryGreen,
      AppColors.purple,
      AppColors.accentOrange,
    ];
    final topics = List.generate(progress.unitProgress.length, (index) {
      final unit = progress.unitProgress[index];
      final name = unitTitleById[unit.unitId] ?? unit.unitId;
      final preScore = unit.pretestScore ?? 0;
      final postScore = unit.finalScore ?? unit.checkpointAverage ?? 0;
      return (
        name,
        preScore,
        postScore,
        topicColors[index % topicColors.length],
      );
    });
    final hasTopics = topics.isNotEmpty;

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: AppColors.postDark),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(width: 32, height: 32,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.15)),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    Text('Hasil Post-Test', style: AppTextStyles.screenTitle),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Score Comparison Cards ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.postSurface, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        Text('PERBANDINGAN SKOR', style: AppTextStyles.eyebrow.copyWith(color: AppColors.postGray)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _scoreCol('Pre-Test', '${progress.overallPretestScore}', AppColors.accentOrange)),
                            const Icon(Icons.arrow_forward_rounded, color: AppColors.secondaryGreen, size: 24),
                            Expanded(child: _scoreCol('Post-Test', '${progress.overallPosttestScore}', AppColors.secondaryGreen)),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 16),

                  // ── N-Gain Big Card ──
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.postDarker, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        Text('N-GAIN SCORE', style: AppTextStyles.eyebrow.copyWith(color: AppColors.postMuted)),
                        const SizedBox(height: 4),
                        Text(nGain.toStringAsFixed(2), style: AppTextStyles.scoreHuge.copyWith(color: AppColors.postTeal)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.postTealLight.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(NGainCalculator.getDescription(nGain),
                            style: AppTextStyles.chip.copyWith(color: AppColors.postTealLight)),
                        ),
                      ],
                    ),
                  ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 24),

                  // ── Radar Chart: Per-Topic Comparison ──
                  Text('RADAR KOMPETENSI', style: AppTextStyles.eyebrow.copyWith(color: AppColors.postDark)),
                  const SizedBox(height: 8),
                  if (hasTopics)
                    Container(
                      height: 240,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                      ),
                      child: RadarChart(
                        RadarChartData(
                          radarBorderData: BorderSide(color: Colors.grey.shade200),
                          gridBorderData: BorderSide(color: Colors.grey.shade200, width: 0.5),
                          tickBorderData: BorderSide(color: Colors.grey.shade300, width: 0.5),
                          tickCount: 4,
                          ticksTextStyle: AppTextStyles.statLabel.copyWith(color: Colors.transparent),
                          titlePositionPercentageOffset: 0.2,
                          titleTextStyle: AppTextStyles.labelTiny.copyWith(
                            color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 11,
                          ),
                          getTitle: (index, angle) {
                            if (index < topics.length) return RadarChartTitle(text: topics[index].$1);
                            return const RadarChartTitle(text: '');
                          },
                          dataSets: [
                            RadarDataSet(
                              fillColor: AppColors.accentOrange.withValues(alpha: 0.15),
                              borderColor: AppColors.accentOrange,
                              borderWidth: 2,
                              entryRadius: 3,
                              dataEntries: topics.map((t) => RadarEntry(value: t.$2.toDouble())).toList(),
                            ),
                            RadarDataSet(
                              fillColor: AppColors.progressTealAccent.withValues(alpha: 0.2),
                              borderColor: AppColors.progressTealAccent,
                              borderWidth: 2,
                              entryRadius: 3,
                              dataEntries: topics.map((t) => RadarEntry(value: t.$3.toDouble())).toList(),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 500.ms)
                  else
                    _emptyDataCard(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendDot(AppColors.accentOrange, 'Pre-Test'),
                      const SizedBox(width: 16),
                      _legendDot(AppColors.progressTealAccent, 'Post-Test'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Horizontal Bar: Nilai Per Topik ──
                  Text('NILAI PER TOPIK', style: AppTextStyles.eyebrow.copyWith(color: AppColors.postDark)),
                  const SizedBox(height: 10),
                  if (hasTopics)
                    Container(
                      height: 200,
                      padding: const EdgeInsets.fromLTRB(0, 12, 16, 8),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                      ),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 100,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => AppColors.postDark,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${topics[group.x].$1}: ${rod.toY.toInt()}',
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
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= topics.length) return const SizedBox();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(topics[idx].$1,
                                      style: AppTextStyles.labelTiny.copyWith(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                  );
                                },
                                reservedSize: 24,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true, reservedSize: 28, interval: 25,
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
                            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(topics.length, (i) {
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: topics[i].$3.toDouble(),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                    colors: [topics[i].$4.withValues(alpha: 0.6), topics[i].$4],
                                  ),
                                  width: 18, borderRadius: BorderRadius.circular(6),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 500.ms)
                  else
                    _emptyDataCard(),

                  const SizedBox(height: 24),
                  GradientButton(
                    text: 'Ambil Sertifikat', icon: Icons.card_membership_rounded,
                    backgroundColor: AppColors.postDark, shadowColor: AppColors.postDarker, width: double.infinity,
                    onPressed: () => context.push('/certificate'),
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

  Widget _scoreCol(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.statLabel.copyWith(color: AppColors.textMuted)),
          Text(value, style: AppTextStyles.scoreMedium.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _emptyDataCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Text(
        'Belum ada data unit yang bisa dianalisis.',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        textAlign: TextAlign.center,
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
