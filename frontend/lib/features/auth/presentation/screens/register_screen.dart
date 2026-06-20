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
import '../widgets/auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _passwordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    try {
      await ref.read(authProvider.notifier).register(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            name: _nameCtrl.text.trim(),
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
            child: AuthBlurCircle(
              size: 260,
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: size.height * 0.3,
            left: -80,
            child: AuthBlurCircle(
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
                  constraints: BoxConstraints(
                      minHeight:
                          size.height - MediaQuery.paddingOf(context).top),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: size.height * 0.08),

                        // ── 헤더
                        Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryGradientEnd,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_add_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ).animate().scale(
                                  duration: 500.ms,
                                  curve: Curves.easeOutBack,
                                ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              '회원가입',
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
                              '모운과 함께 스마트하게 시작하세요',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ).animate(delay: 150.ms).fadeIn(),
                          ],
                        ),

                        SizedBox(height: size.height * 0.05),

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
                                    color: AppColors.primary
                                        .withValues(alpha: 0.06),
                                    blurRadius: 32,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AuthInputField(
                                      controller: _nameCtrl,
                                      focusNode: _nameFocus,
                                      label: '이름',
                                      hint: '홍길동',
                                      icon: Icons.person_outline_rounded,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) =>
                                          _emailFocus.requestFocus(),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? '이름을 입력해주세요'
                                              : null,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    AuthInputField(
                                      controller: _emailCtrl,
                                      focusNode: _emailFocus,
                                      label: '이메일',
                                      hint: 'example@email.com',
                                      icon: Icons.mail_outline_rounded,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) =>
                                          _passwordFocus.requestFocus(),
                                      validator: (v) =>
                                          (v == null || !v.contains('@'))
                                              ? '올바른 이메일을 입력해주세요'
                                              : null,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    AuthInputField(
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
                                        onPressed: () => setState(() =>
                                            _passwordVisible =
                                                !_passwordVisible),
                                      ),
                                    ),

                                    // ── 에러
                                    AnimatedSize(
                                      duration: 200.ms,
                                      child: _errorMessage != null
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  top: AppSpacing.md),
                                              child: AuthErrorBanner(
                                                  message: _errorMessage!),
                                            )
                                          : const SizedBox.shrink(),
                                    ),

                                    const SizedBox(height: AppSpacing.xl),

                                    AuthGradientButton(
                                      onPressed:
                                          isAuthenticating ? null : _submit,
                                      loading: isAuthenticating,
                                      label: '가입하기',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

                        const SizedBox(height: AppSpacing.xl),

                        // ── 로그인으로 이동
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '이미 계정이 있으신가요?',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                '로그인',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
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
