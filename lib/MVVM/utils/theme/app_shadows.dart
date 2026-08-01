import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static final List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.overlay.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> popup = [
    BoxShadow(
      color: AppColors.overlay.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> dropdown = [
    BoxShadow(
      color: AppColors.overlay.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> hover = [
    BoxShadow(
      color: AppColors.overlay.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];
}
