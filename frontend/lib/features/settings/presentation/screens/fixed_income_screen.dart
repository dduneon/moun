import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/constants/category_type_names.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/category_selector.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../features/budget/presentation/providers/budget_provider.dart';
import '../../../../features/categories/presentation/providers/category_provider.dart';
import '../../../../shared/widgets/collapsible_category_picker.dart';
import '../providers/settings_provider.dart';
import '../../data/settings_repository.dart';
import '../../../../features/transactions/presentation/providers/transaction_provider.dart';

class FixedIncomeScreen extends ConsumerWidget {
  const FixedIncomeScreen({super.key});

  Future<DateTime?> _showEffectiveFromDialog(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => _EffectiveFromDialog(
        thisMonth: thisMonth,
        nextMonth: nextMonth,
        itemLabel: '고정 수입',
      ),
    );
  }

  Future<String?> _showDeleteDialog(BuildContext context, String name) {
    final now = DateTime.now();
    return showDialog<String>(
      context: context,
      builder: (ctx) => _DeleteDialog(thisMonth: DateTime(now.year, now.month)),
    );
  }

  Future<void> _showIncomeActions(BuildContext context, WidgetRef ref, dynamic e) async {
    await AppBottomSheet.show<void>(
      context,
      child: _ActionSheet(
        title: e.name,
        onEdit: () async {
          final effectiveFrom = await _showEffectiveFromDialog(context);
          if (effectiveFrom == null || !context.mounted) return;
          await AppBottomSheet.show(
            context,
            title: '고정 수입 수정',
            child: _AddIncomeForm(
              initial: e,
              onSave: (name, amount, frequency, scheduledDay, dayOfWeek, categoryId, _) async {
                await ref.read(settingsRepositoryProvider).updateIncome(
                  e.id, name: name, amount: amount,
                  frequency: frequency, scheduledDay: scheduledDay, dayOfWeek: dayOfWeek,
                  effectiveFrom: effectiveFrom,
                );
                ref.invalidate(fixedIncomesProvider);
                ref.invalidate(availableBudgetProvider);
                ref.invalidate(currentCycleTransactionsProvider);
              },
            ),
          );
        },
        onDelete: () async {
          final option = await _showDeleteDialog(context, e.name as String);
          if (option == null || !context.mounted) return;
          final now = DateTime.now();
          final endFrom = option == 'soft' ? DateTime(now.year, now.month) : null;
          await ref.read(settingsRepositoryProvider).deleteIncome(e.id, endFrom: endFrom);
          ref.invalidate(fixedIncomesProvider);
          ref.invalidate(availableBudgetProvider);
          ref.invalidate(currentCycleTransactionsProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final fmt = NumberFormat('#,###');
    final async = ref.watch(fixedIncomesProvider(null));

    return GradientBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              size: 18, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text('고정 수입', style: tt.headlineMedium),
                  ],
                ).animate().fadeIn(),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: async.when(
                  data: (items) => GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xxl),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary),
                                const SizedBox(height: AppSpacing.md),
                                Text('등록된 고정 수입이 없어요',
                                    textAlign: TextAlign.center,
                                    style: tt.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        else
                          ...items.map((e) => Column(
                                children: [
                                  _IncomeRow(
                                    item: e,
                                    fmt: fmt,
                                    onTap: () => _showIncomeActions(context, ref, e),
                                  ),
                                  if (e != items.last)
                                    const Divider(height: 1, indent: 52),
                                ],
                              )),
                        const Divider(height: 1),
                        _AddRow(
                          label: '고정 수입 추가',
                          color: AppColors.income,
                          onTap: () async {
                            await AppBottomSheet.show(
                              context,
                              title: '고정 수입 추가',
                              child: _AddIncomeForm(
                                onSave: (name, amount, frequency, scheduledDay, dayOfWeek, categoryId, includeCurrentCycle) async {
                                  await ref
                                      .read(settingsRepositoryProvider)
                                      .createIncome(
                                        name: name,
                                        amount: amount,
                                        frequency: frequency,
                                        scheduledDay: scheduledDay,
                                        dayOfWeek: dayOfWeek,
                                        categoryId: categoryId,
                                        includeCurrentCycle: includeCurrentCycle,
                                      );
                                  ref.invalidate(fixedIncomesProvider);
                                  ref.invalidate(availableBudgetProvider);
                                  ref.invalidate(currentCycleTransactionsProvider);
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  loading: () => const Center(
                      child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: CircularProgressIndicator(),
                  )),
                  error: (e, _) => Center(child: Text('오류: $e')),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    ));
  }
}

// ── 수입 항목 행 ───────────────────────────────────────────────

class _IncomeRow extends StatelessWidget {
  const _IncomeRow({
    required this.item,
    required this.fmt,
    required this.onTap,
  });

  final FixedIncomeItem item;
  final NumberFormat fmt;
  final VoidCallback onTap;

  static const _dowLabels = ['월', '화', '수', '목', '금', '토', '일'];

  String _scheduleLabel() {
    final freq = item.frequency;
    final dow = item.dayOfWeek;
    final day = item.scheduledDay;
    return switch (freq) {
      'weekly'   => '매주 ${dow != null ? _dowLabels[dow] : '?'}요일',
      'biweekly' => '격주 ${dow != null ? _dowLabels[dow] : '?'}요일',
      'daily'    => '매일',
      _          => day != null ? (day == 31 ? '매월 말일' : '매월 ${day}일') : '매월',
    };
  }

  bool get _startsNextCycle {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return item.effectiveFrom.isAfter(todayDate);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.income.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                size: 18,
                color: AppColors.income,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(item.name,
                          style: tt.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500)),
                      if (_startsNextCycle) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.effectiveFrom.month}/${item.effectiveFrom.day}부터',
                            style: tt.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    _scheduleLabel(),
                    style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              '+${fmt.format(item.expectedAmount.round())}원',
              style: tt.bodyMedium?.copyWith(
                  color: AppColors.income, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── 추가 행 ───────────────────────────────────────────────────

class _AddRow extends StatelessWidget {
  const _AddRow(
      {required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardBorderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add_rounded, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── 고정 수입 추가 폼 ─────────────────────────────────────────

class _AddIncomeForm extends ConsumerStatefulWidget {
  const _AddIncomeForm({required this.onSave, this.initial});
  final Future<void> Function(
    String name,
    double amount,
    String frequency,
    int? scheduledDay,
    int? dayOfWeek,
    int? categoryId,
    bool includeCurrentCycle,
  ) onSave;
  final dynamic initial;

  @override
  ConsumerState<_AddIncomeForm> createState() => _AddIncomeFormState();
}

class _AddIncomeFormState extends ConsumerState<_AddIncomeForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late int _amount;
  late String _frequency;
  late int? _scheduledDay;
  late int? _dayOfWeek;
  int? _categoryId;
  bool _showCategoryPicker = false;
  bool _showDayPicker = false;
  bool _saving = false;

  static const _frequencies = [
    ('monthly',  '매월'),
    ('weekly',   '매주'),
    ('biweekly', '격주'),
    ('daily',    '매일'),
  ];

  bool get _canSave {
    if (_saving || _nameCtrl.text.trim().isEmpty || _amount <= 0) return false;
    if (_frequency == 'monthly' && _scheduledDay == null) return false;
    if ((_frequency == 'weekly' || _frequency == 'biweekly') && _dayOfWeek == null) return false;
    return true;
  }

  bool _hasPastOccurrence() {
    final today = DateTime.now();
    if (_frequency == 'daily') return true;
    if ((_frequency == 'weekly' || _frequency == 'biweekly') && _dayOfWeek != null) {
      return _dayOfWeek! <= today.weekday - 1;
    }
    if (_frequency == 'monthly' && _scheduledDay != null) {
      return _scheduledDay! <= today.day;
    }
    return false;
  }

  String _dialogSubtitle() {
    const dowLabels = ['월', '화', '수', '목', '금', '토', '일'];
    return switch (_frequency) {
      'weekly'   => '이번 주 ${dowLabels[_dayOfWeek!]}요일',
      'biweekly' => '이번 사이클 ${dowLabels[_dayOfWeek!]}요일',
      'daily'    => '오늘부터',
      _          => '이번 달 ${_scheduledDay == 31 ? '말일' : '${_scheduledDay}일'}',
    };
  }

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _amount = init != null ? (init.expectedAmount as num).round() : 0;
    _frequency = init?.frequency ?? 'monthly';
    _scheduledDay = init?.scheduledDay as int?;
    _dayOfWeek = init?.dayOfWeek as int?;
    _categoryId = init?.categoryId as int?;
    _nameCtrl = TextEditingController(text: init?.name ?? '');
    _amountCtrl = TextEditingController(
      text: _amount > 0
          ? _amount.toString().replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')
          : '',
    );
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _nameCtrl,
          label: '이름',
          hint: '월급, 부업, 임대료 등',
          autofocus: true,
        ),
        const SizedBox(height: AppSpacing.md),
        AmountTextField(
          label: '예상 금액',
          controller: _amountCtrl,
          onChanged: (v) => setState(() => _amount = v),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── 반복 유형 선택 ──
        Text('반복', style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: _frequencies.map((opt) {
            final (val, label) = opt;
            final isSel = _frequency == val;
            final isLast = val == 'daily';
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _frequency = val;
                  if (val == 'monthly') _dayOfWeek = null;
                  if (val != 'monthly') _scheduledDay = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: isLast ? 0 : AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.income.withValues(alpha: 0.1) : const Color(0x0A000000),
                    borderRadius: AppRadius.buttonBorderRadius,
                    border: Border.all(color: isSel ? AppColors.income : AppColors.divider),
                  ),
                  child: Center(
                    child: Text(label, style: tt.labelMedium?.copyWith(
                      color: isSel ? AppColors.income : AppColors.textSecondary,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                    )),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── 날짜/요일 피커 ──
        if (_frequency == 'monthly')
          _InlineDayPicker(
            label: '받는 날',
            value: _scheduledDay,
            isOpen: _showDayPicker,
            onToggle: () => setState(() {
              _showDayPicker = !_showDayPicker;
              if (_showDayPicker) _showCategoryPicker = false;
            }),
            onChanged: (v) => setState(() => _scheduledDay = v),
          )
        else if (_frequency == 'weekly' || _frequency == 'biweekly')
          _DowPicker(
            label: '요일',
            value: _dayOfWeek,
            color: AppColors.income,
            onChanged: (v) => setState(() => _dayOfWeek = v),
          ),

        const SizedBox(height: AppSpacing.md),
        ref.watch(categoryItemsProvider).when(
          data: (all) {
            final items = all.where((c) => incomeCategoryNames.contains(c.label)).toList();
            final selected = items.where((c) => c.id == _categoryId).firstOrNull;
            return CollapsibleCategoryPicker(
              items: items,
              selected: selected,
              expanded: _showCategoryPicker,
              accentColor: AppColors.income,
              onToggle: () => setState(() {
                _showCategoryPicker = !_showCategoryPicker;
                if (_showCategoryPicker) _showDayPicker = false;
              }),
              onSelected: (c) => setState(() {
                _categoryId = c.id;
                _showCategoryPicker = false;
              }),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: _canSave
              ? () async {
                  bool includeCurrentCycle = true;
                  if (widget.initial == null && _hasPastOccurrence()) {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => _CurrentCycleDialog(
                        subtitle: _dialogSubtitle(),
                        name: _nameCtrl.text.trim(),
                        color: AppColors.income,
                        label: '수입',
                      ),
                    );
                    if (result == null || !context.mounted) return;
                    includeCurrentCycle = result;
                  }
                  setState(() => _saving = true);
                  await widget.onSave(
                    _nameCtrl.text.trim(),
                    _amount.toDouble(),
                    _frequency,
                    _scheduledDay,
                    _dayOfWeek,
                    _categoryId,
                    includeCurrentCycle,
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.income,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.income.withValues(alpha: 0.35),
            disabledForegroundColor: Colors.white70,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
                borderRadius: AppRadius.buttonBorderRadius),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.initial != null ? '수정 완료' : '추가', style: tt.labelLarge),
        ),
      ],
    );
  }
}

// ── 수정/삭제 액션 시트 ───────────────────────────────────────

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({
    required this.title,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(title,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SheetAction(
          icon: Icons.edit_rounded,
          iconColor: AppColors.primary,
          label: '수정',
          onTap: () {
            Navigator.pop(context);
            onEdit();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _SheetAction(
          icon: Icons.delete_rounded,
          iconColor: AppColors.expense,
          label: '삭제',
          labelColor: AppColors.expense,
          onTap: () {
            Navigator.pop(context);
            onDelete();
          },
        ),
      ],
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.buttonBorderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.06),
          borderRadius: AppRadius.buttonBorderRadius,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: labelColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 삭제 범위 다이얼로그 ──────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.thisMonth});
  final DateTime thisMonth;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 28),
          Text('어떻게 삭제할까요?',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('삭제 범위를 선택해주세요',
              style: tt.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          const Divider(height: 1),
          _DialogOption(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.expense,
            title: '${thisMonth.month}월부터 삭제',
            subtitle: '이전 달 기록은 유지됩니다',
            onTap: () => Navigator.pop(context, 'soft'),
          ),
          const Divider(height: 1, indent: 56),
          _DialogOption(
            icon: Icons.delete_forever_rounded,
            iconColor: const Color(0xFFB00020),
            title: '전체 삭제',
            subtitle: '모든 기록이 삭제됩니다',
            onTap: () => Navigator.pop(context, 'hard'),
          ),
          const Divider(height: 1),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 48),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
            ),
            child: Text('취소', style: tt.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// ── 적용 시점 다이얼로그 ──────────────────────────────────────

class _EffectiveFromDialog extends StatelessWidget {
  const _EffectiveFromDialog({
    required this.thisMonth,
    required this.nextMonth,
    required this.itemLabel,
  });

  final DateTime thisMonth;
  final DateTime nextMonth;
  final String itemLabel;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 28),
          Text(
            '언제부터 적용할까요?',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '변경 사항이 적용되는 시점을 선택해주세요',
            style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          _DialogOption(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.income,
            title: '이번 달 ${thisMonth.month}월부터',
            subtitle: '${thisMonth.year}년 ${thisMonth.month}월 $itemLabel부터 반영',
            onTap: () => Navigator.pop(context, thisMonth),
          ),
          const Divider(height: 1, indent: 56),
          _DialogOption(
            icon: Icons.arrow_forward_rounded,
            iconColor: AppColors.primary,
            title: '다음 달 ${nextMonth.month}월부터',
            subtitle: '${nextMonth.year}년 ${nextMonth.month}월 $itemLabel부터 반영',
            onTap: () => Navigator.pop(context, nextMonth),
          ),
          const Divider(height: 1, indent: 56),
          _DialogOption(
            icon: Icons.history_rounded,
            iconColor: AppColors.textSecondary,
            title: '처음부터 (전체 수정)',
            subtitle: '기존 기록도 모두 변경됩니다',
            onTap: () => Navigator.pop(context, DateTime(2000)),
          ),
          const Divider(height: 1),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 48),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
            ),
            child: Text('취소', style: tt.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// ── 이번 달 포함 여부 다이얼로그 ─────────────────────────────

// ── 요일 피커 ──────────────────────────────────────────────────

class _DowPicker extends StatelessWidget {
  const _DowPicker({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final Color color;
  final ValueChanged<int?> onChanged;

  static const _labels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: List.generate(7, (i) {
            final isSel = value == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: i < 6 ? AppSpacing.xs : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? color.withValues(alpha: 0.12) : const Color(0x0A000000),
                    borderRadius: AppRadius.buttonBorderRadius,
                    border: Border.all(color: isSel ? color : AppColors.divider),
                  ),
                  child: Center(
                    child: Text(_labels[i], style: tt.labelMedium?.copyWith(
                      color: isSel ? color : AppColors.textSecondary,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                    )),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CurrentCycleDialog extends StatelessWidget {
  const _CurrentCycleDialog({
    required this.subtitle,
    required this.name,
    required this.color,
    required this.label,
  });

  final String subtitle;
  final String name;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 28),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_month_rounded, size: 26, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            '이번 사이클에도 발생했나요?',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '$subtitle에 $name $label이\n이미 발생했나요?',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          _DialogOption(
            icon: Icons.check_circle_rounded,
            iconColor: color,
            title: '네, 이번 사이클도 포함해주세요',
            subtitle: '$subtitle 발생분이 자동 기록됩니다',
            onTap: () => Navigator.pop(context, true),
          ),
          const Divider(height: 1, indent: 56),
          _DialogOption(
            icon: Icons.arrow_forward_rounded,
            iconColor: AppColors.primary,
            title: '아니요, 다음 사이클부터 시작할게요',
            subtitle: '이번 사이클은 건너뛰고 다음부터 추적됩니다',
            onTap: () => Navigator.pop(context, false),
          ),
          const Divider(height: 1),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 48),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
            ),
            child: Text('취소', style: tt.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _DialogOption extends StatelessWidget {
  const _DialogOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: tt.bodySmall?.copyWith(
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── 받는 날 피커 ──────────────────────────────────────────────

class _InlineDayPicker extends StatelessWidget {
  const _InlineDayPicker({
    required this.label,
    required this.value,
    required this.isOpen,
    required this.onToggle,
    required this.onChanged,
  });
  final String label;
  final int? value;
  final bool isOpen;
  final VoidCallback onToggle;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hasValue = value != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0x0A000000),
        borderRadius: AppRadius.buttonBorderRadius,
        border: Border.all(
            color: isOpen
                ? AppColors.income
                : hasValue
                    ? AppColors.income.withValues(alpha: 0.5)
                    : AppColors.divider,
            width: isOpen ? 1.5 : 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    label,
                    style: tt.bodyLarge?.copyWith(
                      color: hasValue
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (hasValue)
                    Text(
                      value == 31 ? '매월 말일' : '매월 ${value}일',
                      style: tt.bodyMedium?.copyWith(
                        color: AppColors.income,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: AppSpacing.xs,
                  crossAxisSpacing: AppSpacing.xs,
                  childAspectRatio: 1,
                ),
                itemCount: 31,
                itemBuilder: (_, i) {
                  final day = i + 1;
                  final isSel = day == value;
                  final isLast = day == 31;
                  return GestureDetector(
                    onTap: () {
                      onChanged(day);
                      if (isOpen) onToggle();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.income
                            : AppColors.income.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isLast ? '말일' : '$day',
                        style: tt.labelSmall?.copyWith(
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                          fontSize: isLast ? 8 : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
