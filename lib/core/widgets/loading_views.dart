import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_motion.dart';

/// A single shimmering placeholder block.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppDimensions.radiusSmall,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // A soft highlight sweeping left to right.
        final x = -1.0 + _c.value * 3;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(x - 1, 0),
              end: Alignment(x, 0),
              colors: const [AppColors.divider, Color(0xFFF7F9FC), AppColors.divider],
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder that mirrors the shape of a content card while data loads, so
/// the screen doesn't jump from a lone spinner to a full layout.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.lines = 2, this.hasLeading = true});

  final int lines;
  final bool hasLeading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLeading) ...[
            const SkeletonBox(width: 42, height: 42, radius: 12),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines; i++) ...[
                  SkeletonBox(width: i == 0 ? 140 : null, height: i == 0 ? 14 : 10),
                  if (i != lines - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen loading state with the product's own identity instead of a bare
/// `CircularProgressIndicator`.
class AppLoader extends StatefulWidget {
  const AppLoader({super.key, this.message, this.color = AppColors.primaryBlue});

  final String? message;
  final Color color;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Three packets travelling along a wire — the app's own metaphor.
          SizedBox(
            width: 74,
            height: 22,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: widget.color.withValues(alpha: 0.15),
                  ),
                  for (var i = 0; i < 3; i++)
                    Align(
                      alignment: Alignment(-1 + ((_c.value + i / 3) % 1) * 2, 0),
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color.withValues(
                            alpha: 0.35 + 0.65 * ((_c.value + i / 3) % 1),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 12),
            AnimatedDefaultTextStyle(
              duration: AppMotion.normal,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
              child: Text(widget.message!),
            ),
          ],
        ],
      ),
    );
  }
}
