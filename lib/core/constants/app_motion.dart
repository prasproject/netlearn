import 'package:flutter/animation.dart';

/// NetLearn Design System — Motion
///
/// One place for timing and curves so every animation in the app feels like it
/// belongs to the same product instead of each screen inventing its own.
class AppMotion {
  AppMotion._();

  /// Small state changes: a switch, a chip, a colour change.
  static const Duration fast = Duration(milliseconds: 180);

  /// Default for most UI movement: cards, sheets, list items.
  static const Duration normal = Duration(milliseconds: 280);

  /// Bigger moments: page content settling in, celebration states.
  static const Duration slow = Duration(milliseconds: 420);

  /// Delay between items of a staggered list entrance.
  static const Duration stagger = Duration(milliseconds: 55);

  /// Standard easing for things entering or settling.
  static const Curve enter = Curves.easeOutCubic;

  /// Easing for things responding to a press.
  static const Curve press = Curves.easeOut;

  /// A gentle overshoot for rewards and confirmations.
  static const Curve pop = Curves.easeOutBack;
}
