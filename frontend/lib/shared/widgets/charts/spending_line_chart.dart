import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class SpendingPoint {
  const SpendingPoint({required this.day, required this.amount});
  final int day;    // 1~31
  final int amount; // 누적 또는 일별 지출
}

class SpendingLineChart extends StatelessWidget {
  const SpendingLineChart({
    super.key,
    required this.points,
    this.budgetLimit,
    this.showArea = true,
  });

  final List<SpendingPoint> points;
  final int? budgetLimit; // 예산 한도선 (선택)
  final bool showArea;

  double get _maxY {
    final dataMax = points.fold<int>(
      0,
      (prev, e) => e.amount > prev ? e.amount : prev,
    );
    final cap = budgetLimit != null && budgetLimit! > dataMax
        ? budgetLimit!
        : dataMax;
    return (cap * 1.2).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final spots = points
        .map((p) => FlSpot(p.day.toDouble(), p.amount.toDouble()))
        .toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: _maxY,
          clipData: const FlClipData.all(),
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
                interval: 7,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}일',
                  style: tt.labelSmall,
                ),
                reservedSize: 24,
              ),
            ),
          ),
          extraLinesData: budgetLimit != null
              ? ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: budgetLimit!.toDouble(),
                      color: AppColors.expense.withValues(alpha: 0.5),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 4, bottom: 2),
                        style: tt.labelSmall?.copyWith(color: AppColors.expense),
                        labelResolver: (_) => '예산',
                      ),
                    ),
                  ],
                )
              : null,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.textPrimary.withValues(alpha: 0.85),
              getTooltipItems: (spots) => spots.map((s) {
                return LineTooltipItem(
                  '${s.x.toInt()}일\n',
                  tt.labelSmall!.copyWith(color: Colors.white54),
                  children: [
                    TextSpan(
                      text: '${_fmt(s.y.toInt())}원',
                      style: tt.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) =>
                    spot == spots.first || spot == spots.last,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.primary,
                ),
              ),
              belowBarData: showArea
                  ? BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.18),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    )
                  : BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}천만';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}만';
    return '$v';
  }
}

// 여러 항목 비교용 멀티라인 (예: 이번달 vs 지난달)
class MultiLineData {
  const MultiLineData({
    required this.label,
    required this.color,
    required this.points,
  });
  final String label;
  final Color color;
  final List<SpendingPoint> points;
}

class CompareLineChart extends StatelessWidget {
  const CompareLineChart({super.key, required this.series});
  final List<MultiLineData> series;

  double get _maxY {
    double m = 0;
    for (final s in series) {
      for (final p in s.points) {
        if (p.amount > m) m = p.amount.toDouble();
      }
    }
    return m * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: _maxY,
              clipData: const FlClipData.all(),
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
                    interval: 7,
                    getTitlesWidget: (value, _) => Text('${value.toInt()}일', style: tt.labelSmall),
                    reservedSize: 24,
                  ),
                ),
              ),
              lineBarsData: series.map((s) {
                final spots = s.points
                    .map((p) => FlSpot(p.day.toDouble(), p.amount.toDouble()))
                    .toList();
                return LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: s.color,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: series.map((s) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16, height: 2,
                  decoration: BoxDecoration(
                    color: s.color,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 4),
                Text(s.label, style: tt.labelSmall),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }
}
