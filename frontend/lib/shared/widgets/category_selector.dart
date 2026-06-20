import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'app_bottom_sheet.dart';

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.label,
    required this.icon,
    this.color = AppColors.primary,
  });

  final int id;
  final String label;
  final IconData icon;
  final Color color;
}

// 기본 카테고리 세트
const defaultExpenseCategories = [
  CategoryItem(id: 1, label: '식비', icon: Icons.restaurant_rounded, color: Color(0xFF5B8DEF)),
  CategoryItem(id: 2, label: '교통', icon: Icons.directions_subway_rounded, color: Color(0xFF7C6FF0)),
  CategoryItem(id: 3, label: '쇼핑', icon: Icons.shopping_bag_rounded, color: Color(0xFFFF6B6B)),
  CategoryItem(id: 4, label: '문화', icon: Icons.movie_rounded, color: Color(0xFF34C77B)),
  CategoryItem(id: 5, label: '의료', icon: Icons.local_hospital_rounded, color: Color(0xFFFF9F43)),
  CategoryItem(id: 6, label: '통신', icon: Icons.smartphone_rounded, color: Color(0xFF54A0FF)),
  CategoryItem(id: 7, label: '카페', icon: Icons.local_cafe_rounded, color: Color(0xFF8D6E63)),
  CategoryItem(id: 8, label: '여행', icon: Icons.flight_rounded, color: Color(0xFFB39DFF)),
  CategoryItem(id: 9, label: '구독', icon: Icons.subscriptions_rounded, color: Color(0xFFFF6B6B)),
  CategoryItem(id: 10, label: '기타', icon: Icons.more_horiz_rounded, color: AppColors.textSecondary),
];

const defaultIncomeCategories = [
  CategoryItem(id: 101, label: '급여', icon: Icons.account_balance_rounded, color: Color(0xFF34C77B)),
  CategoryItem(id: 102, label: '부업', icon: Icons.work_rounded, color: Color(0xFF5B8DEF)),
  CategoryItem(id: 103, label: '투자', icon: Icons.trending_up_rounded, color: Color(0xFFB39DFF)),
  CategoryItem(id: 104, label: '기타', icon: Icons.more_horiz_rounded, color: AppColors.textSecondary),
];

// 인라인 그리드 선택기 (폼 안에 바로 삽입하는 용도)
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CategoryItem> items;
  final int? selectedId;
  final ValueChanged<CategoryItem> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final isSelected = item.id == selectedId;
        return GestureDetector(
          onTap: () => onSelected(item),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? item.color.withValues(alpha: 0.15)
                      : const Color(0x0A000000),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? item.color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  item.icon,
                  size: 22,
                  color: isSelected ? item.color : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected ? item.color : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

// 바텀시트 카테고리 선택기
class CategorySelectorSheet extends StatefulWidget {
  const CategorySelectorSheet({
    super.key,
    required this.items,
    this.initialId,
    this.title = '카테고리',
  });

  final List<CategoryItem> items;
  final int? initialId;
  final String title;

  static Future<CategoryItem?> show(
    BuildContext context, {
    List<CategoryItem> items = defaultExpenseCategories,
    int? initialId,
    String title = '카테고리 선택',
  }) {
    return AppBottomSheet.show<CategoryItem>(
      context,
      title: title,
      child: CategorySelectorSheet(
        items: items,
        initialId: initialId,
        title: title,
      ),
    );
  }

  @override
  State<CategorySelectorSheet> createState() => _CategorySelectorSheetState();
}

class _CategorySelectorSheetState extends State<CategorySelectorSheet> {
  late int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialId;
  }

  @override
  Widget build(BuildContext context) {
    return CategoryGrid(
      items: widget.items,
      selectedId: _selected,
      onSelected: (item) {
        setState(() => _selected = item.id);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (context.mounted) Navigator.pop(context, item);
        });
      },
    );
  }
}

// 폼에서 카테고리 선택 필드로 쓰는 탭 가능한 버튼
class CategoryPickerField extends StatelessWidget {
  const CategoryPickerField({
    super.key,
    this.selected,
    required this.onSelected,
    this.items = defaultExpenseCategories,
    this.label = '카테고리',
  });

  final CategoryItem? selected;
  final ValueChanged<CategoryItem> onSelected;
  final List<CategoryItem> items;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () async {
        final result = await CategorySelectorSheet.show(
          context,
          items: items,
          initialId: selected?.id,
        );
        if (result != null) onSelected(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceGlass,
          borderRadius: AppRadius.buttonBorderRadius,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            if (selected != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected!.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(selected!.icon, size: 16, color: selected!.color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(selected!.label, style: tt.bodyLarge),
            ] else ...[
              Icon(Icons.grid_view_rounded, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: tt.bodyLarge?.copyWith(color: AppColors.textSecondary)),
            ],
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
