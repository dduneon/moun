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
import 'fixed_expense_screen.dart';
import 'fixed_income_screen.dart';
import '../providers/settings_provider.dart';

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
          // ── 헤더
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
              child: Text('설정', style: tt.headlineMedium)
                  .animate()
                  .fadeIn(duration: 300.ms),
            ),
          ),

          // ── 프로필 카드
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
                        user?.name.isNotEmpty == true ? user!.name[0] : '?',
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
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

          // ── 예산 기준일
          SliverToBoxAdapter(child: _SectionHeader('예산 설정')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: _SettingsTile(
                  icon: Icons.calendar_month_rounded,
                  iconColor: AppColors.primary,
                  label: '예산 기준일',
                  value: user != null ? '매월 ${user.salaryDay}일' : null,
                  onTap: () async {
                    final current = user?.salaryDay ?? 1;
                    final picked = await _pickSalaryDay(context, current);
                    if (picked != null && picked != current && context.mounted) {
                      await ref.read(authProvider.notifier).updateSalaryDay(picked);
                    }
                  },
                ),
              ).animate(delay: 150.ms).fadeIn(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

          // ── 고정 수입/지출
          SliverToBoxAdapter(child: _SectionHeader('정기 항목')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.trending_up_rounded,
                      iconColor: AppColors.income,
                      label: '고정 수입',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FixedIncomeScreen()),
                      ),
                    ),
                    const Divider(height: 1, indent: 52),
                    _SettingsTile(
                      icon: Icons.repeat_rounded,
                      iconColor: AppColors.expense,
                      label: '고정 지출',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FixedExpenseScreen()),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

          // ── 앱 설정
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
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.textSecondary,
                      label: '버전 정보',
                      value: 'v1.0.0',
                      onTap: () {},
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

          // ── 로그아웃
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
              ).animate(delay: 350.ms).fadeIn(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

}

// ── 공용 서브 위젯 ─────────────────────────────────────────────

String _cycleRangeLabel(int salaryDay) {
  final now = DateTime.now();
  if (salaryDay <= 1) {
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return '${now.month}월 1일 ~ ${now.month}월 ${lastDay}일';
  }
  if (now.day >= salaryDay) {
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    return '${now.month}월 ${salaryDay}일 ~ ${nextMonth}월 ${salaryDay - 1}일';
  } else {
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    return '${prevMonth}월 ${salaryDay}일 ~ ${now.month}월 ${salaryDay - 1}일';
  }
}

Future<int?> _pickSalaryDay(BuildContext context, int current) async {
  int selected = current;
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final rangeLabel = _cycleRangeLabel(selected);
        final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom +
            MediaQuery.of(ctx).padding.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
            AppSpacing.lg + bottomPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('예산 기준일',
                  style: Theme.of(ctx).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text('매월 몇 일부터 예산을 시작할까요?',
                  style: Theme.of(ctx)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  key: ValueKey(rangeLabel),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '이번 사이클: $rangeLabel',
                        style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: List.generate(28, (i) {
                  final day = i + 1;
                  final isSelected = day == selected;
                  return GestureDetector(
                    onTap: () => setState(() => selected = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.buttonBorderRadius),
                ),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg + 4, 0, AppSpacing.lg, AppSpacing.sm),
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
    this.labelColor,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
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
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
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
              Text(value!,
                  style: tt.bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: AppSpacing.xs),
            ],
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}



