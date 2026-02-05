import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Color Palette
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color secondaryColor = Color(0xFF8B5CF6); // Violet
  static const Color accentColor = Color(0xFFF4F7FF); // Soft wash
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  
  static const Color backgroundColor = Color(0xFFFBFBFE);
  static const Color surfaceColor = Colors.white;
  static const Color textColor = Color(0xFF0F172A); // Deep slate
  static const Color subtitleColor = Color(0xFF64748B); // Muted slate

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSurface: textColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 24,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: subtitleColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.outfit(
          color: primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor, size: 24),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          fontFamily: 'Outfit',
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          shadowColor: primaryColor.withOpacity(0.3),
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
          foregroundColor: primaryColor,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        hintStyle: GoogleFonts.outfit(
          color: Colors.grey.shade400,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 10,
        height: 80,
        indicatorColor: primaryColor.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return GoogleFonts.outfit(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            );
          }
          return GoogleFonts.outfit(
            color: subtitleColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primaryColor, size: 26);
          }
          return const IconThemeData(color: subtitleColor, size: 24);
        }),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme.copyWith(brightness: Brightness.dark); // Simplified for now
}
