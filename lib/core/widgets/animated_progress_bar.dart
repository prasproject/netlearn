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
    final colors =
        gradientColors ?? [AppColors.primaryBlueAccent, AppColors.primaryBlueSky];
    final value = progress.clamp(0.0, 1.0);

    // `width: double.infinity` matters: the fill used to live in a loose Stack,
    // so the track shrank to the width of the fill. Inside a centred Column
    // (the home header) that made the whole bar look like it grew outward from
    // the middle instead of filling from the left.
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: trackColor ?? Colors.white.withValues(alpha: 0.2),
          borderRadius: radius,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) => FractionallySizedBox(
              widthFactor: animated,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: radius,
                ),
                child: SizedBox(height: height),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
