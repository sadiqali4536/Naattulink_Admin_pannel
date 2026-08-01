import 'package:flutter/material.dart';

class AppAnimation {
  AppAnimation._();

  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve decelerationCurve = Curves.easeOutCubic;
  static const Curve accelerationCurve = Curves.easeInCubic;
  static const Curve bounceCurve = Curves.elasticOut;
}
