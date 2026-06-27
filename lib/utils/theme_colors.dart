import 'package:flutter/material.dart';

/// Adaptive color helpers — returns dark-theme values in dark mode,
/// light-appropriate values in light mode. Use via BuildContext extension.
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Primary text — usernames, titles, captions
  Color get primaryText =>
      isDark ? const Color(0xFFD4D4D4) : const Color(0xFF0A0A0A);

  /// Secondary text — subtitles, light labels
  Color get secondaryText =>
      isDark ? const Color(0xFFA3A3A3) : const Color(0xFF3D3D3D);

  /// Muted text — timestamps, counts, hints
  Color get mutedText =>
      isDark ? const Color(0xFF737373) : const Color(0xFF666666);

  /// Icon color — inactive/outline icons
  Color get iconColor =>
      isDark ? const Color(0xFFA3A3A3) : const Color(0xFF444444);

  /// Divider / border color
  Color get dividerColor =>
      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5);

  /// Skeleton / shimmer base
  Color get shimmerBase =>
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0);

  /// Skeleton / shimmer highlight
  Color get shimmerHighlight =>
      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0);
}
