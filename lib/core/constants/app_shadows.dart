import 'package:flutter/material.dart';

import 'app_colors.dart';

/// NetLearn Design System — Elevation
///
/// Shadows used to be written inline with slightly different blur and opacity
/// on every screen, which made the UI look noisy. These three levels cover the
/// whole app: resting surfaces, raised surfaces, and floating overlays.
class AppShadows {
  AppShadows._();

  /// Cards sitting on the background.
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.primaryBlue.withValues(alpha: 0.06),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  /// Cards that invite a tap, or the currently highlighted item.
  static List<BoxShadow> get raised => [
    BoxShadow(
      color: AppColors.primaryBlue.withValues(alpha: 0.10),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  /// Sheets, dialogs, and floating bars.
  static List<BoxShadow> get overlay => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, -2),
    ),
  ];

  /// Coloured glow used behind an accented element (badges, active menu).
  static List<BoxShadow> glow(Color color, {double alpha = 0.28}) => [
    BoxShadow(
      color: color.withValues(alpha: alpha),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];
}
