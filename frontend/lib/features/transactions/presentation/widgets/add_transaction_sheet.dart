import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/category_selector.dart';
import '../../../../shared/widgets/selection_chip.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../providers/transaction_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddTransactionSheet(),
    );
  }

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  bool _isExpense = true;
  int _amount = 0;
  CategoryItem? _category;
  DateTime _date = DateTime.now();
  final _nameCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  bool _loading = false;
  bool _showDatePicker = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
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
    if (_category == null) {
      _showErrorDialog('카테고리를 선택해 주세요.');
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.create(
        amount: _isExpense ? -_amount : _amount,
        categoryId: _category!.id,
        paymentMethod: 'cash',
        transactionDate: _date,
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      );
      ref.invalidate(currentCycleTransactionsProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint('거래 저장 실패: $e\n$st');
      if (mounted) _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorDialog(String msg) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('오류'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final accent = _accentColor;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                color: Color.alphaBlend(
                  accent.withValues(alpha: 0.07),
                  AppColors.surfaceGlass,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color.alphaBlend(
                      accent.withValues(alpha: 0.2),
                      AppColors.surfaceGlassBorder,
                    ),
                    width: 1,
                  ),
                  left: const BorderSide(color: AppColors.surfaceGlassBorder, width: 1),
                  right: const BorderSide(color: AppColors.surfaceGlassBorder, width: 1),
                ),
              ),
              // 키보드 + 버튼이 항상 보이도록 최대 높이 제한 후 스크롤
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.92,
              ),
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl,
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
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    Text('거래 추가', style: tt.headlineSmall),
                    const SizedBox(height: AppSpacing.lg),

                    // 수입 / 지출 탭
                    TransactionTypeToggle(
                      isExpense: _isExpense,
                      onChanged: (v) => setState(() {
                        _isExpense = v;
                        _category = null;
                      }),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 금액
                    AmountTextField(
                      label: '금액',
                      onChanged: (v) => _amount = v,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 카테고리 인라인 그리드
                    Text(
                      '카테고리',
                      style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ref.watch(categoryItemsProvider).when(
                      data: (all) {
                        final items = _filterCategories(all);
                        if (items.isEmpty) {
                          return Text(
                            '카테고리를 불러오는 중...',
                            style: tt.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          );
                        }
                        return CategoryGrid(
                          items: items,
                          selectedId: _category?.id,
                          onSelected: (c) => setState(() => _category = c),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => CategoryGrid(
                        items: _isExpense
                            ? defaultExpenseCategories
                            : defaultIncomeCategories,
                        selectedId: _category?.id,
                        onSelected: (c) => setState(() => _category = c),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 거래명 (선택)
                    AppTextField(
                      controller: _nameCtrl,
                      label: '거래명 (선택)',
                      hint: '예: 스타벅스',
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // 날짜 선택
                    _DateField(
                      date: _date,
                      expanded: _showDatePicker,
                      accentColor: accent,
                      onToggle: () =>
                          setState(() => _showDatePicker = !_showDatePicker),
                      onDateChanged: (d) => setState(() => _date = d),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // 메모 (선택)
                    AppTextField(
                      controller: _memoCtrl,
                      label: '메모 (선택)',
                      maxLines: 2,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // 저장 버튼
                    _AccentButton(
                      label: '저장',
                      loading: _loading,
                      color: accent,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
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
