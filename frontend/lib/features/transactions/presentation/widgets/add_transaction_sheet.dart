import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/category_selector.dart';
import '../../../../shared/widgets/selection_chip.dart';
import '../../../../shared/widgets/transaction_list.dart' show TransactionItem;
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../providers/transaction_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key, this.initialItem});

  final TransactionItem? initialItem;

  static Future<bool?> show(BuildContext context, {TransactionItem? initialItem}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTransactionSheet(initialItem: initialItem),
    );
  }

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late bool _isExpense;
  late int _amount;
  CategoryItem? _category;
  late DateTime _date;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _memoCtrl;
  late final TextEditingController _amountCtrl;
  final _amountFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _memoFocus = FocusNode();
  bool _loading = false;

  bool get _isEditMode => widget.initialItem != null;

  void _closePickers() {
    if (_showCategoryPicker || _showDatePicker) {
      setState(() {
        _showCategoryPicker = false;
        _showDatePicker = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _isExpense = item != null ? !item.isIncome : true;
    _amount = item != null ? item.amount.abs() : 0;
    _date = item?.date ?? DateTime.now();
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _memoCtrl = TextEditingController(text: item?.memo ?? '');
    _amountCtrl = TextEditingController(
      text: _amount > 0
          ? _amount.toString().replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')
          : '',
    );
    for (final fn in [_amountFocus, _nameFocus, _memoFocus]) {
      fn.addListener(() { if (fn.hasFocus) _closePickers(); });
    }
  }
  bool _showDatePicker = false;
  bool _showCategoryPicker = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _memoCtrl.dispose();
    _amountCtrl.dispose();
    _amountFocus.dispose();
    _nameFocus.dispose();
    _memoFocus.dispose();
    super.dispose();
  }

  void _openCategory() {
    _amountFocus.unfocus();
    setState(() {
      _showCategoryPicker = !_showCategoryPicker;
      if (_showCategoryPicker) _showDatePicker = false;
    });
  }

  void _openDate() {
    _amountFocus.unfocus();
    setState(() {
      _showDatePicker = !_showDatePicker;
      if (_showDatePicker) _showCategoryPicker = false;
    });
  }

  static const _incomeNames = {'급여', '부업', '투자', '기타수입'};

  List<CategoryItem> _filterCategories(List<CategoryItem> all) => all
      .where((c) => _isExpense
          ? !_incomeNames.contains(c.label)
          : _incomeNames.contains(c.label))
      .toList();

  Color get _accentColor => _isExpense ? AppColors.expense : AppColors.income;

  Future<void> _submit() async {
    if (_amount <= 0) {
      _showErrorDialog('금액을 입력해 주세요.');
      return;
    }
    final effectiveCategory = _category ?? widget.initialItem?.category;
    if (effectiveCategory == null) {
      _showErrorDialog('카테고리를 선택해 주세요.');
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      final finalAmount = _isExpense ? -_amount : _amount;
      final name = _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim();
      final memo = _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim();

      if (_isEditMode) {
        await repo.update(
          widget.initialItem!.id,
          amount: finalAmount,
          categoryId: effectiveCategory.id,
          transactionDate: _date,
          name: name,
          memo: memo,
        );
      } else {
        await repo.create(
          amount: finalAmount,
          categoryId: effectiveCategory.id,
          paymentMethod: 'cash',
          transactionDate: _date,
          name: name,
          memo: memo,
        );
      }
      ref.invalidate(currentCycleTransactionsProvider);
      ref.invalidate(availableBudgetProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint('거래 저장 실패: $e\n$st');
      if (mounted) _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorDialog(String msg) {
    AppConfirmDialog.show(
      context,
      title: '오류',
      message: msg,
      confirmLabel: '확인',
      cancelLabel: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final accent = _accentColor;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // 키보드 + 버튼이 항상 보이도록 최대 높이 제한 후 스크롤
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 핸들
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(_isEditMode ? '거래 수정' : '거래 추가', style: tt.headlineSmall),
            const SizedBox(height: AppSpacing.lg),

            TransactionTypeToggle(
              isExpense: _isExpense,
              onChanged: (v) => setState(() {
                _isExpense = v;
                if (!_isEditMode) _category = null;
              }),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppTextField(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              label: '거래명 (선택)',
              hint: '예: 스타벅스',
            ),
            const SizedBox(height: AppSpacing.lg),

            AmountTextField(
              label: '금액',
              controller: _amountCtrl,
              focusNode: _amountFocus,
              onChanged: (v) => _amount = v,
            ),
            const SizedBox(height: AppSpacing.lg),

            _CategoryField(
              expanded: _showCategoryPicker,
              selected: _category ?? widget.initialItem?.category,
              isExpense: _isExpense,
              accentColor: accent,
              onToggle: _openCategory,
              onSelected: (c) => setState(() {
                _category = c;
                _showCategoryPicker = false;
              }),
              categoryItems: ref.watch(categoryItemsProvider),
              filterCategories: _filterCategories,
            ),
            const SizedBox(height: AppSpacing.md),

            _DateField(
              date: _date,
              expanded: _showDatePicker,
              accentColor: accent,
              onToggle: _openDate,
              onDateChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              controller: _memoCtrl,
              focusNode: _memoFocus,
              label: '메모 (선택)',
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xl),

            _AccentButton(
              label: _isEditMode ? '수정 완료' : '저장',
              loading: _loading,
              color: accent,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 인라인 날짜 선택기 ──────────────────────────────────────────

class _DateField extends StatefulWidget {
  const _DateField({
    required this.date,
    required this.expanded,
    required this.accentColor,
    required this.onToggle,
    required this.onDateChanged,
  });

  final DateTime date;
  final bool expanded;
  final Color accentColor;
  final VoidCallback onToggle;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();
    _year = widget.date.year;
    _month = widget.date.month;
    _day = widget.date.day;
  }

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  void _clampAndNotify() {
    final clamped = _day.clamp(1, _daysInMonth);
    if (clamped != _day) _day = clamped;
    widget.onDateChanged(DateTime(_year, _month, _day));
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final dateStr = DateFormat('yyyy. MM. dd.').format(widget.date);
    final accent = widget.accentColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: AppRadius.buttonBorderRadius,
        border: Border.all(
          color: widget.expanded ? accent : AppColors.divider,
          width: widget.expanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 탭
          GestureDetector(
            onTap: widget.onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 18,
                      color:
                          widget.expanded ? accent : AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(dateStr,
                      style: tt.bodyLarge?.copyWith(
                        color: widget.expanded ? accent : null,
                        fontWeight: widget.expanded ? FontWeight.w600 : null,
                      )),
                  const Spacer(),
                  AnimatedRotation(
                    turns: widget.expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.expand_more_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // 확장 피커
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: widget.expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
              ),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      // 연도
                      Expanded(
                        child: _SpinnerColumn(
                          label: '연',
                          value: _year,
                          min: 2020,
                          max: 2030,
                          accentColor: accent,
                          onChanged: (v) {
                            setState(() => _year = v);
                            _clampAndNotify();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // 월
                      Expanded(
                        child: _SpinnerColumn(
                          label: '월',
                          value: _month,
                          min: 1,
                          max: 12,
                          accentColor: accent,
                          onChanged: (v) {
                            setState(() => _month = v);
                            _clampAndNotify();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // 일
                      Expanded(
                        child: _SpinnerColumn(
                          label: '일',
                          value: _day,
                          min: 1,
                          max: _daysInMonth,
                          accentColor: accent,
                          onChanged: (v) {
                            setState(() => _day = v);
                            _clampAndNotify();
                          },
                        ),
                      ),
                    ],
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

class _SpinnerColumn extends StatefulWidget {
  const _SpinnerColumn({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.accentColor,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  @override
  State<_SpinnerColumn> createState() => _SpinnerColumnState();
}

class _SpinnerColumnState extends State<_SpinnerColumn> {
  late final FixedExtentScrollController _ctrl;
  static const _itemH = 40.0;

  @override
  void initState() {
    super.initState();
    _ctrl = FixedExtentScrollController(
        initialItem: widget.value - widget.min);
  }

  @override
  void didUpdateWidget(_SpinnerColumn old) {
    super.didUpdateWidget(old);
    final idx = widget.value - widget.min;
    if (_ctrl.hasClients && _ctrl.selectedItem != idx) {
      _ctrl.jumpToItem(idx);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final count = widget.max - widget.min + 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label,
            style: tt.labelSmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: _itemH * 3,
          child: Stack(
            children: [
              // 선택 하이라이트
              Positioned(
                top: _itemH,
                left: 0,
                right: 0,
                height: _itemH,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: widget.accentColor.withValues(alpha: 0.3)),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: _ctrl,
                itemExtent: _itemH,
                physics: const FixedExtentScrollPhysics(),
                perspective: 0.003,
                diameterRatio: 3,
                onSelectedItemChanged: (i) =>
                    widget.onChanged(widget.min + i),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: count,
                  builder: (_, i) {
                    final val = widget.min + i;
                    final selected = val == widget.value;
                    return Center(
                      child: Text(
                        val.toString().padLeft(2, '0'),
                        style: tt.bodyLarge?.copyWith(
                          color: selected
                              ? widget.accentColor
                              : AppColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 저장 버튼 ──────────────────────────────────────────────────

class _AccentButton extends StatelessWidget {
  const _AccentButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.buttonBorderRadius,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: AppRadius.buttonBorderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      label,
                      style: tt.labelLarge?.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}


// ── 접이식 카테고리 선택기 ──────────────────────────────────────────

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.expanded,
    required this.selected,
    required this.isExpense,
    required this.accentColor,
    required this.onToggle,
    required this.onSelected,
    required this.categoryItems,
    required this.filterCategories,
  });

  final bool expanded;
  final CategoryItem? selected;
  final bool isExpense;
  final Color accentColor;
  final VoidCallback onToggle;
  final ValueChanged<CategoryItem> onSelected;
  final AsyncValue<List<CategoryItem>> categoryItems;
  final List<CategoryItem> Function(List<CategoryItem>) filterCategories;

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
                  Icon(Icons.category_rounded,
                      size: 18,
                      color: expanded ? accentColor : AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(label,
                      style: tt.bodyLarge?.copyWith(
                        color: selected != null
                            ? (expanded ? accentColor : null)
                            : AppColors.textSecondary,
                        fontWeight:
                            expanded ? FontWeight.w600 : FontWeight.normal,
                      )),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.expand_more_rounded,
                        size: 20, color: AppColors.textSecondary),
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
                AppSpacing.md, 0, AppSpacing.md, 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),
                  categoryItems.when(
                    data: (all) {
                      final items = filterCategories(all);
                      if (items.isEmpty) {
                        return Text('카테고리를 불러오는 중...',
                            style: tt.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary));
                      }
                      return CategoryGrid(
                        items: items,
                        selectedId: selected?.id,
                        onSelected: onSelected,
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, e) => CategoryGrid(
                      items: isExpense
                          ? defaultExpenseCategories
                          : defaultIncomeCategories,
                      selectedId: selected?.id,
                      onSelected: onSelected,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
