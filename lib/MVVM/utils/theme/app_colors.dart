import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFF0F172A); // Deep Navy Blue
  static const Color secondary = Color(0xFF1E293B); // Lighter Navy
  static const Color accent = Color(0xFFFFC107); // Yellow / Gold

  // Background & Surface
  static const Color background = Color(0xFFF1F5F9); // Light Grey
  static const Color surface = Colors.white; // White Cards
  static const Color hover = Color(0xFFF8FAFC);
  static const Color selected = Color.fromARGB(
    255,
    255,
    255,
    255,
  ); // Soft light yellow

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Dark Navy
  static const Color textSecondary = Color(0xFF64748B); // Grey
  static const Color textHint = Color(0xFF94A3B8); // Light Grey
  static const Color textInverse = Colors.white; // White Text

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color focusedBorder = Color(0xFF0F172A);

  // Semantic Colors
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Orange
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // Opacity / Overlay
  static const Color overlay = Color(0x1A000000); // 10% Black
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF1F5F9);
}
