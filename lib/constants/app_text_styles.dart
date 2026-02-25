import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_constants.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppTextStyles — single source of truth for all text styles in Blackclap.
///
/// Font: Plus Jakarta Sans
///   • Modern, geometric, friendly — ideal for social media products.
///   • Used by Notion, Linear, and many design-forward apps.
///
/// Usage:
///   Text('Hello', style: AppTextStyles.titleLarge)
///   Text('@username', style: AppTextStyles.username)
/// ─────────────────────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._(); // prevent instantiation

  // ── Base factory (always Plus Jakarta Sans, textPrimary colour) ───────────
  static TextStyle _base({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Display / Hero text
  // ─────────────────────────────────────────────────────────────────────────

  /// App name / hero splash — 40 sp, ExtraBold
  static TextStyle get displayLarge => _base(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: AppColors.accent,
        letterSpacing: -1.0,
        height: 1.1,
      );

  /// Section hero headings — 32 sp, Bold
  static TextStyle get displayMedium => _base(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Headlines
  // ─────────────────────────────────────────────────────────────────────────

  /// Screen titles, large section headers — 24 sp, Bold
  static TextStyle get headlineLarge => _base(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  /// Card titles, profile name — 20 sp, SemiBold
  static TextStyle get headlineMedium => _base(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  /// Subsection titles — 18 sp, SemiBold
  static TextStyle get headlineSmall => _base(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Title / AppBar
  // ─────────────────────────────────────────────────────────────────────────

  /// AppBar brand title — 22 sp, ExtraBold, purple
  static TextStyle get titleLarge => _base(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.accent,
        letterSpacing: -0.3,
      );

  /// Dialog / sheet titles — 16 sp, SemiBold
  static TextStyle get titleMedium => _base(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  /// Small card / list tile title — 14 sp, SemiBold
  static TextStyle get titleSmall => _base(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Body
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary body text — 15 sp, Regular
  static TextStyle get bodyLarge => _base(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// Standard body / list subtitles — 14 sp, Regular
  static TextStyle get bodyMedium => _base(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// Supporting / secondary body — 13 sp, Regular, textSecondary
  static TextStyle get bodySmall => _base(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Labels & Buttons
  // ─────────────────────────────────────────────────────────────────────────

  /// Button labels — 15 sp, SemiBold
  static TextStyle get labelLarge => _base(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  /// Tab labels, chips — 13 sp, Medium
  static TextStyle get labelMedium => _base(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  /// Badge / tiny labels — 11 sp, Medium
  static TextStyle get labelSmall => _base(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Social-media–specific helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// @username in feed / profile header — SemiBold, near-black
  static TextStyle get username => _base(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Post full-name display — SemiBold, slightly larger
  static TextStyle get displayName => _base(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Post caption body text — Regular, primary colour
  static TextStyle get caption => _base(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// Relative time / location meta — 12 sp, textTertiary
  static TextStyle get timestamp => _base(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
      );

  /// Like / comment count — 13 sp, SemiBold
  static TextStyle get engagementCount => _base(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// #hashtag / @mention in captions — purple, SemiBold
  static TextStyle get hashtag => _base(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
      );

  /// Story circle label below avatar — 11 sp, truncated
  static TextStyle get storyLabel => _base(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  /// Input label / hint override — textTertiary
  static TextStyle get hint => _base(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Full Material TextTheme (applied globally in ThemeData)
  // ─────────────────────────────────────────────────────────────────────────

  /// Call this once in ThemeData to apply Plus Jakarta Sans app-wide.
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
