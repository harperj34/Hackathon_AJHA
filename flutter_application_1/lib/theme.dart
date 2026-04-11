import 'package:flutter/material.dart';

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
  static const bgPage = Color(0xFFF5F6FA);
  static const bgCard = Colors.white;
  static const borderColor = Color(0xFFE6E8EE);
  static const divider = Color(0xFFF0F2F8);

  static const primaryGradient = LinearGradient(
    colors: [accent, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cosmicGradient = LinearGradient(
    colors: [accent, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class UniverseTheme {
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: UniverseColors.bgPage,
    colorScheme: const ColorScheme.light(
      primary: UniverseColors.accent,
      secondary: UniverseColors.accentBlue,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: UniverseColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
  );

  static ThemeData get darkTheme => lightTheme;
}
