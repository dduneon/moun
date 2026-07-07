import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/selection_chip.dart';
import '../../../../shared/widgets/transaction_list.dart' show TransactionItem;
import '../../domain/transaction_models.dart' show TransactionType;
import '../../../budget/domain/budget_models.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../spaces/domain/space_model.dart';
import '../../../spaces/presentation/providers/space_budget_provider.dart';
import '../../../spaces/presentation/providers/space_provider.dart';
import '../../../spaces/presentation/providers/space_transaction_provider.dart';
import '../../../spaces/presentation/widgets/space_switcher.dart';
import '../providers/transaction_provider.dart';
import '../widgets/add_transaction_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  Set<String> _filter = {'전체'};
  bool _excludeFixed = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final spaceContext = ref.watch(currentSpaceProvider).value;
    final isSpace = spaceContext is SpaceSelected;

    final txByDayAsync = isSpace
        ? ref.watch(spaceTransactionsByDateProvider)
        : ref.watch(transactionsByDateProvider);
    final AsyncValue<BudgetCycle?> cycleAsync = isSpace
        ? ref.watch(currentSpaceCycleProvider)
        : ref.watch(currentCycleProvider);
    final title = isSpace ? '${spaceContext.space.name} 거래 내역' : '거래 내역';

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── 헤더 ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: tt.headlineMedium)
                        .animate()
                        .fadeIn(duration: 300.ms),
                  ),
                  const SpaceSwitcher(),
                ],
              ),
            ),
          ),

          // ── 기준일 범위 + 소비 요약 ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: cycleAsync.when(
                data: (cycle) => cycle == null
                    ? const SizedBox.shrink()
                    : txByDayAsync.when(
                        data: (txByDay) => _SummaryCard(
                          cycle: cycle,
                          txByDay: _applyFilter(txByDay),
                          isFiltered: !_filter.contains('전체') || _excludeFixed,
                        ).animate(delay: 60.ms).fadeIn(),
                        loading: () => const SizedBox.shrink(),
                        error: (e, st) => const SizedBox.shrink(),
                      ),
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // ── 필터 칩 ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  SelectionChipGroup<String>(
                    items: const ['전체', '수입', '지출', '저축'],
                    labelOf: (s) => s,
                    selected: _filter,
                    onSelected: (v) => setState(() => _filter = v),
                  ),
                  const Spacer(),
                  if (!_filter.contains('수입')) GestureDetector(
                    onTap: () => setState(() => _excludeFixed = !_excludeFixed),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: _excludeFixed
                            ? AppColors.expensePending.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _excludeFixed
                              ? AppColors.expensePending
                              : AppColors.divider,
                          width: _excludeFixed ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.repeat_rounded,
                            size: 12,
                            color: _excludeFixed
                                ? AppColors.expensePending
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '고정 지출 제외',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _excludeFixed
                                  ? AppColors.expensePending
                                  : AppColors.textSecondary,
                              fontWeight: _excludeFixed
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // ── 거래 목록 ─────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl,
            ),
            sliver: SliverToBoxAdapter(
              child: txByDayAsync.when(
                data: (txByDay) {
                  final filtered = _applyFilter(txByDay);
                  return _TransactionListView(txByDay: filtered)
                      .animate(delay: 150.ms)
                      .fadeIn();
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('거래 내역을 불러올 수 없어요',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<TransactionItem>> _applyFilter(
      Map<DateTime, List<TransactionItem>> txByDay) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final result = Map.fromEntries(
      txByDay.entries.where((e) => !e.key.isAfter(todayKey)),
    );
    return result.map((key, items) {
      final filtered = items.where((t) {
        if (!_filter.contains('전체')) {
          if (_filter.contains('수입') && t.type != TransactionType.income) return false;
          if (_filter.contains('지출') && t.type != TransactionType.expense) return false;
          if (_filter.contains('저축') && t.type != TransactionType.saving) return false;
        }
        if (_excludeFixed && t.isFixed && !t.isIncome) return false;
        return true;
      }).toList();
      return MapEntry(key, filtered);
    })..removeWhere((_, v) => v.isEmpty);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.cycle,
    required this.txByDay,
    this.isFiltered = false,
  });

  final BudgetCycle cycle;
  final Map<DateTime, List<TransactionItem>> txByDay;
  final bool isFiltered;

  static final _dateFmt = DateFormat('M월 d일', 'ko');

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final allItems = txByDay.values.expand((e) => e).toList();
    final totalIncome =
        allItems.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
    final totalExpense = allItems
        .where((t) => !t.isIncome && !t.isSaving)
        .fold(0, (s, t) => s + t.amount.abs());
    final totalSaving = allItems
        .where((t) => t.isSaving)
        .fold(0, (s, t) => s + t.amount.abs());

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기준일 범위
          Row(
            children: [
              const Icon(Icons.date_range_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${_dateFmt.format(cycle.startDate)} – 오늘',
                style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
              ),
              if (isFiltered) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '필터 적용됨',
                    style: tt.labelSmall?.copyWith(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // 수입 / 지출 / (저축) / 합계 요약
          Builder(builder: (context) {
            final net = totalIncome - totalExpense - totalSaving;
            final tiles = [
              _SummaryTile(
                label: '수입',
                amount: totalIncome,
                color: AppColors.income,
                sign: '+',
              ),
              _SummaryTile(
                label: '지출',
                amount: totalExpense,
                color: AppColors.expense,
                sign: '-',
              ),
              _SummaryTile(
                label: '저축',
                amount: totalSaving,
                color: AppColors.saving,
                sign: '-',
              ),
              _SummaryTile(
                label: '합계',
                amount: net,
                color: net >= 0 ? AppColors.income : AppColors.expense,
                sign: net >= 0 ? '+' : '-',
                absolute: true,
              ),
            ];
            return Row(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) Container(width: 1, height: 36, color: AppColors.divider),
                  Expanded(child: tiles[i]),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.sign,
    this.absolute = false,
  });

  final String label;
  final int amount;
  final Color color;
  final String sign;
  final bool absolute;

  static final _fmt = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final displayAmt = absolute ? amount.abs() : amount;
    return Column(
      children: [
        Text(label,
            style:
                tt.labelSmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          '$sign${_fmt.format(displayAmt)}원',
          style: tt.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _TransactionListView extends ConsumerWidget {
  const _TransactionListView({required this.txByDay});
  final Map<DateTime, List<TransactionItem>> txByDay;

  static final _dateFmt = DateFormat('M월 d일 EEEE', 'ko');
  static final _amtFmt = NumberFormat('#,###');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final sorted = txByDay.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    if (sorted.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Column(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 48,
                  color: AppColors.textSecondary.withValues(alpha: 0.3)),
              const SizedBox(height: AppSpacing.md),
              Text('거래 내역이 없어요',
                  style: tt.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: sorted.map((entry) {
        final dayIncome = entry.value
            .where((t) => t.isIncome)
            .fold(0, (s, t) => s + t.amount);
        final dayExpense = entry.value
            .where((t) => !t.isIncome)
            .fold(0, (s, t) => s + t.amount.abs());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 헤더 행
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    _dateFmt.format(entry.key),
                    style: tt.labelMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  if (dayIncome > 0)
                    Text(
                      '+${_amtFmt.format(dayIncome)}원',
                      style: tt.labelSmall?.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500),
                    ),
                  if (dayIncome > 0 && dayExpense > 0)
                    Text(
                      ' / ',
                      style: tt.labelSmall?.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.35)),
                    ),
                  if (dayExpense > 0)
                    Text(
                      '-${_amtFmt.format(dayExpense)}원',
                      style: tt.labelSmall?.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: entry.value.asMap().entries.map((e) {
                  final isLast = e.key == entry.value.length - 1;
                  return Column(
                    children: [
                      _TransactionRow(item: e.value, ref: ref),
                      if (!isLast)
                        const Divider(height: 1, indent: 56, endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      }).toList(),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item, required this.ref});
  final TransactionItem item;
  final WidgetRef ref;

  static final _amtFmt = NumberFormat('#,###');

  Future<void> _showActions(BuildContext context) async {
    await AppBottomSheet.show<void>(
      context,
      child: _TransactionActionSheet(item: item, ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => _showActions(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.category.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.category.icon,
                size: 18, color: item.category.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Text(item.category.label, style: tt.labelSmall),
                    if (item.isFixed) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: (item.isIncome
                                  ? AppColors.income
                                  : item.isSaving
                                      ? AppColors.saving
                                      : AppColors.expensePending)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.isIncome ? '고정 수입' : item.isSaving ? '고정 저축' : '고정 지출',
                          style: tt.labelSmall?.copyWith(
                            fontSize: 10,
                            color: item.isIncome
                                ? AppColors.income
                                : item.isSaving
                                    ? AppColors.saving
                                    : AppColors.expensePending,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.memo != null && item.memo!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.memo!,
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Text(
            item.isIncome
                ? '+${_amtFmt.format(item.amount)}원'
                : '-${_amtFmt.format(item.amount.abs())}원',
            style: tt.bodyMedium?.copyWith(
              color: item.isIncome
                  ? AppColors.income
                  : item.isSaving
                      ? AppColors.saving
                      : AppColors.expense,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _TransactionActionSheet extends StatelessWidget {
  const _TransactionActionSheet({required this.item, required this.ref});
  final TransactionItem item;
  final WidgetRef ref;

  Future<void> _delete(BuildContext context) async {
    Navigator.pop(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: '거래 삭제',
      message: '이 거래를 삭제할까요?',
      confirmLabel: '삭제',
      cancelLabel: '취소',
    );
    if (confirmed == true) {
      await ref.read(transactionRepositoryProvider).delete(item.id);
      ref.invalidate(currentCycleTransactionsProvider);
      ref.invalidate(availableBudgetProvider);
    }
  }

  Future<void> _edit(BuildContext context) async {
    Navigator.pop(context);
    await AddTransactionSheet.show(context, initialItem: item);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final amtFmt = NumberFormat('#,###');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(item.name,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            item.isIncome
                ? '+${amtFmt.format(item.amount)}원'
                : '-${amtFmt.format(item.amount.abs())}원',
            style: tt.bodySmall?.copyWith(
              color: item.isIncome
                  ? AppColors.income
                  : item.isSaving
                      ? AppColors.saving
                      : AppColors.expense,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SheetAction(
          icon: Icons.edit_rounded,
          iconColor: AppColors.primary,
          label: '수정',
          onTap: () => _edit(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SheetAction(
          icon: Icons.delete_rounded,
          iconColor: AppColors.expense,
          label: '삭제',
          labelColor: AppColors.expense,
          onTap: () => _delete(context),
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
