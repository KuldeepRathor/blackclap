import 'package:flutter/material.dart';

class AppColors {
  // ── Primary Colors [ Shades of White / Off-White ] ──────────────────────
  static const Color primary = Color(0xFFFFFFFF); // Pure white
  static const Color primaryLight =
      Color(0xFFF9F9F9); // Near-white (lightest surface)
  static const Color primaryDark =
      Color(0xFFF0F0F0); // Slightly deeper white/grey

  // ── Secondary Colors [ Shades of Black ] ─────────────────────────────────
  static const Color secondary =
      Color(0xFF0D0D0D); // Near-black (headlines / icons)
  static const Color secondaryLight =
      Color(0xFF2C2C2C); // Dark grey (body text)
  static const Color secondaryDark = Color(0xFF000000); // Pure black

  // ── Tertiary / Accent [ Shades of Purple – Social Media Brand ] ──────────
  static const Color accent = Color(0xFF7C3AED); // Vibrant purple-600
  static const Color accentLight = Color(0xFFA855F7); // Soft purple-400
  static const Color accentDark = Color(0xFF5B21B6); // Deep purple-800
  static const Color accentSurface =
      Color(0xFFF3E8FF); // Ultra-light purple tint (bg chips)

  // ── Neutral Greys [ Light-Theme Support ] ────────────────────────────────
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 =
      Color(0xFFA3A3A3); // placeholder / inactive icons
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);

  // ── Surfaces & Backgrounds ───────────────────────────────────────────────
  static const Color background = primary; // White canvas
  static const Color surface = primaryLight; // Card / nav surface
  static const Color surfaceVariant =
      neutral100; // Input fill / subtle container
  static const Color divider = neutral200; // Divider lines

  // ── Text on Surfaces ────────────────────────────────────────────────────
  static const Color onPrimary = secondary; // Dark text on white
  static const Color onSecondary = Color(0xFFFFFFFF); // White text on dark
  static const Color onAccent = Color(0xFFFFFFFF); // White text on purple
  static const Color onBackground = secondary;
  static const Color onSurface = secondary;

  // ── Semantic Text Colours (light-theme safe) ─────────────────────────────
  /// Bold headlines, usernames – near-black
  static const Color textPrimary = Color(0xFF0D0D0D);

  /// Body text, captions – dark grey
  static const Color textSecondary = Color(0xFF525252);

  /// Timestamps, meta text – medium grey (still readable on white)
  static const Color textTertiary = Color(0xFF737373);

  /// Avatar initials on accent bg – always white
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ── UI Element Helpers ────────────────────────────────────────────────────
  /// Image loading placeholder / empty thumbnail bg
  static const Color imagePlaceholder = Color(0xFFE5E5E5);

  /// Interest / hashtag chip background
  static const Color chipBackground = Color(0xFFEDE9FE); // very light purple

  // ── Social Interaction Colors ────────────────────────────────────────────
  static const Color like = Color(0xFFEF4444); // Red – likes/heart
  static const Color comment = Color(0xFF0EA5E9); // Sky-blue – comments
  static const Color share = Color(0xFF22C55E); // Green – share
  static const Color save = accent; // Purple – save/bookmark

  // ── Semantic Colors ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [accentLight, accent, accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [accentLight, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient storyRingGradient = LinearGradient(
    colors: [Color(0xFFF472B6), accent, Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows ──────────────────────────────────────────────────────────────
  static const Color shadow = Color(0x14000000); // 8 % opacity – light shadow
  static const Color shadowMedium = Color(0x29000000); // 16 %
  static const Color shadowHigh = Color(0x3D000000); // 24 %

  // ── Overlays ─────────────────────────────────────────────────────────────
  static const Color overlay = Color(0x66000000);
  static const Color overlayLight = Color(0x33000000);
  static const Color overlayHeavy = Color(0xCC000000);
}

class AppColorScheme {
  /// Light theme – white primary / black secondary / purple tertiary
  static ColorScheme get lightScheme => ColorScheme(
        brightness: Brightness.light,

        // Primary = shades of white
        primary: AppColors.primaryDark, // subtle off-white used as bg accent
        onPrimary: AppColors.secondary, // dark text on white

        // Secondary = shades of black
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,

        // Tertiary = purple brand colour
        tertiary: AppColors.accent,
        onTertiary: AppColors.onAccent,

        // Surfaces
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerHighest: AppColors.surfaceVariant,

        error: AppColors.error,
        onError: AppColors.onSecondary,
      );

  // Keep dark scheme for future reference if needed
  static ColorScheme get darkScheme => ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
      );
}
