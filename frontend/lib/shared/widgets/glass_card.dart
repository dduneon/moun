import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.sigmaBlur = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double sigmaBlur;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.cardBorderRadius;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaBlur, sigmaY: sigmaBlur),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceGlass,
            borderRadius: radius,
            border: Border.all(
              color: AppColors.surfaceGlassBorder,
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000), // black 8%
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
