import 'package:flutter/material.dart';

/// NetLearn Design System — Color Palette
///
/// Pastel scheme tuned for high-school students: the old navy/forest tones read
/// as formal and corporate, so every family was softened toward a friendlier
/// hue while keeping each colour's role and name unchanged.
///
/// Base tones are kept dark enough to carry white text (contrast ≥ 4.0 against
/// white — a pastel that is too light makes the headers unreadable), while
/// surfaces and accents carry the actual pastel feel.
class AppColors {
  AppColors._();

  // ── Primary Blue (denim / langit) ──
  //
  // Deliberately sits at hue ~210 rather than the ~230 indigo every default
  // template ships with: the violet-leaning blue made the app look generic.
  static const Color primaryBlue = Color(0xFF35699C);
  static const Color primaryBlueDark = Color(0xFF274F78);
  static const Color primaryBlueLight = Color(0xFF5B8FBF);
  static const Color primaryBlueSurface = Color(0xFFE7F0F8);
  static const Color primaryBlueAccent = Color(0xFFA8D0EE);
  static const Color primaryBlueSky = Color(0xFF79C2E8);

  // ── Secondary Green (mint) ──
  static const Color secondaryGreen = Color(0xFF2F8F5B);
  static const Color secondaryGreenDark = Color(0xFF216A42);
  static const Color secondaryGreenLight = Color(0xFF46B078);
  static const Color secondaryGreenSurface = Color(0xFFE6F7EE);
  static const Color secondaryGreenAccent = Color(0xFFA8E6C1);

  // ── Accent Orange (apricot) ──
  static const Color accentOrange = Color(0xFFC1662F);
  static const Color accentOrangeDark = Color(0xFF9B5022);
  static const Color accentOrangeLight = Color(0xFFE08C4E);
  static const Color accentOrangeSurface = Color(0xFFFDF0E6);
  static const Color accentOrangeWarm = Color(0xFFFFC48A);
  static const Color accentOrangeGold = Color(0xFFFFB458);

  // ── Purple (grape) ──
  //
  // Pulled away from the blue-violet end so it reads as its own colour next to
  // the denim primary rather than as a second shade of the same template blue.
  static const Color purple = Color(0xFF7A5C9E);
  static const Color purpleDark = Color(0xFF5F4680);
  static const Color purpleLight = Color(0xFF9A80BB);
  static const Color purpleSurface = Color(0xFFF2ECF8);
  static const Color purpleAccent = Color(0xFFD3C0E8);

  // ── Quiz Pink (rose) ──
  static const Color quizPink = Color(0xFFC75A86);
  static const Color quizPinkDark = Color(0xFFA4416A);
  static const Color quizPinkLight = Color(0xFFD87FA3);
  static const Color quizPinkSurface = Color(0xFFFCEBF1);
  static const Color quizPinkAccent = Color(0xFFF6B6CD);

  // ── Progress Teal (sea) ──
  static const Color progressTeal = Color(0xFF2E88A0);
  static const Color progressTealLight = Color(0xFF45A6C0);
  static const Color progressTealSurface = Color(0xFFE6F5F9);
  static const Color progressTealAccent = Color(0xFF8FD8E8);
  static const Color progressTealPale = Color(0xFFC9EDF5);

  // ── Post-Test (slate) ──
  static const Color postDark = Color(0xFF4A5D75);
  static const Color postDarker = Color(0xFF36455A);
  static const Color postGray = Color(0xFF6B7F96);
  static const Color postMuted = Color(0xFFA7B6C7);
  static const Color postSurface = Color(0xFFEEF2F7);
  static const Color postTeal = Color(0xFF9BD8D1);
  static const Color postTealLight = Color(0xFF66BFB5);

  // ── Gamification ──
  static const Color gold = Color(0xFFF2B93B);
  static const Color goldDark = Color(0xFFD99A1F);
  static const Color goldSurface = Color(0xFFFFF7E6);
  static const Color goldLight = Color(0xFFFFD98A);

  // ── Neutrals ──
  static const Color background = Color(0xFFF3F6FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE9ECF5);
  static const Color textPrimary = Color(0xFF26263D);
  static const Color textSecondary = Color(0xFF5A5A72);
  static const Color textMuted = Color(0xFF8C8CA1);
  static const Color textDisabled = Color(0xFFBFBFD0);
  static const Color divider = Color(0xFFEDEFF6);

  // ── Dark Mode Neutrals ──
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);

  /// Brand gradient used on headers and auth screens.
  ///
  /// Three stops (a lighter sky at the top, denim in the middle, deep navy at
  /// the bottom) so a large area has depth instead of reading as one flat slab
  /// of colour — which is what made the old screens feel template-generated.
  static const List<Color> brandGradient = [Color(0xFF4C86BE), primaryBlue, Color(0xFF22456A)];

  static const List<double> brandGradientStops = [0.0, 0.45, 1.0];

  /// Green counterpart, used on the register screen.
  static const List<Color> greenGradient = [
    Color(0xFF47A874),
    secondaryGreen,
    Color(0xFF1B5437),
  ];

  // ── Status Colors ──
  static const Color success = Color(0xFF45B26B);
  static const Color error = Color(0xFFE5614F);
  static const Color warning = Color(0xFFF0A63C);
  static const Color info = Color(0xFF5B9BE8);
}
