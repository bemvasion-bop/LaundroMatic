import 'package:flutter/material.dart';

class ThemeColors {
  final bool isDark;

  const ThemeColors(this.isDark);

  // Deep, modern slate navy backgrounds
  Color get pageBg => isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F8FC);
  Color get cardBg => isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get elevatedBg => isDark ? const Color(0xFF243048) : Colors.white;
  Color get subCardBg => isDark ? const Color(0xFF172033) : const Color(0xFFF8FAFC);

  // High contrast typography for readability
  Color get textPrimary => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get textMuted => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  // Crisp 1px borders and dividers
  Color get border => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get divider => isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

  // Brand Primary (lighter in dark mode for AAA contrast)
  Color get primary => isDark ? const Color(0xFF3B82F6) : const Color(0xFF1E64D4);
  Color get primaryLight => isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFEBF2FE);

  // Status Badges & Accents
  Color get successText => isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A);
  Color get successBg => isDark ? const Color(0xFF064E3B).withValues(alpha: 0.45) : const Color(0xFFDCFCE7);

  Color get warningText => isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  Color get warningBg => isDark ? const Color(0xFF78350F).withValues(alpha: 0.45) : const Color(0xFFFEF3C7);

  Color get errorText => isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
  Color get errorBg => isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.45) : const Color(0xFFFEE2E2);

  Color get purpleText => isDark ? const Color(0xFFC084FC) : const Color(0xFF9333EA);
  Color get purpleBg => isDark ? const Color(0xFF581C87).withValues(alpha: 0.45) : const Color(0xFFF3E8FF);

  // Form inputs
  Color get inputFill => isDark ? const Color(0xFF172033) : Colors.white;
  Color get inputBorder => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
}

class ThemeController {
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;
  static bool get isDark => isDarkMode;

  static void toggleTheme() {
    themeModeNotifier.value =
        isDarkMode ? ThemeMode.light : ThemeMode.dark;
  }

  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  static ThemeColors get colors => ThemeColors(isDarkMode);

  static ThemeColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || isDarkMode;
    return ThemeColors(isDark);
  }
}
