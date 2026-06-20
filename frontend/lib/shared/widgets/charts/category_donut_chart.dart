import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class CategoryData {
  const CategoryData({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;
}

class CategoryDonutChart extends StatefulWidget {
  const CategoryDonutChart({
    super.key,
    required this.items,
    this.centerLabel = '지출 합계',
  });

  final List<CategoryData> items;
  final String centerLabel;

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int _touched = -1;
  static final _fmt = NumberFormat('#,###');

  int get _total => widget.items.fold(0, (sum, e) => sum + e.amount);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 56,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response?.touchedSection == null) {
                          _touched = -1;
                          return;
                        }
                        _touched =
                            response!.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: List.generate(widget.items.length, (i) {
                    final item = widget.items[i];
                    final isTouched = i == _touched;
                    final pct = _total > 0 ? item.amount / _total * 100 : 0.0;
                    return PieChartSectionData(
                      value: item.amount.toDouble(),
                      color: item.color,
                      radius: isTouched ? 48 : 38,
                      showTitle: false, // 바깥 배지로 대체
                      badgeWidget: isTouched
                          ? _PctBadge(
                              pct: pct,
                              color: item.color,
                              label: item.label,
                            )
                          : null,
                      badgePositionPercentageOffset: 1.3,
                    );
                  }),
                ),
              ),
              // 가운데: 터치된 항목 또는 전체 합계
              _CenterContent(
                label: _touched >= 0
                    ? widget.items[_touched].label
                    : widget.centerLabel,
                amount: _touched >= 0
                    ? widget.items[_touched].amount
                    : _total,
                color: _touched >= 0
                    ? widget.items[_touched].color
                    : AppColors.textPrimary,
                pct: _touched >= 0 && _total > 0
                    ? widget.items[_touched].amount / _total * 100
                    : null,
                tt: tt,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // 범례 — 카드 형태로 금액 + 비율 표시
        ...widget.items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final pct = _total > 0 ? item.amount / _total * 100 : 0.0;
          final isSelected = _touched == i;

          return GestureDetector(
            onTap: () => setState(() => _touched = isSelected ? -1 : i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? item.color.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? item.color.withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(item.label, style: tt.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  )),
                  const Spacer(),
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: tt.labelSmall?.copyWith(
                      color: item.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${_fmt.format(item.amount)}원',
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _CenterContent extends StatelessWidget {
  const _CenterContent({
    required this.label,
    required this.amount,
    required this.color,
    required this.tt,
    this.pct,
  });

  final String label;
  final int amount;
  final Color color;
  final TextTheme tt;
  final double? pct;

  static final _fmt = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: tt.labelSmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          '${_fmt.format(amount)}원',
          style: tt.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
        if (pct != null)
          Text(
            '${pct!.toStringAsFixed(1)}%',
            style: tt.labelSmall?.copyWith(color: color),
          ),
      ],
    );
  }
}

class _PctBadge extends StatelessWidget {
  const _PctBadge({
    required this.pct,
    required this.color,
    required this.label,
  });

  final double pct;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${pct.toStringAsFixed(0)}%',
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
