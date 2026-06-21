import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../features/budget/presentation/providers/budget_provider.dart';
import '../providers/settings_provider.dart';

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
              onSave: (name, amount, scheduledDay) async {
                await ref.read(settingsRepositoryProvider).updateIncome(
                  e.id, name: name, amount: amount, scheduledDay: scheduledDay,
                  effectiveFrom: effectiveFrom,
                );
                ref.invalidate(fixedIncomesProvider);
                ref.invalidate(availableBudgetProvider);
              },
            ),
          );
        },
        onDelete: () async {
          final ok = await AppConfirmDialog.show(
            context,
            title: '삭제',
            message: '${e.name}을(를) 삭제할까요?',
            confirmLabel: '삭제',
            isDestructive: true,
          );
          if (ok && context.mounted) {
            await ref.read(settingsRepositoryProvider).deleteIncome(e.id);
            ref.invalidate(fixedIncomesProvider);
            ref.invalidate(availableBudgetProvider);
          }
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
                                onSave: (name, amount, scheduledDay) async {
                                  await ref
                                      .read(settingsRepositoryProvider)
                                      .createIncome(
                                        name: name,
                                        amount: amount,
                                        scheduledDay: scheduledDay,
                                      );
                                  ref.invalidate(fixedIncomesProvider);
                                  ref.invalidate(availableBudgetProvider);
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

  final dynamic item;
  final NumberFormat fmt;
  final VoidCallback onTap;

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
                  Text(item.name,
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                  if (item.scheduledDay != null)
                    Text(
                      '매월 ${item.scheduledDay}일',
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

class _AddIncomeForm extends StatefulWidget {
  const _AddIncomeForm({required this.onSave, this.initial});
  final Future<void> Function(String name, double amount, int scheduledDay) onSave;
  final dynamic initial;

  @override
  State<_AddIncomeForm> createState() => _AddIncomeFormState();
}

class _AddIncomeFormState extends State<_AddIncomeForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late int _amount;
  late int? _scheduledDay;
  bool _saving = false;

  bool get _canSave =>
      !_saving &&
      _nameCtrl.text.trim().isNotEmpty &&
      _amount > 0 &&
      _scheduledDay != null;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _amount = init != null ? (init.expectedAmount as num).round() : 0;
    _scheduledDay = init?.scheduledDay as int?;
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
        _InlineDayPicker(
          label: '받는 날',
          value: _scheduledDay,
          onChanged: (v) => setState(() => _scheduledDay = v),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: _canSave
              ? () async {
                  setState(() => _saving = true);
                  await widget.onSave(
                      _nameCtrl.text.trim(), _amount.toDouble(), _scheduledDay!);
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

class _InlineDayPicker extends StatefulWidget {
  const _InlineDayPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  State<_InlineDayPicker> createState() => _InlineDayPickerState();
}

class _InlineDayPickerState extends State<_InlineDayPicker> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hasValue = widget.value != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0x0A000000),
        borderRadius: AppRadius.buttonBorderRadius,
        border: Border.all(
            color: _open
                ? AppColors.income
                : hasValue
                    ? AppColors.income.withValues(alpha: 0.5)
                    : AppColors.divider,
            width: _open ? 1.5 : 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    widget.label,
                    style: tt.bodyLarge?.copyWith(
                      color: hasValue
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (hasValue)
                    Text(
                      '매월 ${widget.value}일',
                      style: tt.bodyMedium?.copyWith(
                        color: AppColors.income,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
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
                _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
                itemCount: 28,
                itemBuilder: (_, i) {
                  final day = i + 1;
                  final isSel = day == widget.value;
                  return GestureDetector(
                    onTap: () {
                      widget.onChanged(day);
                      setState(() => _open = false);
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
                        '$day',
                        style: tt.labelSmall?.copyWith(
                          color:
                              isSel ? Colors.white : AppColors.textPrimary,
                          fontWeight:
                              isSel ? FontWeight.w700 : FontWeight.w400,
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
