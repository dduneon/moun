import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class NavBarItem {
  const NavBarItem({
    required this.icon,
    required this.label,
    this.isCenter = false,
  });

  final IconData icon;
  final String label;
  final bool isCenter;
}

const _defaultItems = [
  NavBarItem(icon: Icons.home_rounded, label: '홈'),
  NavBarItem(icon: Icons.receipt_long_rounded, label: '거래'),
  NavBarItem(icon: Icons.add_rounded, label: '추가', isCenter: true),
  NavBarItem(icon: Icons.bar_chart_rounded, label: '통계'),
  NavBarItem(icon: Icons.settings_rounded, label: '설정'),
];

class GlassFloatingNavbar extends StatelessWidget {
  const GlassFloatingNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = _defaultItems,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.navbarBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceGlass,
              borderRadius: AppRadius.navbarBorderRadius,
              border: Border.all(
                color: AppColors.surfaceGlassBorder,
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 32,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                return _NavBarTab(
                  item: items[i],
                  isSelected: currentIndex == i,
                  onTap: () => onTap(i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarTab extends StatelessWidget {
  const _NavBarTab({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final NavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (item.isCenter) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryGradientEnd],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 22,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.label,
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ).animate(target: isSelected ? 1 : 0).scaleXY(
              begin: 1,
              end: 1.05,
              duration: 150.ms,
              curve: Curves.easeOut,
            ),
      ),
    );
  }
}
