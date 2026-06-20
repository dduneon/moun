import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum AmountSize { large, medium, small }

class AmountDisplay extends StatefulWidget {
  const AmountDisplay({
    super.key,
    required this.amount,
    this.size = AmountSize.medium,
    this.animate = false,
    this.style,
  });

  final int amount;
  final AmountSize size;
  final bool animate;
  final TextStyle? style;

  @override
  State<AmountDisplay> createState() => _AmountDisplayState();
}

class _AmountDisplayState extends State<AmountDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  static final _fmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (widget.animate) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle get _baseStyle {
    if (widget.style != null) return widget.style!;
    return switch (widget.size) {
      AmountSize.large => AppTypography.amountLarge,
      AmountSize.medium => AppTypography.amountMedium,
      AmountSize.small => AppTypography.amountSmall,
    };
  }

  Color get _color {
    if (widget.amount > 0) return AppColors.income;
    if (widget.amount < 0) return AppColors.expense;
    return AppColors.textPrimary;
  }

  // 절댓값만 표시, 단위 '원' 후치
  String _format(int value) => '${_fmt.format(value.abs())}원';

  @override
  Widget build(BuildContext context) {
    final style = _baseStyle.copyWith(color: _color);

    if (!widget.animate) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(_format(widget.amount), style: style, maxLines: 1),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        final current = (widget.amount * _animation.value).round();
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(_format(current), style: style, maxLines: 1),
        );
      },
    );
  }
}

// 라벨 + 금액 조합 위젯
// amount 부호는 색상(수입=green, 지출=red)으로만 표현, 숫자는 절댓값
class LabeledAmount extends StatelessWidget {
  const LabeledAmount({
    super.key,
    required this.label,
    required this.amount,
    this.size = AmountSize.small,
    this.animate = false,
  });

  final String label;
  final int amount;
  final AmountSize size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        AmountDisplay(amount: amount, size: size, animate: animate),
      ],
    );
  }
}
