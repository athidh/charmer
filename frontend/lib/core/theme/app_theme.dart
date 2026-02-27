import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── CHARMER Palette — Earth + Tech ──
  static const Color forestGreen = Color(0xFF2D5A27);
  static const Color forestGreenLight = Color(0xFF3D7A35);
  static const Color forestGreenDark = Color(0xFF1E3D1A);
  static const Color sunsetOrange = Color(0xFFFF8C00);
  static const Color sunsetOrangeLight = Color(0xFFFFAB40);
  static const Color sunsetOrangeDark = Color(0xFFE67E00);

  // New CHARMER accent colors
  static const Color deepSoil = Color(0xFF5D3A1A);
  static const Color skyClimate = Color(0xFF0097A7);
  static const Color riceGold = Color(0xFFD4A637);
  static const Color voicePurple = Color(0xFF7C4DFF);

  // Semantic Colors
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF43A047);
  static const Color infoBlue = Color(0xFF1E88E5);
  static const Color warningAmber = Color(0xFFFFA726);

  // Light Theme Surface Colors
  static const Color backgroundLight = Color(0xFFF7F9F7);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimary = Color(0xFF1A1D1A);
  static const Color textSecondary = Color(0xFF6B7B6B);

  // Dark Theme Surface Colors
  static const Color backgroundDark = Color(0xFF0A0F0A);
  static const Color surfaceDark = Color(0xFF151A15);
  static const Color textPrimaryDark = Color(0xFFF0F5F0);
  static const Color textSecondaryDark = Color(0xFF8FA08F);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forestGreen, forestGreenLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sunsetOrange, sunsetOrangeLight],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [forestGreenDark, forestGreen, forestGreenLight],
  );

  static const LinearGradient voiceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [voicePurple, skyClimate],
  );

  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      background: backgroundLight,
      surface: surfaceLight,
      textColor: textPrimary,
      secondaryTextColor: textSecondary,
      primary: forestGreen,
    );
  }

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      background: backgroundDark,
      surface: surfaceDark,
      textColor: textPrimaryDark,
      secondaryTextColor: textSecondaryDark,
      primary: forestGreenLight,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color textColor,
    required Color secondaryTextColor,
    required Color primary,
  }) {
    final bool isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: sunsetOrange,
        tertiary: skyClimate,
        error: errorRed,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: textColor,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w800,
          fontSize: 40,
          color: textColor,
          letterSpacing: -1.5,
        ),
        displayMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 32,
          color: textColor,
          letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 28,
          color: textColor,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: textColor,
        ),
        titleLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: textColor,
        ),
        titleMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: textColor,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          color: textColor,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: secondaryTextColor,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forestGreen,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: forestGreen, width: 1.5),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: forestGreen, width: 2),
        ),
        labelStyle: TextStyle(color: secondaryTextColor),
        hintStyle: TextStyle(color: secondaryTextColor),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.shade200,
        thickness: 1,
      ),
    );
  }
}
