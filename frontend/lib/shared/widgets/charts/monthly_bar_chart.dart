import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class MonthlyBarData {
  const MonthlyBarData({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;  // ex) '1월'
  final int income;
  final int expense;
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
      (prev, e) => [prev, e.income, e.expense].reduce((a, b) => a > b ? a : b),
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
                      toY: d.income.toDouble(),
                      color: AppColors.income,
                      width: 10,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: d.expense.toDouble(),
                      color: AppColors.expense,
                      width: 10,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.textPrimary.withValues(alpha: 0.85),
                  getTooltipItem: (group, _, rod, rodIndex) {
                    final label = rodIndex == 0 ? '수입' : '지출';
                    final value = rod.toY.toInt();
                    return BarTooltipItem(
                      '$label\n',
                      tt.labelSmall!.copyWith(color: Colors.white),
                      children: [
                        TextSpan(
                          text: '${_fmt(value)}원',
                          style: tt.labelMedium?.copyWith(
                            color: rodIndex == 0 ? AppColors.income : AppColors.expense,
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
            const SizedBox(width: AppSpacing.lg),
            _Legend('지출', AppColors.expense),
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
