import 'package:flutter/material.dart';

class UniverseColors {
  static const royalBlue = Color(0xFF5D5CFE);
  static const skyBlue = Color(0xFF3C92FF);
  static const cyanBlue = Color(0xFF71CDFF);
  static const lavenderPurple = Color(0xFFA374F5);
  static const hotPink = Color(0xFFFF64BF);
  static const softPink = Color(0xFFFF97E7);
  static const brightYellow = Color(0xFFFFEB69);
  static const darkNavy = Color(0xFF12121B);
  static const blushPink = Color(0xFFFFD1D1);

  static const primaryGradient = LinearGradient(
    colors: [royalBlue, lavenderPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [skyBlue, cyanBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cosmicGradient = LinearGradient(
    colors: [royalBlue, lavenderPurple, hotPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class UniverseTheme {
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: UniverseColors.darkNavy,
        colorScheme: const ColorScheme.dark(
          primary: UniverseColors.royalBlue,
          secondary: UniverseColors.lavenderPurple,
          surface: Color(0xFF1C1C2E),
        ),
        fontFamily: 'SF Pro Display',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1C1C2E),
          selectedItemColor: UniverseColors.royalBlue,
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1C1C2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
      );
}
