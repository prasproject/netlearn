import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_motion.dart';

/// Wraps any tappable surface with a subtle press-down animation.
///
/// The app previously used bare `GestureDetector`s, so cards gave no feedback
/// at all when tapped — on a card that navigates elsewhere it felt like the tap
/// had been missed. This adds a short scale + haptic tick, and dims disabled
/// items consistently.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.scale = 0.97,
    this.disabledOpacity = 0.55,
    this.haptic = true,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;

  /// How far the surface shrinks while held.
  final double scale;
  final double disabledOpacity;
  final bool haptic;

  /// Used for the ink splash when provided.
  final BorderRadius? borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  bool get _active => widget.enabled && widget.onTap != null;

  void _setDown(bool value) {
    if (!_active || _down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setDown(true),
      onTapUp: (_) => _setDown(false),
      onTapCancel: () => _setDown(false),
      onTap: _active
          ? () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!.call();
            }
          : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      child: AnimatedOpacity(
        duration: AppMotion.fast,
        opacity: widget.enabled ? 1 : widget.disabledOpacity,
        child: AnimatedScale(
          duration: AppMotion.fast,
          curve: AppMotion.press,
          scale: _down ? widget.scale : 1,
          child: widget.child,
        ),
      ),
    );
  }
}
