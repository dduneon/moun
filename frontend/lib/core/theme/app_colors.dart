import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF5B8DEF);
  static const primaryGradientEnd = Color(0xFF7C6FF0);

  // Background
  static const backgroundStart = Color(0xFFF7F8FC);
  static const backgroundEnd = Color(0xFFFFFFFF);

  // Surface
  static const surfaceGlass = Color(0xB3FFFFFF); // white 70%
  static const surfaceGlassBorder = Color(0x4DFFFFFF); // white 30%

  // Semantic
  static const income = Color(0xFF34C77B);
  static const expense = Color(0xFFFF6B6B);
  static const expensePending = Color(0xFFB39DFF);
  static const saving = Color(0xFF3AB0D9);

  // Text
  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF8E8E93);

  // Divider
  static const divider = Color(0x0F000000); // rgba(0,0,0,0.06)

  // --- Light ColorScheme ---
  static ColorScheme get lightScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD8E4FF),
        onPrimaryContainer: Color(0xFF001849),
        secondary: primaryGradientEnd,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE5DEFF),
        onSecondaryContainer: Color(0xFF1B0066),
        tertiary: income,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFB8F5D4),
        onTertiaryContainer: Color(0xFF002115),
        error: expense,
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),
        surface: backgroundEnd,
        onSurface: textPrimary,
        surfaceContainerHighest: Color(0xFFECEFF4),
        onSurfaceVariant: textSecondary,
        outline: Color(0xFFBEC6DC),
        outlineVariant: divider,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF2F3033),
        onInverseSurface: Color(0xFFF0F0F4),
        inversePrimary: Color(0xFFADC6FF),
      );

  // --- Dark ColorScheme ---
  static ColorScheme get darkScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFADC6FF),
        onPrimary: Color(0xFF002B74),
        primaryContainer: Color(0xFF003FA3),
        onPrimaryContainer: Color(0xFFD8E4FF),
        secondary: Color(0xFFCDBDFF),
        onSecondary: Color(0xFF30009C),
        secondaryContainer: Color(0xFF4900D8),
        onSecondaryContainer: Color(0xFFE5DEFF),
        tertiary: Color(0xFF72DB9F),
        onTertiary: Color(0xFF003821),
        tertiaryContainer: Color(0xFF005232),
        onTertiaryContainer: Color(0xFFB8F5D4),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFF111318),
        onSurface: Color(0xFFE2E2E8),
        surfaceContainerHighest: Color(0xFF44474F),
        onSurfaceVariant: Color(0xFFC4C6D0),
        outline: Color(0xFF8E9099),
        outlineVariant: Color(0xFF44474F),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFFE2E2E8),
        onInverseSurface: Color(0xFF2F3033),
        inversePrimary: primary,
      );
}
