import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: AppColors.lightScheme,
        textTheme: AppTypography.textTheme,
        scaffoldBackgroundColor: AppColors.backgroundStart,
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          space: 1,
          thickness: 1,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: AppColors.surfaceGlass,
          margin: EdgeInsets.zero,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: AppColors.darkScheme,
        textTheme: AppTypography.textTheme,
      );
}
