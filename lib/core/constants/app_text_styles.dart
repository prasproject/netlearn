import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// NetLearn Design System — Typography
/// All text styles use Nunito font family matching the mockup.
class AppTextStyles {
  AppTextStyles._();

  // ── Helper to get Nunito ──
  static TextStyle _nunito({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.nunito(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ── Display / Title ──
  static TextStyle splashTitle = _nunito(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: -0.5,
  );

  static TextStyle screenTitle = _nunito(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );

  static TextStyle sectionTitle = _nunito(
    fontSize: 14,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );

  static TextStyle cardTitle = _nunito(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    height: 1.2,
  );

  static TextStyle heading = _nunito(
    fontSize: 14,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ── Body ──
  static TextStyle bodyMedium = _nunito(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle bodySmall = _nunito(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static TextStyle paragraph = _nunito(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ── Labels ──
  static TextStyle labelUppercase = _nunito(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryBlueLight,
    letterSpacing: 0.96,
  );

  static TextStyle labelSmall = _nunito(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
  );

  static TextStyle labelTiny = _nunito(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: AppColors.textSecondary,
    letterSpacing: 0.64,
  );

  static TextStyle eyebrow = _nunito(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.96,
  );

  // ── Buttons ──
  static TextStyle buttonPrimary = _nunito(
    fontSize: 13,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );

  static TextStyle buttonSmall = _nunito(
    fontSize: 13,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );

  // ── Score / Stats ──
  static TextStyle scoreHuge = _nunito(
    fontSize: 28,
    fontWeight: FontWeight.w900,
  );

  static TextStyle scoreLarge = _nunito(
    fontSize: 22,
    fontWeight: FontWeight.w900,
  );

  static TextStyle scoreMedium = _nunito(
    fontSize: 18,
    fontWeight: FontWeight.w900,
  );

  static TextStyle statValue = _nunito(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );

  static TextStyle statLabel = _nunito(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  // ── Navigation ──
  static TextStyle navLabel = _nunito(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: AppColors.textDisabled,
  );

  static TextStyle navLabelActive = _nunito(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryBlue,
  );

  // ── Pill ──
  static TextStyle pillText = _nunito(
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );

  // ── Badge ──
  static TextStyle badgeName = _nunito(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: AppColors.textSecondary,
  );

  // ── Greeting ──
  static TextStyle greeting = _nunito(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white70,
  );

  static TextStyle greetingName = _nunito(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    height: 1.1,
  );

  // ── Quiz option ──
  static TextStyle quizOption = _nunito(
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  // ── Version ──
  static TextStyle versionText = _nunito(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white38,
  );

  // ── Chip ──
  static TextStyle chip = _nunito(
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );

  // ── Certificate ──
  static TextStyle certTitle = _nunito(
    fontSize: 14,
    fontWeight: FontWeight.w900,
    color: AppColors.goldLight,
    height: 1.3,
  );

  static TextStyle certName = _nunito(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );

  static TextStyle certSub = _nunito(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white60,
    height: 1.5,
  );
}
