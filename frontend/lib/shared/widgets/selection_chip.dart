import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/transactions/domain/transaction_models.dart' show TransactionType;

// 단일/다중 선택 칩 그룹
class SelectionChipGroup<T> extends StatelessWidget {
  const SelectionChipGroup({
    super.key,
    required this.items,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
    this.multiSelect = false,
  });

  final List<T> items;
  final String Function(T) labelOf;
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelected;
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((item) {
        final isSelected = selected.contains(item);
        return _SelectionChip(
          label: labelOf(item),
          isSelected: isSelected,
          onTap: () {
            if (multiSelect) {
              final next = Set<T>.from(selected);
              isSelected ? next.remove(item) : next.add(item);
              onSelected(next);
            } else {
              onSelected({item});
            }
          },
        );
      }).toList(),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceGlass,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: tt.labelMedium?.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// 수입/지출 타입 토글 — 슬라이딩 인디케이터
class TransactionTypeToggle extends StatelessWidget {
  const TransactionTypeToggle({
    super.key,
    required this.isExpense,
    required this.onChanged,
  });

  final bool isExpense;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    const pad = 3.0;
    const h = 44.0;
    final activeColor = isExpense ? AppColors.expense : AppColors.income;

    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        final thumbW = w / 2 - pad;

        return Container(
          height: h,
          decoration: BoxDecoration(
            color: const Color(0x0A000000),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Stack(
            children: [
              // 슬라이딩 흰 thumb
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                left: isExpense ? pad : w / 2,
                top: pad,
                width: thumbW,
                height: h - pad * 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.button - 2),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // 탭 레이블
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(true),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        height: h,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: tt.labelLarge!.copyWith(
                              color: isExpense ? AppColors.expense : AppColors.textSecondary,
                              fontWeight: isExpense ? FontWeight.w600 : FontWeight.w400,
                            ),
                            child: const Text('지출'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(false),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        height: h,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: tt.labelLarge!.copyWith(
                              color: !isExpense ? AppColors.income : AppColors.textSecondary,
                              fontWeight: !isExpense ? FontWeight.w600 : FontWeight.w400,
                            ),
                            child: const Text('수입'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// 수입/지출/저축 3분할 타입 선택기 — 슬라이딩 인디케이터
class TransactionTypeSelector extends StatelessWidget {
  const TransactionTypeSelector({
    super.key,
    required this.type,
    required this.onChanged,
    this.allowSaving = true,
  });

  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;
  final bool allowSaving;

  static const _allOptions = [
    (TransactionType.expense, '지출', AppColors.expense),
    (TransactionType.income, '수입', AppColors.income),
    (TransactionType.saving, '저축', AppColors.saving),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    const pad = 3.0;
    const h = 44.0;
    final options = allowSaving
        ? _allOptions
        : _allOptions.where((o) => o.$1 != TransactionType.saving).toList();
    final selectedIndex = options.indexWhere((o) => o.$1 == type);
    final activeColor = options[selectedIndex].$3;

    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        final segW = w / options.length;
        final thumbW = segW - pad * 2;

        return Container(
          height: h,
          decoration: BoxDecoration(
            color: const Color(0x0A000000),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                left: segW * selectedIndex + pad,
                top: pad,
                width: thumbW,
                height: h - pad * 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.button - 2),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (value, label, color) in options)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onChanged(value),
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          height: h,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: tt.labelLarge!.copyWith(
                                color: type == value ? color : AppColors.textSecondary,
                                fontWeight: type == value ? FontWeight.w600 : FontWeight.w400,
                              ),
                              child: Text(label),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
