import 'package:flutter/material.dart';

class AppColors {
  // Brand colors matching the weekly-walk-layout aesthetic
  static const Color background = Color(0xFFF5F7F2); // Warm creamy sage
  static const Color darkBackground = Color(0xFF111714); // Deep night forest
  static const Color surface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF1A231F); // Dark card surface
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color darkCardBg = Color(0xFF1A231F);

  // Deep Forest Green (Primary action, active ring, active button)
  static const Color forestGreen = Color(0xFF1E5245);
  static const Color forestGreenLight = Color(0xFF2E6A5B);
  static const Color forestGreenDark = Color(0xFF13382F);
  static const Color forestGreenAccent = Color(0xFF389E80); // Brighter green for dark mode contrast

  // Soft Tint Green (Progress track, light chips)
  static const Color softGreenTint = Color(0xFFE4EDE7);
  static const Color darkSoftGreenTint = Color(0xFF22312A);
  static const Color softGreenBorder = Color(0xFFD4E3DB);

  // Star / Streak warm terracotta
  static const Color streakOrange = Color(0xFFF28F3B);
  static const Color streakBg = Color(0xFFFFF2E6);
  static const Color darkStreakBg = Color(0xFF302217);

  // Capybara accents
  static const Color capyBrown = Color(0xFFB07238);
  static const Color capyHeadbandBlue = Color(0xFF3A86FF);

  // Text colors
  static const Color textDark = Color(0xFF1B2D26);
  static const Color textLight = Color(0xFFF0F5F2);
  static const Color textSecondary = Color(0xFF6B7D75);
  static const Color textSecondaryLight = Color(0xFFA0B0A8);
  static const Color textMuted = Color(0xFFA1AEA7);
  static const Color textMutedDark = Color(0xFF62736B);

  // Borders & Dividers
  static const Color border = Color(0xFFE5ECE8);
  static const Color darkBorder = Color(0xFF293730);
  static const Color divider = Color(0xFFEBF1ED);
  static const Color darkDivider = Color(0xFF222E28);

  // Legacy/Activity colors
  static const Color walkColor = Color(0xFF1E5245);
  static const Color jogColor = Color(0xFF5E3A87);
  static const Color runColor = Color(0xFF5E3A87); // Elegancki, lekko ciemny fiolet

  // Bulletproof theme helpers (accepts bool or BuildContext)
  static bool isDark([dynamic contextOrBool]) {
    if (contextOrBool is bool) return contextOrBool;
    if (contextOrBool is BuildContext) {
      try {
        return Theme.of(contextOrBool).brightness == Brightness.dark;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  static Color bg([dynamic c]) => isDark(c) ? darkBackground : background;
  static Color card([dynamic c]) => isDark(c) ? darkCardBg : Colors.white;
  static Color cardBorder([dynamic c]) => isDark(c) ? darkBorder : border;
  static Color text([dynamic c]) => isDark(c) ? textLight : textDark;
  static Color subtext([dynamic c]) => isDark(c) ? textSecondaryLight : textSecondary;
  static Color tint([dynamic c]) => isDark(c) ? darkSoftGreenTint : softGreenTint;
  static Color starBg([dynamic c]) => isDark(c) ? darkStreakBg : streakBg;
}
