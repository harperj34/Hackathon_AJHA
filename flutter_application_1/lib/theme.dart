import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UniverseColors {
  // Legacy dark palette (kept for reference)
  static const royalBlue = Color(0xFF5D5CFE);
  static const skyBlue = Color(0xFF3C92FF);
  static const cyanBlue = Color(0xFF71CDFF);
  static const lavenderPurple = Color(0xFFA374F5);
  static const hotPink = Color(0xFFFF64BF);
  static const softPink = Color(0xFFFF97E7);
  static const brightYellow = Color(0xFFFFEB69);
  static const darkNavy = Color(0xFF12121B);
  static const blushPink = Color(0xFFFFD1D1);

  // Light palette
  static const accent = Color(0xFF6C63FF); // primary purple
  static const accentBlue = Color(0xFF3D8BFF); // secondary blue
  static const accentOrange = Color(0xFFFF9F43); // food/orange
  static const accentPink = Color(0xFFFF7AD9); // social/pink
  static const textPrimary = Color(0xFF0E0F1A);
  static const textMuted = Color(0xFF9094A5);
  static const textLight = Color(0xFFABAFC7);
  static const bgPage = Color(0xFFF2F2F7);     // iOS systemGray6
  static const bgCard = Colors.white;
  static const borderColor = Color(0xFFE6E8EE);
  static const divider = Color(0xFFF0F2F8);
  static const textSecondary = Color(0xFF6B7280);
  static const iosSysGray = Color(0xFF8E8E93);  // iOS systemGray
  static const iosSysGray2 = Color(0xFFAEAEB2); // iOS systemGray2
  static const iosSysGray6 = Color(0xFFF2F2F7); // iOS systemGray6 — chip/field bg

  static const primaryGradient = LinearGradient(
    colors: [accent, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cosmicGradient = LinearGradient(
    colors: [accent, accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class UniverseTheme {
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: UniverseColors.bgPage,
    fontFamily: '.SF Pro Text',
    colorScheme: const ColorScheme.light(
      primary: UniverseColors.accent,
      secondary: UniverseColors.accentBlue,
      surface: Colors.white,
    ),
    fontFamilyFallback: const ['SF Pro Text', 'Helvetica Neue', 'Arial', 'sans-serif'],
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: UniverseColors.accent,
      selectionColor: Color(0x446C63FF),
      selectionHandleColor: UniverseColors.accent,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: UniverseColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: UniverseColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: UniverseColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      titleLarge: TextStyle(
        color: UniverseColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: UniverseColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        color: UniverseColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: UniverseColors.textPrimary),
      titleTextStyle: TextStyle(
        color: UniverseColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
    ),
    dividerColor: UniverseColors.borderColor,
  );

  static ThemeData get darkTheme => lightTheme;
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand typography — Space Grotesk for display / branding moments
// ─────────────────────────────────────────────────────────────────────────────

class UniverseTextStyles {
  /// Large page / screen titles.
  static final TextStyle displayLarge = GoogleFonts.spaceGrotesk(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: UniverseColors.textPrimary,
    letterSpacing: -0.5,
  );

  /// Medium display (e.g. profile name).
  static final TextStyle displayMedium = GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: UniverseColors.textPrimary,
    letterSpacing: -0.3,
  );

  /// Section headers inside panels.
  static final TextStyle sectionHeader = GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: UniverseColors.textPrimary,
  );

  /// Bottom nav bar tab labels — SF Pro Text (inherits system font).
  static const TextStyle tabLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: UniverseColors.textMuted,
    letterSpacing: 0.1,
  );
}
