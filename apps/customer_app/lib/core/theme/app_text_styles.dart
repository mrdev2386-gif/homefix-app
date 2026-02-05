import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Premium typography system for HomeFix
class AppTextStyles {
  // Display Styles (Large headings)
  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static TextStyle displayMedium = GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static TextStyle displaySmall = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  // Headline Styles
  static TextStyle headlineLarge = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static TextStyle headlineMedium = GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static TextStyle headlineSmall = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // Title Styles
  static TextStyle titleLarge = GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static TextStyle titleMedium = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static TextStyle titleSmall = GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // Body Styles
  static TextStyle bodyLarge = GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static TextStyle bodyMedium = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static TextStyle bodySmall = GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  // Label Styles
  static TextStyle labelLarge = GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static TextStyle labelMedium = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
  );
  
  static TextStyle labelSmall = GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    height: 1.3,
  );
  
  // Button Styles
  static TextStyle buttonLarge = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.2,
  );
  
  static TextStyle buttonMedium = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.2,
  );
  
  static TextStyle buttonSmall = GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.2,
  );
  
  // Caption & Overline
  static TextStyle caption = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.3,
  );
  
  static TextStyle overline = GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AppColors.textSecondary,
    height: 1.2,
  );
  
  // Price Styles
  static TextStyle priceLarge = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: AppColors.primary,
    height: 1.2,
  );
  
  static TextStyle priceMedium = GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    height: 1.2,
  );
  
  static TextStyle priceSmall = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.2,
  );
}
