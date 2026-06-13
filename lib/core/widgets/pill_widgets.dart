import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// XP display pill with star icon, matching the mockup design.
class XpPill extends StatelessWidget {
  final int xp;

  const XpPill({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: AppColors.secondaryGreenAccent),
          const SizedBox(width: 4),
          Text(
            '$xp XP',
            style: AppTextStyles.pillText.copyWith(
              color: AppColors.secondaryGreenAccent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Streak display pill with flame icon.
class StreakPill extends StatelessWidget {
  final int days;

  const StreakPill({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              size: 14, color: AppColors.accentOrangeWarm),
          const SizedBox(width: 4),
          Text(
            '$days Hari',
            style: AppTextStyles.pillText.copyWith(
              color: AppColors.accentOrangeWarm,
            ),
          ),
        ],
      ),
    );
  }
}
