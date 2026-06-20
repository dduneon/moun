import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  static const _family = 'Pretendard';

  static TextStyle _t({
    required double size,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _family,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextTheme get textTheme => TextTheme(
        displayLarge: _t(size: 40, weight: FontWeight.w700, letterSpacing: -1.0),
        displayMedium: _t(size: 32, weight: FontWeight.w700, letterSpacing: -0.5),
        displaySmall: _t(size: 28, weight: FontWeight.w600, letterSpacing: -0.5),
        headlineLarge: _t(size: 24, weight: FontWeight.w700, letterSpacing: -0.3),
        headlineMedium: _t(size: 20, weight: FontWeight.w600, letterSpacing: -0.2),
        headlineSmall: _t(size: 18, weight: FontWeight.w600),
        titleLarge: _t(size: 16, weight: FontWeight.w600),
        titleMedium: _t(size: 15, weight: FontWeight.w500),
        titleSmall: _t(size: 14, weight: FontWeight.w500),
        bodyLarge: _t(size: 16, weight: FontWeight.w400),
        bodyMedium: _t(size: 14, weight: FontWeight.w400),
        bodySmall: _t(size: 12, weight: FontWeight.w400, color: AppColors.textSecondary),
        labelLarge: _t(size: 14, weight: FontWeight.w500),
        labelMedium: _t(size: 12, weight: FontWeight.w500, color: AppColors.textSecondary),
        labelSmall: _t(size: 11, weight: FontWeight.w400, color: AppColors.textSecondary, letterSpacing: 0.4),
      );

  static TextStyle amountLarge = _t(size: 36, weight: FontWeight.w700, letterSpacing: -1.0);
  static TextStyle amountMedium = _t(size: 24, weight: FontWeight.w700, letterSpacing: -0.5);
  static TextStyle amountSmall = _t(size: 18, weight: FontWeight.w600, letterSpacing: -0.3);
}
