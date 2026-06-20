import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/amount_display.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/selection_chip.dart';
import '../../../../shared/widgets/charts/category_donut_chart.dart';
import '../../../../shared/widgets/charts/monthly_bar_chart.dart';
import '../../../../shared/widgets/charts/spending_line_chart.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../budget/domain/budget_models.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  Set<String> _period = {'이번 달'};

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final budgetAsync = ref.watch(availableBudgetProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── 헤더 ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('통계', style: tt.headlineMedium)
                      .animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: AppSpacing.md),
                  SelectionChipGroup<String>(
                    items: const ['이번 달', '3개월', '6개월', '1년'],
                    labelOf: (s) => s,
                    selected: _period,
                    onSelected: (v) => setState(() => _period = v),
                  ),
                ],
              ),
            ),
          ),

          // ── 요약 카드 ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: budgetAsync.when(
                data: (b) => Row(
                  children: [
                    Expanded(child: _SummaryCard(
                      label: '총 수입',
                      amount: (b.salary + b.extraIncome).round(),
                      color: AppColors.income,
                      icon: Icons.arrow_circle_up_rounded,
                    )),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _SummaryCard(
                      label: '총 지출',
                      amount: -b.totalSpent.round(),
                      color: AppColors.expense,
                      icon: Icons.arrow_circle_down_rounded,
                    )),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _SummaryCard(
                      label: '순수익',
                      amount: (b.salary + b.extraIncome - b.totalSpent).round(),
                      color: AppColors.primary,
                      icon: Icons.savings_rounded,
                    )),
                  ],
                ),
                loading: () => const SizedBox(height: 80),
                error: (_, __) => const SizedBox.shrink(),
              ).animate(delay: 100.ms).fadeIn(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // ── 카테고리 도넛 ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('카테고리별 지출', style: tt.titleLarge),
                    const SizedBox(height: AppSpacing.lg),
                    budgetAsync.when(
                      data: (b) => CategoryDonutChart(
                        centerLabel: '이번 달 지출',
                        items: _buildDonutItems(b.spendSummary),
                      ),
                      loading: () => const SizedBox(height: 200),
                      error: (_, __) => Center(
                        child: Text('데이터 없음',
                            style: tt.bodySmall?.copyWith(
                                color: AppColors.textSecondary)),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // ── 월별 수입/지출 (mock - 과거 데이터 API 없음) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('월별 수입 / 지출', style: tt.titleLarge),
                    const SizedBox(height: AppSpacing.lg),
                    const MonthlyBarChart(
                      data: [
                        MonthlyBarData(label: '1월', income: 4200000, expense: 1800000),
                        MonthlyBarData(label: '2월', income: 4200000, expense: 2100000),
                        MonthlyBarData(label: '3월', income: 4500000, expense: 1650000),
                        MonthlyBarData(label: '4월', income: 4200000, expense: 2300000),
                        MonthlyBarData(label: '5월', income: 4200000, expense: 1950000),
                        MonthlyBarData(label: '6월', income: 4350000, expense: 1250000),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // ── 일별 누적 지출 추이 ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    budgetAsync.when(
                      data: (b) => Row(children: [
                        Text('지출 추이', style: tt.titleLarge),
                        const Spacer(),
                        Text('예산 ${_fmtWon((b.salary + b.extraIncome).round())}',
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            )),
                      ]),
                      loading: () => Text('지출 추이', style: tt.titleLarge),
                      error: (_, __) => Text('지출 추이', style: tt.titleLarge),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    budgetAsync.when(
                      data: (b) => SpendingLineChart(
                        budgetLimit: (b.salary + b.extraIncome).round(),
                        points: _buildSpendingPoints(b.spendSummary),
                      ),
                      loading: () => const SizedBox(height: 160),
                      error: (_, __) => const SizedBox(height: 160),
                    ),
                  ],
                ),
              ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  static const _donutColors = [
    Color(0xFF5B8DEF),
    Color(0xFF7C6FF0),
    Color(0xFFFF6B6B),
    Color(0xFF34C77B),
    Color(0xFFB39DFF),
    Color(0xFFFF9F43),
    Color(0xFF54A0FF),
    Color(0xFF8D6E63),
  ];

  List<CategoryData> _buildDonutItems(SpendSummary summary) {
    final expenseItems = summary.byCategory
        .where((c) => c.total < 0)
        .toList()
      ..sort((a, b) => a.total.compareTo(b.total));

    return expenseItems.asMap().entries.map((e) {
      final color = _donutColors[e.key % _donutColors.length];
      return CategoryData(
        label: e.value.categoryName,
        amount: e.value.total.abs().round(),
        color: color,
      );
    }).toList();
  }

  List<SpendingPoint> _buildSpendingPoints(SpendSummary summary) {
    // 현재는 사이클 합계만 있으므로 단순 표시
    final total = summary.totalSpend.abs();
    if (total == 0) return const [];
    return [SpendingPoint(day: 20, amount: total.round())];
  }

  String _fmtWon(int amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(0)}만원';
    }
    return '$amount원';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });
  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AmountDisplay(amount: amount, size: AmountSize.small),
          ),
        ],
      ),
    );
  }
}
