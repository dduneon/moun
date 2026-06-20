import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../features/auth/domain/auth_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthStateAuthenticated ? authState.user : null;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── 헤더 ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
              ),
              child: Text('설정', style: tt.headlineMedium)
                  .animate().fadeIn(duration: 300.ms),
            ),
          ),

          // ── 프로필 카드 ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0]
                            : '?',
                        style: tt.headlineMedium?.copyWith(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? '—', style: tt.titleLarge),
                          Text(user?.email ?? '—', style: tt.bodySmall),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary),
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

          // ── 예산 설정 ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader('예산 설정'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.calendar_today_rounded,
                      iconColor: AppColors.primary,
                      label: '월급날',
                      value: '매월 21일',
                      onTap: () => _showSalaryDaySheet(context),
                    ),
                    const Divider(height: 1, indent: 52),
                    _SettingsTile(
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: AppColors.income,
                      label: '월 예산',
                      value: '3,000,000원',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 52),
                    _SettingsTile(
                      icon: Icons.weekend_rounded,
                      iconColor: AppColors.expensePending,
                      label: '주말 지급 방식',
                      value: '이전 평일',
                      onTap: () {},
                    ),
                  ],
                ),
              ).animate(delay: 150.ms).fadeIn(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

          // ── 카드 / 계좌 ────────────────────────────────────
          SliverToBoxAdapter(child: _SectionHeader('카드 / 계좌')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.credit_card_rounded,
                      iconColor: AppColors.primary,
                      label: '카드 관리',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 52),
                    _SettingsTile(
                      icon: Icons.category_rounded,
                      iconColor: const Color(0xFF7C6FF0),
                      label: '카테고리 관리',
                      onTap: () {},
                    ),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

          // ── 앱 설정 ────────────────────────────────────────
          SliverToBoxAdapter(child: _SectionHeader('앱')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.notifications_rounded,
                      iconColor: const Color(0xFFFF9F43),
                      label: '알림 설정',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 52),
                    _SettingsTile(
                      icon: Icons.dark_mode_rounded,
                      iconColor: AppColors.textSecondary,
                      label: '다크 모드',
                      trailing: Switch(
                        value: false,
                        onChanged: (_) {},
                        activeColor: AppColors.primary,
                      ),
                      onTap: null,
                    ),
                    const Divider(height: 1, indent: 52),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.textSecondary,
                      label: '버전 정보',
                      value: 'v1.0.0',
                      onTap: () {},
                    ),
                  ],
                ),
              ).animate(delay: 250.ms).fadeIn(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

          // ── 로그아웃 ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: _SettingsTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.expense,
                  label: '로그아웃',
                  labelColor: AppColors.expense,
                  onTap: () async {
                    final ok = await AppConfirmDialog.show(
                      context,
                      title: '로그아웃',
                      message: '로그아웃 하시겠어요?',
                      confirmLabel: '로그아웃',
                    );
                    if (ok && context.mounted) {
                      ref.read(authProvider.notifier).logout();
                    }
                  },
                ),
              ).animate(delay: 300.ms).fadeIn(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  void _showSalaryDaySheet(BuildContext context) {
    AppBottomSheet.show(
      context,
      title: '월급날 설정',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(28, (i) => i + 1)
            .map((day) => ListTile(
                  title: Text('매월 $day일'),
                  trailing: day == 21
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context),
                ))
            .toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg + 4, 0, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.value,
    this.trailing,
    this.labelColor,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final Widget? trailing;
  final Color? labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardBorderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: tt.bodyMedium?.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value != null) ...[
              Text(value!, style: tt.bodySmall?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: AppSpacing.xs),
            ],
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
