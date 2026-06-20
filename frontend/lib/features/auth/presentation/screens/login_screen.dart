import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/auth_model.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _passwordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    try {
      await ref.read(authProvider.notifier).login(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticating = ref.watch(authProvider) is AuthStateAuthenticating;
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── 배경 그라디언트
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEFF4FF),
                  Color(0xFFF5F0FF),
                  Color(0xFFFFFFFF),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── 장식 원형 블러
          Positioned(
            top: -80,
            right: -60,
            child: _BlurCircle(
              size: 260,
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: size.height * 0.3,
            left: -80,
            child: _BlurCircle(
              size: 200,
              color: AppColors.primaryGradientEnd.withValues(alpha: 0.12),
            ),
          ),

          // ── 본문
          SafeArea(
            child: AnimatedPadding(
              duration: 300.ms,
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height - MediaQuery.paddingOf(context).top),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: size.height * 0.12),

                        // ── 로고 + 타이틀
                        Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [AppColors.primary, AppColors.primaryGradientEnd],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ).animate().scale(
                                  duration: 500.ms,
                                  curve: Curves.easeOutBack,
                                ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              '모운',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.0,
                                  ),
                              textAlign: TextAlign.center,
                            ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '나의 예산을 스마트하게',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ).animate(delay: 150.ms).fadeIn(),
                          ],
                        ),

                        SizedBox(height: size.height * 0.07),

                        // ── 폼 카드
                        ClipRRect(
                          borderRadius: AppRadius.cardBorderRadius,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.75),
                                borderRadius: AppRadius.cardBorderRadius,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.06),
                                    blurRadius: 32,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _InputField(
                                      controller: _emailCtrl,
                                      focusNode: _emailFocus,
                                      label: '이메일',
                                      hint: 'example@email.com',
                                      icon: Icons.mail_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                                      validator: (v) =>
                                          (v == null || !v.contains('@'))
                                              ? '올바른 이메일을 입력해주세요'
                                              : null,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    _InputField(
                                      controller: _passwordCtrl,
                                      focusNode: _passwordFocus,
                                      label: '비밀번호',
                                      hint: '6자 이상',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: !_passwordVisible,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _submit(),
                                      validator: (v) =>
                                          (v == null || v.length < 6)
                                              ? '비밀번호는 6자 이상이어야 합니다'
                                              : null,
                                      suffix: IconButton(
                                        icon: Icon(
                                          _passwordVisible
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          size: 18,
                                          color: AppColors.textSecondary,
                                        ),
                                        onPressed: () => setState(
                                            () => _passwordVisible = !_passwordVisible),
                                      ),
                                    ),

                                    // ── 에러
                                    AnimatedSize(
                                      duration: 200.ms,
                                      child: _errorMessage != null
                                          ? Padding(
                                              padding: const EdgeInsets.only(top: AppSpacing.md),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: AppSpacing.md,
                                                  vertical: AppSpacing.sm,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.expense.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.error_outline_rounded,
                                                        size: 15, color: AppColors.expense),
                                                    const SizedBox(width: AppSpacing.xs),
                                                    Expanded(
                                                      child: Text(
                                                        _errorMessage!,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(color: AppColors.expense),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),

                                    const SizedBox(height: AppSpacing.xl),

                                    // ── 로그인 버튼
                                    _GradientButton(
                                      onPressed: isAuthenticating ? null : _submit,
                                      loading: isAuthenticating,
                                      label: '로그인',
                                    ),

                                    const SizedBox(height: AppSpacing.md),

                                    // ── 구분선
                                    Row(
                                      children: [
                                        const Expanded(child: Divider()),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                          child: Text(
                                            '또는',
                                            style: Theme.of(context).textTheme.labelMedium,
                                          ),
                                        ),
                                        const Expanded(child: Divider()),
                                      ],
                                    ),

                                    const SizedBox(height: AppSpacing.md),

                                    // ── 카카오 로그인 버튼
                                    _KakaoButton(onPressed: isAuthenticating ? null : () {}),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

                        const SizedBox(height: AppSpacing.xl),

                        // ── 회원가입
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '아직 계정이 없으신가요?',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            TextButton(
                              onPressed: () => context.go('/register'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                '회원가입',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ).animate(delay: 300.ms).fadeIn(),

                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 서브 위젯 ─────────────────────────────────────────────────────

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
    this.suffix,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5)),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
        prefixIconConstraints: const BoxConstraints(),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.backgroundStart.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.expense),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
        ),
        errorStyle: const TextStyle(height: 0),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
      ),
    );
  }
}

class _KakaoButton extends StatelessWidget {
  const _KakaoButton({this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500),
          foregroundColor: const Color(0xFF191919),
          shadowColor: const Color(0xFFFEE500).withValues(alpha: 0.4),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 카카오 말풍선 아이콘
            SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(painter: _KakaoIconPainter()),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '카카오로 시작하기',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF191919),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KakaoIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF191919);
    // 말풍선 타원
    canvas.drawOval(Rect.fromLTWH(0, 0, size.width, size.height * 0.85), paint);
    // 말풍선 꼬리
    final path = Path()
      ..moveTo(size.width * 0.35, size.height * 0.78)
      ..lineTo(size.width * 0.28, size.height)
      ..lineTo(size.width * 0.52, size.height * 0.82)
      ..close();
    canvas.drawPath(path, paint);
    // 눈 3개 (카카오 특징)
    final eyePaint = Paint()..color = const Color(0xFFFEE500);
    final r = size.width * 0.07;
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.38), r, eyePaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.38), r, eyePaint);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.38), r, eyePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? null
              : const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryGradientEnd],
                ),
          color: onPressed == null ? AppColors.textSecondary.withValues(alpha: 0.2) : null,
          borderRadius: AppRadius.buttonBorderRadius,
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
          ),
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
        ),
      ),
    );
  }
}
