import 'package:flutter/material.dart';
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
import '../../domain/space_model.dart';
import '../providers/space_schedule_provider.dart';

/// Space의 고정수입/고정지출을 관리하는 화면.
/// 개인 공간과 달리 매월 반복만 지원하고, 수정 없이 추가/삭제만 가능한 간소화 버전.
class SpaceDetailScreen extends ConsumerWidget {
  const SpaceDetailScreen({super.key, required this.space});
  final SpaceModel space;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final fmt = NumberFormat('#,###');
    final incomesAsync = ref.watch(spaceFixedIncomesProvider(space.id));
    final expensesAsync = ref.watch(spaceFixedExpensesProvider(space.id));

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
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('${space.name} 관리', style: tt.headlineMedium),
                  ],
                ).animate().fadeIn(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('고정 수입', style: tt.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    incomesAsync.when(
                      data: (items) => _ScheduleCard(
                        items: items
                            .map((i) => _ScheduleRowData(
                                  id: i.id,
                                  name: i.name,
                                  amount: i.expectedAmount,
                                  day: i.scheduledDay,
                                  isIncome: true,
                                ))
                            .toList(),
                        fmt: fmt,
                        emptyIcon: Icons.trending_up_rounded,
                        emptyText: '등록된 고정 수입이 없어요',
                        addLabel: '고정 수입 추가',
                        addColor: AppColors.income,
                        onAdd: () => _showAddIncomeSheet(context, ref),
                        onDelete: (id) async {
                          await ref.read(spaceScheduleRepositoryProvider).deleteIncome(space.id, id);
                          ref.invalidate(spaceFixedIncomesProvider(space.id));
                        },
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Text('오류: $e'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('고정 지출', style: tt.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    expensesAsync.when(
                      data: (items) => _ScheduleCard(
                        items: items
                            .map((e) => _ScheduleRowData(
                                  id: e.id,
                                  name: e.name,
                                  amount: e.amount,
                                  day: e.billingDay,
                                  isIncome: false,
                                ))
                            .toList(),
                        fmt: fmt,
                        emptyIcon: Icons.receipt_long_outlined,
                        emptyText: '등록된 고정 지출이 없어요',
                        addLabel: '고정 지출 추가',
                        addColor: AppColors.expense,
                        onAdd: () => _showAddExpenseSheet(context, ref),
                        onDelete: (id) async {
                          await ref.read(spaceScheduleRepositoryProvider).deleteFixedExpense(space.id, id);
                          ref.invalidate(spaceFixedExpensesProvider(space.id));
                        },
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Text('오류: $e'),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    ));
  }

  Future<void> _showAddIncomeSheet(BuildContext context, WidgetRef ref) async {
    final result = await AppBottomSheet.show<_ScheduleFormResult>(
      context,
      title: '고정 수입 추가',
      child: const _ScheduleForm(),
    );
    if (result == null) return;
    await ref.read(spaceScheduleRepositoryProvider).createIncome(
          space.id,
          name: result.name,
          amount: result.amount,
          scheduledDay: result.day,
        );
    ref.invalidate(spaceFixedIncomesProvider(space.id));
  }

  Future<void> _showAddExpenseSheet(BuildContext context, WidgetRef ref) async {
    final result = await AppBottomSheet.show<_ScheduleFormResult>(
      context,
      title: '고정 지출 추가',
      child: const _ScheduleForm(),
    );
    if (result == null) return;
    await ref.read(spaceScheduleRepositoryProvider).createFixedExpense(
          space.id,
          name: result.name,
          amount: result.amount,
          billingDay: result.day,
        );
    ref.invalidate(spaceFixedExpensesProvider(space.id));
  }
}

class _ScheduleRowData {
  const _ScheduleRowData({
    required this.id,
    required this.name,
    required this.amount,
    required this.day,
    required this.isIncome,
  });

  final int id;
  final String name;
  final double amount;
  final int? day;
  final bool isIncome;
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.items,
    required this.fmt,
    required this.emptyIcon,
    required this.emptyText,
    required this.addLabel,
    required this.addColor,
    required this.onAdd,
    required this.onDelete,
  });

  final List<_ScheduleRowData> items;
  final NumberFormat fmt;
  final IconData emptyIcon;
  final String emptyText;
  final String addLabel;
  final Color addColor;
  final VoidCallback onAdd;
  final Future<void> Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xxl),
              child: Column(
                children: [
                  Icon(emptyIcon, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: AppSpacing.md),
                  Text(emptyText,
                      style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            )
          else
            ...items.map((item) => Column(
                  children: [
                    _ScheduleRow(
                      item: item,
                      fmt: fmt,
                      onDelete: () => onDelete(item.id),
                    ),
                    if (item != items.last)
                      const Divider(height: 1, indent: 52),
                  ],
                )),
          const Divider(height: 1),
          _AddRow(label: addLabel, color: addColor, onTap: onAdd),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.item,
    required this.fmt,
    required this.onDelete,
  });

  final _ScheduleRowData item;
  final NumberFormat fmt;
  final VoidCallback onDelete;

  String get _dayLabel {
    final day = item.day;
    if (day == null) return '매월';
    return day >= 31 ? '매월 말일' : '매월 $day일';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = item.isIncome ? AppColors.income : AppColors.expense;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.isIncome ? Icons.trending_up_rounded : Icons.repeat_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                Text(_dayLabel,
                    style: tt.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '${item.isIncome ? '+' : '-'}${fmt.format(item.amount.round())}원',
            style: tt.bodyMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textSecondary),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

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

class _ScheduleFormResult {
  const _ScheduleFormResult({required this.name, required this.amount, required this.day});
  final String name;
  final double amount;
  final int day;
}

class _ScheduleForm extends StatefulWidget {
  const _ScheduleForm();

  @override
  State<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<_ScheduleForm> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  int _day = 1;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (name.isEmpty || amount <= 0) return;
    Navigator.of(context).pop(_ScheduleFormResult(name: name, amount: amount, day: _day));
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(controller: _nameCtrl, label: '이름', hint: '예: 월세, 구독료', autofocus: true),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _amountCtrl,
          label: '금액',
          keyboardType: TextInputType.number,
          suffixText: '원',
        ),
        const SizedBox(height: AppSpacing.md),
        Text('매월 며칠', style: tt.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: List.generate(31, (i) {
            final day = i + 1;
            final isLast = day == 31;
            final isSelected = day == _day;
            return GestureDetector(
              onTap: () => setState(() => _day = day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  isLast ? '말일' : '$day',
                  style: tt.bodySmall?.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    fontSize: isLast ? 9 : null,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
          ),
          child: const Text('추가'),
        ),
      ],
    );
  }
}
