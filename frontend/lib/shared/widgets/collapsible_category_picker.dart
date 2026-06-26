import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'category_selector.dart';

class CollapsibleCategoryPicker extends StatelessWidget {
  const CollapsibleCategoryPicker({
    super.key,
    required this.items,
    required this.selected,
    required this.expanded,
    required this.accentColor,
    required this.onToggle,
    required this.onSelected,
  });

  final List<CategoryItem> items;
  final CategoryItem? selected;
  final bool expanded;
  final Color accentColor;
  final VoidCallback onToggle;
  final ValueChanged<CategoryItem> onSelected;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final label = selected?.label ?? '카테고리 선택';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: AppRadius.buttonBorderRadius,
        border: Border.all(
          color: expanded ? accentColor : AppColors.divider,
          width: expanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.category_rounded,
                    size: 18,
                    color: expanded ? accentColor : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: tt.bodyLarge?.copyWith(
                      color: selected != null
                          ? (expanded ? accentColor : null)
                          : AppColors.textSecondary,
                      fontWeight:
                          expanded ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),
                  CategoryGrid(
                    items: items,
                    selectedId: selected?.id,
                    onSelected: onSelected,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
