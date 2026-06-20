import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/amount_display.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/selection_chip.dart';
import '../../../../shared/widgets/charts/category_donut_chart.dart';
import '../../../../shared/widgets/charts/monthly_bar_chart.dart';
import '../../../../shared/widgets/charts/spending_line_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Set<String> _period = {'이번 달'};

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
              child: Row(
                children: [
                  Expanded(child: _SummaryCard(
                    label: '총 수입',
                    amount: 4350000,
                    color: AppColors.income,
                    icon: Icons.arrow_circle_up_rounded,
                  )),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _SummaryCard(
                    label: '총 지출',
                    amount: -1250000,
                    color: AppColors.expense,
                    icon: Icons.arrow_circle_down_rounded,
                  )),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _SummaryCard(
                    label: '순수익',
                    amount: 3100000,
                    color: AppColors.primary,
                    icon: Icons.savings_rounded,
                  )),
                ],
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
                    const CategoryDonutChart(
                      centerLabel: '이번 달 지출',
                      items: [
                        CategoryData(label: '식비', amount: 420000, color: Color(0xFF5B8DEF)),
                        CategoryData(label: '교통', amount: 85000, color: Color(0xFF7C6FF0)),
                        CategoryData(label: '쇼핑', amount: 230000, color: Color(0xFFFF6B6B)),
                        CategoryData(label: '문화', amount: 120000, color: Color(0xFF34C77B)),
                        CategoryData(label: '기타', amount: 65000, color: Color(0xFFB39DFF)),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // ── 월별 수입/지출 ─────────────────────────────────
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

          // ── 일별 지출 추이 ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('지출 추이', style: tt.titleLarge),
                      const Spacer(),
                      Text('예산 300만원', style: tt.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      )),
                    ]),
                    const SizedBox(height: AppSpacing.lg),
                    const SpendingLineChart(
                      budgetLimit: 3000000,
                      points: [
                        SpendingPoint(day: 1, amount: 65000),
                        SpendingPoint(day: 3, amount: 142000),
                        SpendingPoint(day: 5, amount: 280000),
                        SpendingPoint(day: 8, amount: 395000),
                        SpendingPoint(day: 10, amount: 520000),
                        SpendingPoint(day: 13, amount: 710000),
                        SpendingPoint(day: 15, amount: 880000),
                        SpendingPoint(day: 18, amount: 1050000),
                        SpendingPoint(day: 20, amount: 1250000),
                      ],
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
