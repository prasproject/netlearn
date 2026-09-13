import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_shadows.dart';
import 'pressable.dart';

/// The app's standard white card.
///
/// Screens used to build this by hand with slightly different radii, borders,
/// and shadows each time; routing them through one widget is what makes the UI
/// read as a single, calm system.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.enabled = true,
    this.accent,
    this.raised = false,
    this.radius = AppDimensions.radiusXL,
    this.background = AppColors.surface,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool enabled;

  /// Draws a coloured spine on the left edge, used to tag a card's category.
  final Color? accent;

  /// Slightly stronger shadow for the card the user is meant to act on.
  final bool raised;
  final double radius;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: accent != null
            ? Border(left: BorderSide(color: accent!, width: 4))
            : Border.all(color: AppColors.cardBorder),
        boxShadow: raised ? AppShadows.raised : AppShadows.card,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Pressable(
      onTap: onTap,
      enabled: enabled,
      borderRadius: BorderRadius.circular(radius),
      child: card,
    );
  }
}

/// Small uppercase label that introduces a group of content.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.color = AppColors.primaryBlue,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(width: 8),
          if (icon != null) ...[Icon(icon, size: 15, color: color), const SizedBox(width: 6)],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: color,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
