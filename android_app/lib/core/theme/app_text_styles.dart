import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Text Styles cho ứng dụng
class AppTextStyles {
  AppTextStyles._();

  // Base font family
  static String get _fontFamily => GoogleFonts.inter().fontFamily!;

  // Headings
  static TextStyle get h1 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get h2 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get h3 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get h4 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get h5 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get h6 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // Body Text
  static TextStyle get bodyLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // Labels
  static TextStyle get labelLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get labelMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // Button Text
  static TextStyle get buttonLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        height: 1.25,
      );

  static TextStyle get buttonMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        height: 1.25,
      );

  static TextStyle get buttonSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        height: 1.25,
      );

  // Price Text
  static TextStyle get priceLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        height: 1.2,
      );

  static TextStyle get priceMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        height: 1.2,
      );

  static TextStyle get priceSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        height: 1.2,
      );

  // Caption
  static TextStyle get caption => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textHint,
        height: 1.4,
      );

  // Overline
  static TextStyle get overline => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
        height: 1.4,
      );
}
