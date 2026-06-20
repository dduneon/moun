import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefix,
    this.suffix,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final Widget? prefix;
  final Widget? suffix;
  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final FocusNode? focusNode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      style: tt.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        hintStyle: tt.bodyLarge?.copyWith(color: AppColors.textSecondary),
        labelStyle: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: tt.labelMedium?.copyWith(color: AppColors.primary),
        prefixIcon: widget.prefix,
        suffixText: widget.suffixText,
        suffixStyle: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
        suffix: widget.obscureText
            ? GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(
                  _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              )
            : widget.suffix,
        filled: true,
        fillColor: AppColors.surfaceGlass,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.expense),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),
    );
  }
}

// 금액 전용 입력창 — 숫자만, 천단위 콤마 자동
class AmountTextField extends StatefulWidget {
  const AmountTextField({
    super.key,
    this.controller,
    this.label = '금액',
    this.onChanged,
  });

  final TextEditingController? controller;
  final String label;
  final ValueChanged<int>? onChanged;

  @override
  State<AmountTextField> createState() => _AmountTextFieldState();
}

class _AmountTextFieldState extends State<AmountTextField> {
  late final TextEditingController _ctrl;
  bool _owned = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ctrl = TextEditingController();
      _owned = true;
    } else {
      _ctrl = widget.controller!;
    }
  }

  @override
  void dispose() {
    if (_owned) _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final value = int.tryParse(digits) ?? 0;
    final formatted = value == 0 ? '' : _formatComma(value);
    if (_ctrl.text != formatted) {
      _ctrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    widget.onChanged?.call(value);
  }

  String _formatComma(int v) =>
      v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _ctrl,
      label: widget.label,
      hint: '0',
      suffixText: '원',
      keyboardType: TextInputType.number,
      onChanged: _onChanged,
    );
  }
}
