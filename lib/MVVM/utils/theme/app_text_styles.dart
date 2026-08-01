import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static final TextStyle _baseTextStyle = GoogleFonts.inter(
    color: AppColors.textPrimary,
  );

  // Headings
  static final TextStyle h1 = _baseTextStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static final TextStyle h2 = _baseTextStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
  );

  static final TextStyle h3 = _baseTextStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static final TextStyle h4 = _baseTextStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  // Body Text
  static final TextStyle bodyLarge = _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static final TextStyle bodyMedium = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static final TextStyle bodySmall = _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  // Specific Roles
  static final TextStyle pageTitle = h2;
  
  static final TextStyle pageSubtitle = bodyMedium.copyWith(
    color: AppColors.textSecondary,
  );
  
  static final TextStyle sectionTitle = h4;
  
  static final TextStyle cardTitle = bodyLarge.copyWith(
    fontWeight: FontWeight.w600,
  );
  
  static final TextStyle cardValue = h2;
  
  static final TextStyle tableHeader = bodySmall.copyWith(
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
  
  static final TextStyle tableCell = bodyMedium;
  
  static final TextStyle formLabel = bodyMedium.copyWith(
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  
  static final TextStyle buttonText = bodyMedium.copyWith(
    fontWeight: FontWeight.w600,
  );
  
  static final TextStyle caption = bodySmall.copyWith(
    color: AppColors.textSecondary,
  );
}
