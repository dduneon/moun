import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/moun_calendar.dart';
import '../../../../shared/widgets/selection_chip.dart';
import '../../../../shared/widgets/transaction_list.dart';
import '../../../../shared/widgets/amount_display.dart';
import '../../../../shared/widgets/category_selector.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  bool _showCalendar = true;
  Set<String> _filter = {'전체'};

  // TODO: Riverpod provider에서 실제 데이터 주입
  final Map<DateTime, DayData> _calendarData = {
    DateTime(2025, 6, 1): const DayData(income: 4200000),
    DateTime(2025, 6, 3): const DayData(expense: 65000),
    DateTime(2025, 6, 5): const DayData(expense: 142000),
    DateTime(2025, 6, 10): const DayData(expense: 220000),
    DateTime(2025, 6, 12): const DayData(expense: 88000, hasPending: true),
    DateTime(2025, 6, 14): const DayData(income: 150000, expense: 55000),
    DateTime(2025, 6, 16): const DayData(hasPending: true),
    DateTime(2025, 6, 18): const DayData(expense: 310000),
    DateTime(2025, 6, 21): const DayData(income: 4200000),
    DateTime(2025, 6, 23): const DayData(expense: 120000),
  };

  final Map<DateTime, List<TransactionItem>> _txByDay = {
    DateTime(2025, 6, 3): [
      TransactionItem(
        id: 1, name: '스타벅스 강남점', amount: -6500,
        date: DateTime(2025, 6, 3, 8, 42),
        category: const CategoryItem(id: 7, label: '카페', icon: Icons.local_cafe_rounded, color: Color(0xFF8D6E63)),
        memo: '아메리카노',
      ),
      TransactionItem(
        id: 2, name: '대중교통', amount: -1450,
        date: DateTime(2025, 6, 3, 9, 10),
        category: const CategoryItem(id: 2, label: '교통', icon: Icons.directions_subway_rounded, color: Color(0xFF7C6FF0)),
      ),
      TransactionItem(
        id: 3, name: '점심 식사', amount: -12000,
        date: DateTime(2025, 6, 3, 12, 30),
        category: const CategoryItem(id: 1, label: '식비', icon: Icons.restaurant_rounded, color: Color(0xFF5B8DEF)),
      ),
    ],
    DateTime(2025, 6, 14): [
      TransactionItem(
        id: 4, name: '프리랜서 수입', amount: 150000,
        date: DateTime(2025, 6, 14, 14, 0),
        category: const CategoryItem(id: 102, label: '부업', icon: Icons.work_rounded, color: Color(0xFF34C77B)),
      ),
      TransactionItem(
        id: 5, name: '저녁 모임', amount: -55000,
        date: DateTime(2025, 6, 14, 19, 30),
        category: const CategoryItem(id: 1, label: '식비', icon: Icons.restaurant_rounded, color: Color(0xFF5B8DEF)),
        memo: '친구들과 회식',
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

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
                  // 달력/목록 토글
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
                items: const ['전체', '수입', '지출', '청구예정'],
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
              child: _showCalendar
                  ? GlassCard(
                      child: MounCalendar(
                        data: _calendarData,
                        onDayTap: (day) {
                          final key = DateTime(day.year, day.month, day.day);
                          final txns = _txByDay[key] ?? [];
                          DayTransactionSheet.show(
                            context,
                            day: day,
                            transactions: txns,
                          );
                        },
                        onMonthChanged: (_) {
                          // TODO: 해당 월 거래 API 호출
                        },
                      ),
                    ).animate(delay: 150.ms).fadeIn()
                  : _TransactionListView(txByDay: _txByDay)
                      .animate(delay: 150.ms).fadeIn(),
            ),
          ),
        ],
      ),
    );
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
        child: Icon(icon, size: 18,
            color: active ? Colors.white : AppColors.textSecondary),
      ),
    );
  }
}

class _TransactionListView extends StatelessWidget {
  const _TransactionListView({required this.txByDay});
  final Map<DateTime, List<TransactionItem>> txByDay;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final sorted = txByDay.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Column(
      children: sorted.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                '${entry.key.month}월 ${entry.key.day}일',
                style: tt.labelMedium?.copyWith(color: AppColors.textSecondary),
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
                      if (!isLast) const Divider(height: 1, indent: 56, endIndent: 16),
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
  const _TransactionRow({required this.item});
  final TransactionItem item;

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
                Text(item.name, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                Text(item.category.label, style: tt.labelSmall),
              ],
            ),
          ),
          AmountDisplay(amount: item.amount, size: AmountSize.small),
        ],
      ),
    );
  }
}
