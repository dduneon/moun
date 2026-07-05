import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/amount_display.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/category_selector.dart' show CategoryItem;
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/moun_calendar.dart';
import '../../../../shared/widgets/transaction_list.dart' show TransactionItem;
import '../../domain/space_model.dart';
import '../providers/space_budget_provider.dart';
import '../providers/space_provider.dart';
import '../providers/space_schedule_provider.dart';
import '../providers/space_transaction_provider.dart';

/// Space가 선택된 경우 홈/거래 화면에서 보여줄 예산 카드 + 달력.
/// 개인 공간과 같은 달력 UI를 쓰되, Space 고정수입/지출은 매월 반복만
/// 지원하므로 발생일 계산이 개인 공간보다 단순하다(한 달에 하루뿐).
class SpaceHomeBody extends ConsumerStatefulWidget {
  const SpaceHomeBody({super.key, required this.space});
  final SpaceModel space;

  @override
  ConsumerState<SpaceHomeBody> createState() => _SpaceHomeBodyState();
}

class _SpaceHomeBodyState extends ConsumerState<SpaceHomeBody> {
  DateTime? _selectedDay;
  DateTime _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Space 고정수입/지출은 매월 반복만 지원 → 발생일은 그 달에 딱 하루.
  DateTime? _monthlyOccurrence(DateTime month, int? day) {
    if (day == null) return null;
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final actual = day > lastDay ? lastDay : day;
    return DateTime(month.year, month.month, actual);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final space = widget.space;

    final budgetAsync = ref.watch(currentSpaceBudgetProvider);
    final cycleAsync = ref.watch(currentSpaceCycleProvider);
    final txByDayAsync = ref.watch(spaceTransactionsByDateProvider);
    final fixedIncomesAsync =
        ref.watch(spaceFixedIncomesForMonthProvider((spaceId: space.id, month: _viewMonth)));
    final fixedExpensesAsync =
        ref.watch(spaceFixedExpensesForMonthProvider((spaceId: space.id, month: _viewMonth)));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(Icons.groups_rounded, color: AppColors.income, size: 18),
            const SizedBox(width: 6),
            Text('멤버 ${space.memberCount}명', style: tt.bodySmall?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        budgetAsync.when(
          data: (budget) {
            if (budget == null) return const SizedBox.shrink();
            final cycle = cycleAsync.value;
            final fmt = DateFormat('M/d');
            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('사용 가능 예산',
                          style: tt.labelMedium?.copyWith(color: AppColors.textSecondary)),
                      const Spacer(),
                      if (cycle != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${fmt.format(cycle.startDate)} ~ ${fmt.format(cycle.endDate)}',
                            style: tt.labelSmall?.copyWith(color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AmountDisplay(amount: budget.available.round(), size: AmountSize.large),
                ],
              ),
            );
          },
          loading: () => const GlassCard(
            child: SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
          ),
          error: (_, __) => GlassCard(
            child: Text('예산 정보를 불러올 수 없어요', style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        txByDayAsync.when(
          data: (txByDay) {
            final fixedIncomes = fixedIncomesAsync.value ?? [];
            final fixedExpenses = fixedExpensesAsync.value ?? [];
            final now = DateTime.now();
            final vm = _viewMonth;
            final isFutureMonth = vm.year > now.year || (vm.year == now.year && vm.month > now.month);
            final calendarData = <DateTime, DayData>{};

            txByDay.forEach((day, items) {
              final income = items.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
              final expense = items.where((t) => !t.isIncome).fold(0, (s, t) => s + t.amount.abs());
              calendarData[day] = DayData(income: income, expense: expense);
            });

            final today = DateTime(now.year, now.month, now.day);

            for (final fi in fixedIncomes) {
              final d = _monthlyOccurrence(vm, fi.scheduledDay);
              if (d == null) continue;
              final isPending = isFutureMonth || d.isAfter(today);
              if (!isPending) continue;
              final amt = fi.expectedAmount.round();
              final prev = calendarData[d] ?? const DayData();
              calendarData[d] = DayData(income: prev.income + amt, expense: prev.expense, hasPending: true);
            }

            for (final fe in fixedExpenses) {
              if (!fe.isActive) continue;
              final d = _monthlyOccurrence(vm, fe.billingDay);
              if (d == null) continue;
              final isPending = isFutureMonth || d.isAfter(today);
              if (!isPending) continue;
              final amt = fe.amount.round();
              final prev = calendarData[d] ?? const DayData();
              calendarData[d] = DayData(income: prev.income, expense: prev.expense + amt, hasPending: true);
            }

            List<TransactionItem>? selectedItems;
            if (_selectedDay != null) {
              final real = txByDay[_selectedDay] ?? [];
              final pseudo = <TransactionItem>[];

              for (final fi in fixedIncomes) {
                final d = _monthlyOccurrence(vm, fi.scheduledDay);
                if (d == null) continue;
                final isPending = isFutureMonth || d.isAfter(today);
                if (!isPending) continue;
                if (_isSameDay(d, _selectedDay!)) {
                  pseudo.add(TransactionItem(
                    id: -fi.id,
                    name: fi.name,
                    amount: fi.expectedAmount.round(),
                    date: d,
                    category: const CategoryItem(
                      id: 0,
                      label: '고정 수입',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.income,
                    ),
                    isPending: true,
                    isFixed: true,
                  ));
                }
              }

              for (final fe in fixedExpenses) {
                if (!fe.isActive) continue;
                final d = _monthlyOccurrence(vm, fe.billingDay);
                if (d == null) continue;
                final isPending = isFutureMonth || d.isAfter(today);
                if (!isPending) continue;
                if (_isSameDay(d, _selectedDay!)) {
                  pseudo.add(TransactionItem(
                    id: -fe.id - 100000,
                    name: fe.name,
                    amount: -fe.amount.round(),
                    date: d,
                    category: const CategoryItem(
                      id: 0,
                      label: '고정 지출',
                      icon: Icons.repeat_rounded,
                      color: AppColors.expensePending,
                    ),
                    isPending: true,
                    isFixed: true,
                  ));
                }
              }

              selectedItems = [...real, ...pseudo];
            }

            return Column(
              children: [
                GlassCard(
                  child: MounCalendar(
                    data: calendarData,
                    selectedDay: _selectedDay,
                    onDayTap: (day) {
                      final key = DateTime(day.year, day.month, day.day);
                      setState(() {
                        _selectedDay = _selectedDay == key ? null : key;
                      });
                    },
                    onMonthChanged: (month) {
                      setState(() {
                        _viewMonth = DateTime(month.year, month.month);
                        _selectedDay = null;
                      });
                    },
                  ),
                ),
                if (selectedItems != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SpaceDayDetail(day: _selectedDay!, transactions: selectedItems, space: space),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _SpaceDayDetail extends ConsumerWidget {
  const _SpaceDayDetail({required this.day, required this.transactions, required this.space});
  final DateTime day;
  final List<TransactionItem> transactions;
  final SpaceModel space;

  static final _dateFmt = DateFormat('M월 d일 EEEE', 'ko');
  static final _amtFmt = NumberFormat('#,###');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final totalIncome = transactions.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
    final totalExpense = transactions.where((t) => !t.isIncome).fold(0, (s, t) => s + t.amount.abs());

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_dateFmt.format(day), style: tt.titleMedium),
              const Spacer(),
              if (totalIncome > 0)
                Text('+${_amtFmt.format(totalIncome)}원',
                    style: tt.labelMedium?.copyWith(color: AppColors.income, fontWeight: FontWeight.w600)),
              if (totalIncome > 0 && totalExpense > 0) const SizedBox(width: AppSpacing.sm),
              if (totalExpense > 0)
                Text('-${_amtFmt.format(totalExpense)}원',
                    style: tt.labelMedium?.copyWith(color: AppColors.expense, fontWeight: FontWeight.w600)),
            ],
          ),
          if (transactions.isEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('거래 내역이 없어요', style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            ...transactions.asMap().entries.map((e) {
              final isLast = e.key == transactions.length - 1;
              return Column(
                children: [
                  _SpaceTransactionRow(item: e.value, space: space),
                  if (!isLast) const Divider(height: 1, indent: 56, endIndent: 0),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _SpaceTransactionRow extends ConsumerWidget {
  const _SpaceTransactionRow({required this.item, required this.space});
  final TransactionItem item;
  final SpaceModel space;

  static final _amtFmt = NumberFormat('#,###');

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: '거래 삭제',
      message: '이 거래를 삭제할까요?',
      confirmLabel: '삭제',
      cancelLabel: '취소',
    );
    if (confirmed) {
      await ref.read(spaceTransactionRepositoryProvider).delete(space.id, item.id);
      ref.invalidate(currentSpaceTransactionsProvider);
      ref.invalidate(currentSpaceBudgetProvider);
    }
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    if (item.id < 0) return; // 예정 항목(pseudo) — 액션 없음
    await AppBottomSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Text(item.name, style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: AppColors.expense),
            title: const Text('삭제', style: TextStyle(color: AppColors.expense)),
            onTap: () {
              Navigator.pop(context);
              _delete(context, ref);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => _showActions(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: item.category.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(item.category.icon, size: 18, color: item.category.color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(item.name,
                            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (item.isPending) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.expensePending.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('예정',
                              style: tt.labelSmall?.copyWith(color: AppColors.expensePending, fontSize: 9)),
                        ),
                      ],
                    ],
                  ),
                  Text(item.category.label, style: tt.labelSmall),
                ],
              ),
            ),
            Text(
              item.isIncome ? '+${_amtFmt.format(item.amount)}원' : '-${_amtFmt.format(item.amount.abs())}원',
              style: tt.bodyMedium?.copyWith(
                color: item.isPending
                    ? (item.isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.5)
                    : item.isIncome
                        ? AppColors.income
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
