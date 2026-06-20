import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/domain/auth_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/budget/domain/budget_models.dart';
import '../../../../features/budget/presentation/providers/budget_provider.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import '../../../../features/transactions/presentation/providers/transaction_provider.dart';
import '../../../../shared/widgets/amount_display.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/moun_calendar.dart';
import '../../../../shared/widgets/category_selector.dart' show CategoryItem;
import '../../../../shared/widgets/transaction_list.dart' show TransactionItem;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime? _selectedDay;
  DateTime _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthStateAuthenticated ? authState.user : null;
    final tt = Theme.of(context).textTheme;

    final cycleAsync = ref.watch(currentCycleProvider);
    final budgetAsync = ref.watch(availableBudgetProvider);
    final txByDayAsync = ref.watch(transactionsByDateProvider);
    final fixedIncomesAsync = ref.watch(fixedIncomesProvider);
    final fixedExpensesAsync = ref.watch(fixedExpensesProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── 상단 인사 + 알림 ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user != null ? '안녕하세요, ${user.name}님 👋' : '모운',
                        style: tt.headlineMedium,
                      ),
                      cycleAsync.when(
                        data: (c) => Text(
                          '${c.label} 예산 현황',
                          style: tt.bodyMedium?.copyWith(
                              color: AppColors.textSecondary),
                        ),
                        loading: () => Text('불러오는 중...',
                            style: tt.bodyMedium?.copyWith(
                                color: AppColors.textSecondary)),
                        error: (e, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    color: AppColors.textPrimary,
                    onPressed: () {},
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // ── 메인 예산 카드 ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: budgetAsync.when(
                data: (budget) => _BudgetCard(budget: budget, cycle: cycleAsync.value),
                loading: () => const _BudgetCardSkeleton(),
                error: (e, st) {
                  debugPrint('[budget error] $e\n$st');
                  return GlassCard(
                    child: Text('예산 정보를 불러올 수 없어요\n$e',
                        style: tt.bodyMedium?.copyWith(
                            color: AppColors.textSecondary)),
                  );
                },
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

          // ── 수입 / 고정지출 카드 ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: budgetAsync.when(
                data: (budget) => Row(
                  children: [
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.arrow_circle_up_rounded,
                                    color: AppColors.income, size: 14),
                                const SizedBox(width: 4),
                                Text('수입', style: tt.labelSmall),
                                if (budget.hasPendingIncome) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.income.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '예정',
                                      style: tt.labelSmall?.copyWith(
                                        color: AppColors.income,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            AmountDisplay(
                              amount: budget.expectedIncome.round(),
                              size: AmountSize.small,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.repeat_rounded,
                                    color: AppColors.expensePending, size: 14),
                                const SizedBox(width: 4),
                                Text('고정지출', style: tt.labelSmall),
                              ],
                            ),
                            const SizedBox(height: 4),
                            AmountDisplay(
                              amount: -budget.fixedExpense.round(),
                              size: AmountSize.small,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox(height: 44),
                error: (e, _) => const SizedBox.shrink(),
              ).animate(delay: 200.ms).fadeIn(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // ── 달력 ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl,
            ),
            sliver: SliverToBoxAdapter(
              child: txByDayAsync.when(
                data: (txByDay) {
                  final fixedIncomes = fixedIncomesAsync.value ?? [];
                  final fixedExpenses = fixedExpensesAsync.value ?? [];
                  final now = DateTime.now();
                  final vm = _viewMonth; // 현재 보여지는 달
                  final isFutureMonth = vm.year > now.year ||
                      (vm.year == now.year && vm.month > now.month);
                  final calendarData = <DateTime, DayData>{};

                  // 실제 거래 데이터 (현재 달에만 존재)
                  txByDay.forEach((day, items) {
                    final income = items
                        .where((t) => t.isIncome)
                        .fold(0, (s, t) => s + t.amount);
                    final expense = items
                        .where((t) => !t.isIncome)
                        .fold(0, (s, t) => s + t.amount.abs());
                    calendarData[day] = DayData(income: income, expense: expense);
                  });

                  // 고정 수입: 보여지는 달의 scheduled_day에 표시
                  for (final fi in fixedIncomes) {
                    if (fi.scheduledDay == null) continue;
                    final day = DateTime(vm.year, vm.month, fi.scheduledDay!);
                    // 미래 달이거나, 같은 달인데 오늘 이후면 예정
                    final isPending = isFutureMonth || fi.scheduledDay! > now.day;
                    final amt = fi.expectedAmount.round();
                    final prev = calendarData[day] ?? const DayData();
                    calendarData[day] = DayData(
                      income: prev.income + amt,
                      expense: prev.expense,
                      hasPending: prev.hasPending || isPending,
                    );
                  }

                  // 고정 지출: 보여지는 달의 billingDay에 표시
                  for (final fe in fixedExpenses) {
                    if (!fe.isActive) continue;
                    final day = DateTime(vm.year, vm.month, fe.billingDay);
                    final isPending = isFutureMonth || fe.billingDay > now.day;
                    final amt = fe.amount.round();
                    final prev = calendarData[day] ?? const DayData();
                    calendarData[day] = DayData(
                      income: prev.income,
                      expense: prev.expense + amt,
                      hasPending: prev.hasPending || isPending,
                    );
                  }

                  // 선택한 날의 상세 항목
                  List<TransactionItem>? selectedItems;
                  if (_selectedDay != null) {
                    final real = txByDay[_selectedDay] ?? [];
                    final pseudo = <TransactionItem>[];

                    for (final fi in fixedIncomes) {
                      if (fi.scheduledDay == null) continue;
                      final day = DateTime(vm.year, vm.month, fi.scheduledDay!);
                      if (_isSameDay(day, _selectedDay!)) {
                        final isPending = isFutureMonth || fi.scheduledDay! > now.day;
                        pseudo.add(TransactionItem(
                          id: -fi.id,
                          name: fi.name,
                          amount: fi.expectedAmount.round(),
                          date: day,
                          category: const CategoryItem(
                            id: 0,
                            label: '고정 수입',
                            icon: Icons.trending_up_rounded,
                            color: AppColors.income,
                          ),
                          isPending: isPending,
                        ));
                      }
                    }

                    for (final fe in fixedExpenses) {
                      if (!fe.isActive) continue;
                      final day = DateTime(vm.year, vm.month, fe.billingDay);
                      if (_isSameDay(day, _selectedDay!)) {
                        final isPending = isFutureMonth || fe.billingDay > now.day;
                        pseudo.add(TransactionItem(
                          id: -fe.id - 100000,
                          name: fe.name,
                          amount: -fe.amount.round(),
                          date: day,
                          category: const CategoryItem(
                            id: 0,
                            label: '고정 지출',
                            icon: Icons.repeat_rounded,
                            color: AppColors.expensePending,
                          ),
                          isPending: isPending,
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
                      ).animate(delay: 250.ms).fadeIn(),
                      if (selectedItems != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _DayDetail(
                          day: _selectedDay!,
                          transactions: selectedItems,
                        ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.08, end: 0),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 서브 위젯 ─────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget, this.cycle});
  final AvailableBudget budget;
  final BudgetCycle? cycle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final fmt = DateFormat('M/d');
    final dateLabel = cycle != null
        ? '${fmt.format(cycle!.startDate)} ~ ${fmt.format(cycle!.endDate)}'
        : '';

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('사용 가능 예산',
                  style: tt.labelMedium
                      ?.copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              if (dateLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(dateLabel,
                      style: tt.labelSmall
                          ?.copyWith(color: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AmountDisplay(
            amount: budget.available.round(),
            size: AmountSize.large,
            animate: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _BudgetProgressBar(
            spent: budget.totalSpent.round(),
            total: budget.expectedIncome.round(),
          ),
        ],
      ),
    );
  }
}

class _BudgetCardSkeleton extends StatelessWidget {
  const _BudgetCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 14, width: 80,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              )),
          const SizedBox(height: AppSpacing.xs),
          Container(height: 36, width: 180,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              )),
          const SizedBox(height: AppSpacing.sm),
          Container(height: 6, width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              )),
        ],
      ),
    );
  }
}

class _BudgetProgressBar extends StatelessWidget {
  const _BudgetProgressBar({required this.spent, required this.total});
  final int spent;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
    final color = ratio > 0.85
        ? AppColors.expense
        : ratio > 0.65
            ? const Color(0xFFFFAA00)
            : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: AppColors.divider.withValues(alpha: 4.0),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(ratio * 100).toStringAsFixed(0)}% 사용',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _DayDetail extends StatelessWidget {
  const _DayDetail({required this.day, required this.transactions});
  final DateTime day;
  final List<TransactionItem> transactions;

  static final _dateFmt = DateFormat('M월 d일 EEEE', 'ko');
  static final _amtFmt = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final totalIncome = transactions
        .where((t) => t.isIncome)
        .fold(0, (s, t) => s + t.amount);
    final totalExpense = transactions
        .where((t) => !t.isIncome)
        .fold(0, (s, t) => s + t.amount.abs());

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
                    style: tt.labelMedium?.copyWith(
                        color: AppColors.income,
                        fontWeight: FontWeight.w600)),
              if (totalIncome > 0 && totalExpense > 0)
                const SizedBox(width: AppSpacing.sm),
              if (totalExpense > 0)
                Text('-${_amtFmt.format(totalExpense)}원',
                    style: tt.labelMedium?.copyWith(
                        color: AppColors.expense,
                        fontWeight: FontWeight.w600)),
            ],
          ),
          if (transactions.isEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('거래 내역이 없어요',
                    style: tt.bodyMedium?.copyWith(
                        color: AppColors.textSecondary)),
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            ...transactions.asMap().entries.map((e) {
              final isLast = e.key == transactions.length - 1;
              return Column(
                children: [
                  _TransactionRow(item: e.value),
                  if (!isLast)
                    const Divider(height: 1, indent: 56, endIndent: 0),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item});
  final TransactionItem item;

  static final _amtFmt = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
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
                          style: tt.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (item.isPending) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.expensePending.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('예정',
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.expensePending,
                              fontSize: 9,
                            )),
                      ),
                    ],
                  ],
                ),
                Text(item.category.label,
                    style: tt.labelSmall?.copyWith(
                      color: item.isPending
                          ? AppColors.textSecondary.withValues(alpha: 0.6)
                          : null,
                    )),
              ],
            ),
          ),
          Text(
            item.isIncome
                ? '+${_amtFmt.format(item.amount)}원'
                : '-${_amtFmt.format(item.amount.abs())}원',
            style: tt.bodyMedium?.copyWith(
              color: item.isPending
                  ? (item.isIncome ? AppColors.income : AppColors.expense)
                      .withValues(alpha: 0.5)
                  : item.isIncome
                      ? AppColors.income
                      : AppColors.expense,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
