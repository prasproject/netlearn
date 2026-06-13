import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'simulation_tutorial_data.dart';

/// Panel petunjuk penggunaan simulasi (berubah sesuai topologi aktif).
class SimulationTutorialPanel extends StatelessWidget {
  final String simulationId;

  const SimulationTutorialPanel({super.key, required this.simulationId});

  static Future<void> showPopup(BuildContext context, String simulationId) {
    final tutorial = SimulationTutorials.forSimulation(simulationId);
    if (tutorial == null) return Future.value();

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.secondaryGreen, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Petunjuk ${tutorial.topologyName}',
                        style: AppTextStyles.heading.copyWith(
                          color: AppColors.secondaryGreen,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: AppColors.textMuted,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SimulationTutorialPanel(simulationId: simulationId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tutorial = SimulationTutorials.forSimulation(simulationId);
    if (tutorial == null) return const SizedBox.shrink();

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tutorial.aboutTopology,
            style: AppTextStyles.bodySmall.copyWith(height: 1.45, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            'LANGKAH MENGERJAKAN TUGAS',
            style: AppTextStyles.eyebrow.copyWith(color: AppColors.secondaryGreen, fontSize: 11),
          ),
          const SizedBox(height: 6),
          ...List.generate(tutorial.goalSteps.length, (i) => _stepRow(i + 1, tutorial.goalSteps[i])),
          const SizedBox(height: 10),
          Text(
            'KONTROL APLIKASI',
            style: AppTextStyles.eyebrow.copyWith(color: AppColors.secondaryGreen, fontSize: 11),
          ),
          const SizedBox(height: 6),
          ...SimulationTutorials.commonControls.map(_bulletRow),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondaryGreenSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.secondaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tutorial.tip,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondaryGreen,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
    );
  }

  Widget _stepRow(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.secondaryGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTextStyles.labelTiny.copyWith(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall.copyWith(height: 1.4, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _bulletRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryGreen, fontWeight: FontWeight.w800)),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall.copyWith(height: 1.35, fontSize: 12))),
        ],
      ),
    );
  }
}
