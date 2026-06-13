import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Animated progress bar with gradient fill and smooth width animation.
class AnimatedProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? trackColor;
  final List<Color>? gradientColors;
  final Duration duration;
  final BorderRadius? borderRadius;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 4.0,
    this.trackColor,
    this.gradientColors,
    this.duration = const Duration(milliseconds: 600),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(99);
    final colors = gradientColors ??
        [AppColors.primaryBlueAccent, AppColors.primaryBlueSky];

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: trackColor ?? Colors.white.withValues(alpha: 0.2),
        borderRadius: radius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: radius,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
