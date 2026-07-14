import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/domain/auth_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/budget/domain/budget_models.dart';
import '../../../../features/budget/presentation/providers/budget_provider.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import '../providers/selected_calendar_date_provider.dart';
import '../../../../features/transactions/presentation/providers/transaction_provider.dart';
import '../../../../shared/widgets/amount_display.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/moun_calendar.dart';
import '../../../../shared/widgets/category_selector.dart' show CategoryItem;
import '../../../../shared/widgets/transaction_list.dart' show TransactionItem;
import '../../../transactions/domain/transaction_models.dart' show TransactionType;
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';
import '../../../spaces/domain/space_model.dart';
import '../../../spaces/presentation/providers/space_provider.dart';
import '../../../spaces/presentation/widgets/space_home_body.dart';
import '../../../spaces/presentation/widgets/space_switcher.dart';
import '../../../vouchers/presentation/providers/voucher_provider.dart';

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
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(selectedCalendarDateProvider.notifier).state = _selectedDay;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // 주어진 달에서 고정 항목의 발생 날짜 목록 계산 (백엔드 schedule_generator 로직과 동일)
  List<DateTime> _occurrenceDatesForMonth(
    DateTime month, {
    required String frequency,
    int? day,
    int? dayOfWeek,
    required DateTime effectiveFrom,
  }) {
    final year = month.year;
    final mon = month.month;
    final lastDay = DateTime(year, mon + 1, 0).day;
    final monthStart = DateTime(year, mon, 1);
    final monthEnd = DateTime(year, mon, lastDay);

    if (frequency == 'monthly' && day != null) {
      final actual = day.clamp(1, lastDay);
      return [DateTime(year, mon, actual)];
    }

    if (frequency == 'weekly' && dayOfWeek != null) {
      // Python: 0=Mon...6=Sun / Dart: 1=Mon...7=Sun
      final dartDow = dayOfWeek % 7 + 1;
      final result = <DateTime>[];
      for (var d = 1; d <= lastDay; d++) {
        final dt = DateTime(year, mon, d);
        if (dt.weekday == dartDow) result.add(dt);
      }
      return result;
    }

    if (frequency == 'biweekly' && dayOfWeek != null) {
      final dartDow = dayOfWeek % 7 + 1;
      final anchorOffset = (dartDow - effectiveFrom.weekday) % 7;
      var cur = effectiveFrom.add(Duration(days: anchorOffset));
      // cur을 monthStart 이상으로 2주씩 전진
      if (cur.isBefore(monthStart)) {
        final weeks = ((monthStart.difference(cur).inDays) / 14).ceil();
        cur = cur.add(Duration(days: weeks * 14));
      }
      final result = <DateTime>[];
      while (!cur.isAfter(monthEnd)) {
        result.add(cur);
        cur = cur.add(const Duration(days: 14));
      }
      return result;
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthStateAuthenticated ? authState.user : null;
    final tt = Theme.of(context).textTheme;

    final cycleAsync = ref.watch(currentCycleProvider);
    final budgetAsync = ref.watch(availableBudgetProvider);
    final txByDayAsync = ref.watch(transactionsByDateProvider);
    final fixedIncomesAsync = ref.watch(fixedIncomesProvider(_viewMonth));
    final fixedExpensesAsync = ref.watch(fixedExpensesProvider(_viewMonth));
    final spaceContext = ref.watch(currentSpaceProvider).value;

    if (spaceContext is SpaceSelected) {
      return SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Row(
                children: [
                  Expanded(child: Text(spaceContext.space.name, style: tt.headlineMedium)),
                  const SpaceSwitcher(),
                ],
              ),
            ),
            Expanded(child: SpaceHomeBody(space: spaceContext.space)),
          ],
        ),
      );
    }

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
                  const SpaceSwitcher(),
                  const SizedBox(width: AppSpacing.xs),
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

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // ── 수입 / 지출 / 저축 카드 ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: budgetAsync.when(
                data: (budget) {
                  final cards = [
                    _BudgetStatCard(
                      icon: Icons.arrow_circle_up_rounded,
                      color: AppColors.income,
                      label: '수입',
                      badge: budget.hasPendingIncome ? '예정' : null,
                      amount: budget.expectedIncome.round(),
                    ),
                    _BudgetStatCard(
                      icon: Icons.arrow_circle_down_rounded,
                      color: AppColors.expense,
                      label: '지출',
                      badge: budget.hasPendingFixedExpense ? '예정포함' : null,
                      amount: -budget.totalSpentWithPending.round(),
                    ),
                    _BudgetStatCard(
                      icon: Icons.savings_rounded,
                      color: AppColors.saving,
                      label: '저축',
                      amount: -budget.totalSaving.round(),
                    ),
                  ];

                  return LayoutBuilder(builder: (context, constraints) {
                    final cardWidth =
                        (constraints.maxWidth - AppSpacing.sm * 2) / 3;
                    return Row(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.sm),
                          SizedBox(width: cardWidth, child: cards[i]),
                        ],
                      ],
                    );
                  });
                },
                loading: () => const SizedBox(height: 44),
                error: (e, _) => const SizedBox.shrink(),
              ).animate(delay: 200.ms).fadeIn(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // ── 상품권 잔액 ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: const _VoucherBalanceStrip(),
            ),
          ),

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
                        .where((t) => !t.isIncome && !t.isSaving)
                        .fold(0, (s, t) => s + t.amount.abs());
                    calendarData[day] = DayData(income: income, expense: expense);
                  });

                  final today = DateTime(now.year, now.month, now.day);

                  // 고정 수입: 이번 달 모든 발생일 추가 (과거는 txByDay에 실제 transaction 존재)
                  for (final fi in fixedIncomes) {
                    final dates = _occurrenceDatesForMonth(
                      vm,
                      frequency: fi.frequency,
                      day: fi.scheduledDay,
                      dayOfWeek: fi.dayOfWeek,
                      effectiveFrom: fi.effectiveFrom,
                    );
                    for (final d in dates) {
                      final isPending = isFutureMonth || d.isAfter(today);
                      if (!isPending) continue;
                      final amt = fi.expectedAmount.round();
                      final prev = calendarData[d] ?? const DayData();
                      calendarData[d] = DayData(
                        income: prev.income + amt,
                        expense: prev.expense,
                        hasPending: true,
                      );
                    }
                  }

                  // 고정 지출: 이번 달 모든 발생일 추가 (과거는 txByDay에 실제 transaction 존재)
                  // 고정 저축은 '소비'가 아니므로 실제 거래와 마찬가지로 지출 합계에서 제외한다.
                  for (final fe in fixedExpenses) {
                    if (!fe.isActive || fe.isSaving) continue;
                    final dates = _occurrenceDatesForMonth(
                      vm,
                      frequency: fe.frequency,
                      day: fe.billingDay,
                      dayOfWeek: fe.dayOfWeek,
                      effectiveFrom: fe.effectiveFrom,
                    );
                    for (final d in dates) {
                      final isPending = isFutureMonth || d.isAfter(today);
                      if (!isPending) continue;
                      final amt = fe.amount.round();
                      final prev = calendarData[d] ?? const DayData();
                      calendarData[d] = DayData(
                        income: prev.income,
                        expense: prev.expense + amt,
                        hasPending: true,
                      );
                    }
                  }

                  // 선택한 날의 상세 항목
                  List<TransactionItem>? selectedItems;
                  if (_selectedDay != null) {
                    final real = txByDay[_selectedDay] ?? [];
                    final pseudo = <TransactionItem>[];

                    for (final fi in fixedIncomes) {
                      final dates = _occurrenceDatesForMonth(
                        vm,
                        frequency: fi.frequency,
                        day: fi.scheduledDay,
                        dayOfWeek: fi.dayOfWeek,
                        effectiveFrom: fi.effectiveFrom,
                      );
                      for (final d in dates) {
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
                    }

                    for (final fe in fixedExpenses) {
                      if (!fe.isActive) continue;
                      final dates = _occurrenceDatesForMonth(
                        vm,
                        frequency: fe.frequency,
                        day: fe.billingDay,
                        dayOfWeek: fe.dayOfWeek,
                        effectiveFrom: fe.effectiveFrom,
                      );
                      for (final d in dates) {
                        final isPending = isFutureMonth || d.isAfter(today);
                        if (!isPending) continue;
                        if (_isSameDay(d, _selectedDay!)) {
                          pseudo.add(TransactionItem(
                            id: -fe.id - 100000,
                            name: fe.name,
                            amount: -fe.amount.round(),
                            type: fe.isSaving
                                ? TransactionType.saving
                                : TransactionType.expense,
                            date: d,
                            category: fe.isSaving
                                ? const CategoryItem(
                                    id: 0,
                                    label: '고정 저축',
                                    icon: Icons.savings_rounded,
                                    color: AppColors.saving,
                                  )
                                : const CategoryItem(
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
                            ref.read(selectedCalendarDateProvider.notifier).state =
                                _selectedDay;
                          },
                          onMonthChanged: (month) {
                            setState(() {
                              _viewMonth = DateTime(month.year, month.month);
                              _selectedDay = null;
                            });
                            ref.read(selectedCalendarDateProvider.notifier).state = null;
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
            spent: (budget.variableExpense + budget.totalFixedExpense).round(),
            total: budget.expectedIncome.clamp(0, double.infinity).round(),
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

class _BudgetStatCard extends StatelessWidget {
  const _BudgetStatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.amount,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int amount;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(label,
                    style: tt.labelSmall, overflow: TextOverflow.ellipsis),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: tt.labelSmall?.copyWith(color: color, fontSize: 9),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          AmountDisplay(amount: amount, size: AmountSize.small),
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

class _DayDetail extends ConsumerWidget {
  const _DayDetail({required this.day, required this.transactions});
  final DateTime day;
  final List<TransactionItem> transactions;

  static final _dateFmt = DateFormat('M월 d일 EEEE', 'ko');
  static final _amtFmt = NumberFormat('#,###');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final totalIncome = transactions
        .where((t) => t.isIncome)
        .fold(0, (s, t) => s + t.amount);
    final totalExpense = transactions
        .where((t) => !t.isIncome && !t.isSaving)
        .fold(0, (s, t) => s + t.amount.abs());
    final totalSaving = transactions
        .where((t) => t.isSaving)
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
              if ((totalIncome > 0 || totalExpense > 0) && totalSaving > 0)
                const SizedBox(width: AppSpacing.sm),
              if (totalSaving > 0)
                Text('저축 ${_amtFmt.format(totalSaving)}원',
                    style: tt.labelMedium?.copyWith(
                        color: AppColors.saving,
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
                  _TransactionRow(item: e.value, ref: ref),
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
                Row(
                  children: [
                    Text(item.category.label,
                        style: tt.labelSmall?.copyWith(
                          color: item.isPending
                              ? AppColors.textSecondary.withValues(alpha: 0.6)
                              : null,
                        )),
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
                          item.isIncome ? '고정수입' : item.isSaving ? '고정저축' : '고정지출',
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
              color: (item.isIncome
                      ? AppColors.income
                      : item.isSaving
                          ? AppColors.saving
                          : AppColors.expense)
                  .withValues(alpha: item.isPending ? 0.5 : 1),
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

  Future<void> _deleteTransaction(BuildContext context) async {
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

  Future<void> _editTransaction(BuildContext context) async {
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
        if (item.id < 0) ...[
          // 예정 항목 (아직 날짜 안 됨 — pseudo)
          Container(
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md, horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.06),
              borderRadius: AppRadius.buttonBorderRadius,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.schedule_rounded,
                      size: 18, color: AppColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '예정된 항목이에요. 날짜가 지나면 거래 내역에 자동 기록돼요.',
                    style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // 실제 transaction (고정 수입/지출 포함) — 수정/삭제 가능
          _SheetAction(
            icon: Icons.edit_rounded,
            iconColor: AppColors.primary,
            label: '수정',
            onTap: () => _editTransaction(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SheetAction(
            icon: Icons.delete_rounded,
            iconColor: AppColors.expense,
            label: '삭제',
            labelColor: AppColors.expense,
            onTap: () => _deleteTransaction(context),
          ),
        ],
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

// ── 상품권 잔액 스트립 ─────────────────────────────────────────

class _VoucherBalanceStrip extends ConsumerWidget {
  const _VoucherBalanceStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final fmt = NumberFormat('#,###');
    const accent = Color(0xFFB39DFF);
    final vouchersAsync = ref.watch(activeVouchersProvider);

    return vouchersAsync.maybeWhen(
      data: (vouchers) {
        final withBalance = vouchers.where((v) => v.balance > 0).toList();
        if (withBalance.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: GlassCard(
          child: InkWell(
            onTap: () => context.push('/settings/vouchers'),
            borderRadius: AppRadius.cardBorderRadius,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.card_giftcard_rounded,
                      size: 18, color: accent),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('상품권 잔액',
                          style: tt.labelSmall
                              ?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        withBalance
                            .map((v) => '${v.name} ${fmt.format(v.balance.round())}원')
                            .join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600, color: accent),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
          ).animate(delay: 250.ms).fadeIn(),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
