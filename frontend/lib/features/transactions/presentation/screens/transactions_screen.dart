import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/moun_calendar.dart';
import '../../../../shared/widgets/selection_chip.dart';
import '../../../../shared/widgets/transaction_list.dart' show TransactionItem;
import '../providers/transaction_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  bool _showCalendar = true;
  Set<String> _filter = {'전체'};
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final txByDayAsync = ref.watch(transactionsByDateProvider);

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
                  Text('거래 내역', style: tt.headlineMedium),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGlass,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        _ViewToggleBtn(
                          icon: Icons.calendar_month_rounded,
                          active: _showCalendar,
                          onTap: () => setState(() => _showCalendar = true),
                        ),
                        _ViewToggleBtn(
                          icon: Icons.list_rounded,
                          active: !_showCalendar,
                          onTap: () => setState(() => _showCalendar = false),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),
          ),

          // ── 필터 칩 ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SelectionChipGroup<String>(
                items: const ['전체', '수입', '지출'],
                labelOf: (s) => s,
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
            ).animate(delay: 80.ms).fadeIn(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // ── 달력 또는 목록 ─────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl,
            ),
            sliver: SliverToBoxAdapter(
              child: txByDayAsync.when(
                data: (txByDay) {
                  final filtered = _applyFilter(txByDay);
                  final calendarData = _buildCalendarData(txByDay);

                  if (_showCalendar) {
                    final selectedTxns = _selectedDay != null
                        ? (txByDay[_selectedDay] ?? [])
                        : null;
                    return Column(
                      children: [
                        GlassCard(
                          child: MounCalendar(
                            data: calendarData,
                            selectedDay: _selectedDay,
                            onDayTap: (day) {
                              final key = DateTime(day.year, day.month, day.day);
                              setState(() {
                                _selectedDay =
                                    _selectedDay == key ? null : key;
                              });
                            },
                            onMonthChanged: (_) {
                              setState(() => _selectedDay = null);
                            },
                          ),
                        ).animate(delay: 150.ms).fadeIn(),
                        if (selectedTxns != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _DayDetail(
                            day: _selectedDay!,
                            transactions: selectedTxns,
                          ).animate().fadeIn(duration: 200.ms).slideY(
                              begin: 0.08, end: 0),
                        ],
                      ],
                    );
                  }
                  return _TransactionListView(txByDay: filtered)
                      .animate(delay: 150.ms).fadeIn();
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
    if (_filter.contains('전체')) return txByDay;
    return txByDay.map((key, items) {
      final filtered = items.where((t) {
        if (_filter.contains('수입')) return t.isIncome;
        if (_filter.contains('지출')) return !t.isIncome;
        return true;
      }).toList();
      return MapEntry(key, filtered);
    })..removeWhere((_, v) => v.isEmpty);
  }

  Map<DateTime, DayData> _buildCalendarData(
      Map<DateTime, List<TransactionItem>> txByDay) {
    return txByDay.map((day, items) {
      final income = items
          .where((t) => t.isIncome)
          .fold(0, (s, t) => s + t.amount);
      final expense = items
          .where((t) => !t.isIncome)
          .fold(0, (s, t) => s + t.amount.abs());
      return MapEntry(day, DayData(income: income, expense: expense));
    });
  }
}

class _ViewToggleBtn extends StatelessWidget {
  const _ViewToggleBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 18,
            color: active ? Colors.white : AppColors.textSecondary),
      ),
    );
  }
}

class _TransactionListView extends StatelessWidget {
  const _TransactionListView({required this.txByDay});
  final Map<DateTime, List<TransactionItem>> txByDay;

  static final _dateFmt = DateFormat('M월 d일', 'ko');

  @override
  Widget build(BuildContext context) {
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                _dateFmt.format(entry.key),
                style: tt.labelMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: entry.value.asMap().entries.map((e) {
                  final isLast = e.key == entry.value.length - 1;
                  return Column(
                    children: [
                      _TransactionRow(item: e.value),
                      if (!isLast)
                        const Divider(
                            height: 1, indent: 56, endIndent: 16),
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
          // 날짜 헤더
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
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
                Text(item.category.label, style: tt.labelSmall),
              ],
            ),
          ),
          Text(
            item.isIncome
                ? '+${_amtFmt.format(item.amount)}원'
                : '-${_amtFmt.format(item.amount.abs())}원',
            style: tt.bodyMedium?.copyWith(
              color: item.isIncome ? AppColors.income : AppColors.expense,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
