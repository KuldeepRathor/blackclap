import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Blackclap Dark Theme
  static const Color primary = Color(0xFF0A0A0A); // Deep black
  static const Color primaryLight = Color(0xFF1A1A1A); // Lighter black
  static const Color primaryDark = Color(0xFF000000); // Pure black

  // Neutral Greys - Dark Theme Support
  static const Color neutral50 = Color(0xFFE5E5E5);
  static const Color neutral100 = Color(0xFFD4D4D4);
  static const Color neutral200 = Color(0xFFA3A3A3);
  static const Color neutral300 = Color(0xFF737373);
  static const Color neutral400 = Color(0xFF525252);
  static const Color neutral500 = Color(0xFF404040);
  static const Color neutral600 = Color(0xFF2A2A2A);
  static const Color neutral700 = Color(0xFF1A1A1A);
  static const Color neutral800 = Color(0xFF0F0F0F);
  static const Color neutral900 = Color(0xFF000000);

  // Accent 1 - Actionable Blue
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentBlueLight = Color(0xFF3B82F6);
  static const Color accentBlueDark = Color(0xFF1E3A8A);

  // Accent 2 - Purple/Magenta for brand
  static const Color accent = Color(0xFF9333EA); // Vibrant purple
  static const Color accentLight = Color(0xFFC026D3);
  static const Color accentDark = Color(0xFF6D28D9);

  // Keep secondary for backward compatibility
  static const Color secondary = accentBlue;
  static const Color secondaryLight = accentBlueLight;
  static const Color secondaryDark = accentBlueDark;

  // Dark Theme Surfaces
  static const Color background = primary;
  static const Color surface = primaryLight;
  static const Color surfaceVariant = neutral600;

  // Light Theme Surfaces
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F0F0);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightOnBackground = Color(0xFF0A0A0A);
  static const Color lightOnSurface = Color(0xFF1A1A1A);
  static const Color lightIconMuted = Color(0xFF9E9E9E);

  // Text Colors
  static const Color onPrimary = Color(0xFFFFFFFF); // White text
  static const Color onSecondary = neutral100; // Better contrast text on blue
  static const Color onAccent = Color(0xFFFFFFFF); // White text on purple
  static const Color onBackground = neutral100;
  static const Color onSurface = neutral100;

  // Social Interaction Colors
  static const Color like = Color(0xFFFF6B6B);   // Red for likes
  static const Color comment = Color(0xFF14B8A6); // Teal for comments
  static const Color share = Color(0xFF22C55E);   // Green for shares
  static const Color save = accent;               // Purple for saves

  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF97316); // Orange instead of purple
  static const Color error = Color(0xFFEF4444);
  static const Color info = accentBlue;

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [accent, accentBlue, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [accentBlue, accentBlueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static const Color shadow = Color(0x40000000);
  static const Color shadowMedium = Color(0x66000000);
  static const Color shadowHigh = Color(0x80000000);

  // Transparent overlays
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
  static const Color overlayHeavy = Color(0xCC000000);
}

class AppColorScheme {
  static ColorScheme get darkScheme => ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    error: AppColors.error,
    onError: AppColors.onPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
  );

  static ColorScheme get lightScheme => ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.light,
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    secondary: AppColors.accentBlue,
    onSecondary: AppColors.onAccent,
    error: AppColors.error,
    onError: AppColors.onAccent,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface,
    surfaceContainerHighest: AppColors.lightSurfaceVariant,
  );
}

/// Returns the correct ThemeData for light and dark modes.
class AppThemeData {
  static ThemeData get darkTheme => ThemeData(
    colorScheme: AppColorScheme.darkScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.neutral400,
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 2,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.neutral600),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.neutral600),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.accent),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.neutral600),
    iconTheme: const IconThemeData(color: AppColors.onSurface),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.accent : AppColors.neutral400,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.accent.withValues(alpha: 0.4)
            : AppColors.neutral600,
      ),
    ),
  );

  static ThemeData get lightTheme => ThemeData(
    colorScheme: AppColorScheme.lightScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.lightBackground,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightOnSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Color(0x14000000),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.lightIconMuted,
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.lightSurface,
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      shadowColor: Color(0x1A000000),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurfaceVariant,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.accent),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.lightBorder),
    iconTheme: const IconThemeData(color: AppColors.lightOnSurface),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.accent : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.accent.withValues(alpha: 0.4)
            : AppColors.lightBorder,
      ),
    ),
  );
}
