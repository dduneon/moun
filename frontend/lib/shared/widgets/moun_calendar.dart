import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

// 날짜별 거래 요약 (외부에서 주입)
class DayData {
  const DayData({
    this.income = 0,
    this.expense = 0,
    this.hasPending = false,
  });

  final int income;
  final int expense;
  final bool hasPending; // 청구 예정 거래 있음

  bool get isEmpty => income == 0 && expense == 0;
}

class MounCalendar extends StatefulWidget {
  const MounCalendar({
    super.key,
    required this.data,           // { DateTime(y,m,d): DayData }
    this.onDayTap,
    this.onMonthChanged,
    this.initialMonth,
    this.selectedDay,
  });

  final Map<DateTime, DayData> data;
  final ValueChanged<DateTime>? onDayTap;
  final ValueChanged<DateTime>? onMonthChanged; // 월 이동 시 새 데이터 요청
  final DateTime? initialMonth;
  final DateTime? selectedDay;

  @override
  State<MounCalendar> createState() => _MounCalendarState();
}

class _MounCalendarState extends State<MounCalendar> {
  late DateTime _month;
  DateTime? _selected;

  static final _monthFmt = DateFormat('yyyy년 M월');

  @override
  void initState() {
    super.initState();
    final now = widget.initialMonth ?? DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = widget.selectedDay;
  }

  void _prevMonth() {
    setState(() => _month = DateTime(_month.year, _month.month - 1));
    widget.onMonthChanged?.call(_month);
  }

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1);
    if (next.isAfter(DateTime.now())) return; // 미래 월 막기
    setState(() => _month = next);
    widget.onMonthChanged?.call(_month);
  }

  DayData _dataFor(DateTime day) =>
      widget.data[DateTime(day.year, day.month, day.day)] ??
      const DayData();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final days = _buildDays();
    final isCurrentMonth = _month.year == DateTime.now().year &&
        _month.month == DateTime.now().month;

    return Column(
      children: [
        // ── 월 네비게이션 ─────────────────────────────────
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: _prevMonth,
              color: AppColors.textPrimary,
            ),
            Expanded(
              child: Center(
                child: Text(_monthFmt.format(_month), style: tt.titleLarge),
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded,
                  color: isCurrentMonth
                      ? AppColors.divider.withValues(alpha: 8.0)
                      : AppColors.textPrimary),
              onPressed: isCurrentMonth ? null : _nextMonth,
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // ── 요일 헤더 ─────────────────────────────────────
        Row(
          children: ['일', '월', '화', '수', '목', '금', '토'].map((d) {
            final isSun = d == '일';
            final isSat = d == '토';
            return Expanded(
              child: Center(
                child: Text(
                  d,
                  style: tt.labelSmall?.copyWith(
                    color: isSun
                        ? AppColors.expense
                        : isSat
                            ? AppColors.primary
                            : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: AppSpacing.sm),

        // ── 날짜 그리드 ───────────────────────────────────
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 68,
          ),
          itemCount: days.length,
          itemBuilder: (_, i) {
            final day = days[i];
            if (day == null) return const SizedBox.shrink();
            return _DayCell(
              day: day,
              data: _dataFor(day),
              isToday: _isToday(day),
              isSelected: _isSame(day, _selected),
              isCurrentMonth: day.month == _month.month,
              onTap: () {
                setState(() => _selected = day);
                widget.onDayTap?.call(day);
              },
            );
          },
        ),

      ],
    );
  }

  // 앞뒤 빈칸 포함한 날짜 목록
  List<DateTime?> _buildDays() {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final lastDay = DateTime(_month.year, _month.month + 1, 0);
    final startPad = firstDay.weekday % 7; // 일=0
    final result = <DateTime?>[];
    for (int i = 0; i < startPad; i++) result.add(null);
    for (int d = 1; d <= lastDay.day; d++) {
      result.add(DateTime(_month.year, _month.month, d));
    }
    // 7의 배수로 채우기
    while (result.length % 7 != 0) result.add(null);
    return result;
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isSame(DateTime a, DateTime? b) =>
      b != null && a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.data,
    required this.isToday,
    required this.isSelected,
    required this.isCurrentMonth,
    required this.onTap,
  });

  final DateTime day;
  final DayData data;
  final bool isToday;
  final bool isSelected;
  final bool isCurrentMonth;
  final VoidCallback onTap;

  static final _amtFmt = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isSunday = day.weekday == 7;

    Color dayColor = isCurrentMonth
        ? (isSunday
            ? AppColors.expense
            : isSat(day)
                ? AppColors.primary
                : AppColors.textPrimary)
        : AppColors.textSecondary.withValues(alpha: 0.4);

    if (isSelected) dayColor = Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : isToday
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: isToday && !isSelected
                ? Border.all(color: AppColors.primary, width: 1)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: tt.bodyMedium?.copyWith(
                  color: dayColor,
                  fontWeight:
                      isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              if (data.income > 0)
                Text(
                  '+${_fmt(data.income)}',
                  style: tt.labelSmall?.copyWith(
                    color: isSelected ? Colors.white70 : AppColors.income,
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              if (data.expense > 0)
                Text(
                  '-${_fmt(data.expense)}',
                  style: tt.labelSmall?.copyWith(
                    color: isSelected ? Colors.white70 : AppColors.expense,
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              if (data.hasPending && data.expense == 0)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.expensePending,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool isSat(DateTime d) => d.weekday == 6;

  String _fmt(int v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(0)}천만';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}만';
    return _amtFmt.format(v);
  }
}

