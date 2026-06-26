import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class MonthlyBarData {
  const MonthlyBarData({
    required this.label,
    required this.income,
    required this.expense,
    this.pendingIncome = 0,
    this.fixedExpense = 0,
  });

  final String label;  // ex) '1월'
  final int income;       // confirmedIncome
  final int pendingIncome; // expectedIncome - confirmedIncome (아직 안 받은 고정수입)
  final int expense;
  final int fixedExpense;
}

class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    super.key,
    required this.data,
  });

  final List<MonthlyBarData> data;

  double get _maxY {
    final m = data.fold<int>(
      0,
      (prev, e) => [prev, e.income + e.pendingIncome, e.expense + e.fixedExpense].reduce((a, b) => a > b ? a : b),
    );
    final raw = (m * 1.25).ceilToDouble();
    return raw > 0 ? raw : 10000;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: _maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _maxY / 4,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.divider,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= data.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(data[i].label, style: tt.labelSmall),
                      );
                    },
                    reservedSize: 24,
                  ),
                ),
              ),
              barGroups: List.generate(data.length, (i) {
                final d = data[i];
                return BarChartGroupData(
                  x: i,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: (d.income + d.pendingIncome).toDouble(),
                      width: 10,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      rodStackItems: d.pendingIncome > 0
                          ? [
                              BarChartRodStackItem(0, d.income.toDouble(), AppColors.income),
                              BarChartRodStackItem(d.income.toDouble(), (d.income + d.pendingIncome).toDouble(), AppColors.income.withValues(alpha: 0.35)),
                            ]
                          : [
                              BarChartRodStackItem(0, d.income.toDouble(), AppColors.income),
                            ],
                      color: Colors.transparent,
                    ),
                    BarChartRodData(
                      toY: (d.expense + d.fixedExpense).toDouble(),
                      width: 10,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      rodStackItems: [
                        BarChartRodStackItem(0, d.expense.toDouble(), AppColors.expense),
                        BarChartRodStackItem(d.expense.toDouble(), (d.expense + d.fixedExpense).toDouble(), AppColors.expensePending),
                      ],
                      color: Colors.transparent,
                    ),
                  ],
                );
              }),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.textPrimary.withValues(alpha: 0.85),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final d = data[groupIndex];
                    if (rodIndex == 0) {
                      final label = d.pendingIncome > 0
                          ? '수입 ${_fmt(d.income)}원  예정 ${_fmt(d.pendingIncome)}원\n'
                          : '수입\n';
                      return BarTooltipItem(
                        label,
                        tt.labelSmall!.copyWith(color: Colors.white),
                        children: [
                          TextSpan(
                            text: '합계 ${_fmt(d.income + d.pendingIncome)}원',
                            style: tt.labelMedium?.copyWith(
                              color: AppColors.income,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    }
                    return BarTooltipItem(
                      '변동 ${_fmt(d.expense)}원  고정 ${_fmt(d.fixedExpense)}원\n',
                      tt.labelSmall!.copyWith(color: Colors.white),
                      children: [
                        TextSpan(
                          text: '합계 ${_fmt(d.expense + d.fixedExpense)}원',
                          style: tt.labelMedium?.copyWith(
                            color: AppColors.expense,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend('수입', AppColors.income),
            const SizedBox(width: AppSpacing.md),
            _Legend('예정수입', AppColors.income.withValues(alpha: 0.35)),
            const SizedBox(width: AppSpacing.md),
            _Legend('지출', AppColors.expense),
            const SizedBox(width: AppSpacing.md),
            _Legend('고정지출', AppColors.expensePending),
          ],
        ),
      ],
    );
  }

  String _fmt(int v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}천만';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}만';
    return '$v';
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
