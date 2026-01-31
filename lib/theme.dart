import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF8B5CF6); // Electric Violet
  static const Color secondaryColor = Color(0xFF2DD4BF); // Cyber Turquoise
  static const Color accentColor = Color(0xFF8B5CF6);
  static const Color emeraldColor = Color(0xFF10B981); // Neon Emerald
  static const Color amberColor = Color(0xFFF59E0B); // Sunset Orange
  static const Color roseColor = Color(0xFFEF4444); // Cyber Red

  static const Color backgroundDark = Color(0xFF020617); // Deep Obsidian
  static const Color surfaceDark = Color(0xFF050505); // Pure Void
  static const Color textMain = Color(0xFFF8FAFC); // Slate 50
  static const Color textSub = Color(0xFF94A3B8); // Slate 400

  // Glassmorphism Constants
  static BoxDecoration glassDecoration(
      {double opacity = 0.05, double blur = 20}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.1),
        width: 1,
      ),
    );
  }

  static List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static TextStyle headingStyle({double fontSize = 24, Color? color}) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: color ?? textMain,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundDark,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceDark,
        background: backgroundDark,
        brightness: Brightness.dark,
      ),

      // Modern Typography
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: textMain,
          fontSize: 32,
        ),
        displayMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: textMain,
          fontSize: 28,
        ),
        titleLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: textMain,
          fontSize: 22,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textMain,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSub,
          fontSize: 14,
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMain),
        titleTextStyle: TextStyle(
          color: textMain,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  // Premium Mesh Background Helper
  static Widget meshBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [backgroundDark, surfaceDark],
            ),
          ),
        ),
        Positioned(
          top: -200,
          right: -100,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.12),
                  primaryColor.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  secondaryColor.withValues(alpha: 0.08),
                  secondaryColor.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
