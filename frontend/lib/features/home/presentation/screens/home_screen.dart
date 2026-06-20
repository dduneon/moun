import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/domain/auth_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/amount_display.dart';
import '../../../../shared/widgets/glass_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthStateAuthenticated ? authState.user : null;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── 상단 인사 + 알림 ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user != null ? '안녕하세요, ${user.name}님 👋' : '모운',
                        style: tt.headlineMedium,
                      ),
                      Text('6월 예산 현황', style: tt.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      )),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    color: AppColors.textPrimary,
                    onPressed: () {},
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // ── 메인 예산 카드 ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('사용 가능 예산', style: tt.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                        )),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '6/1 ~ 6/30',
                            style: tt.labelSmall?.copyWith(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AmountDisplay(
                      amount: 1750000,
                      size: AmountSize.large,
                      animate: true,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 예산 진행 바
                    _BudgetProgressBar(spent: 1250000, total: 3000000),

                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: LabeledAmount(
                            label: '총 예산',
                            amount: 3000000,
                            size: AmountSize.small,
                          ),
                        ),
                        Expanded(
                          child: LabeledAmount(
                            label: '지출',
                            amount: -1250000,
                            size: AmountSize.small,
                          ),
                        ),
                        Expanded(
                          child: LabeledAmount(
                            label: '잔여',
                            amount: 1750000,
                            size: AmountSize.small,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // ── 수입 / 고정지출 카드 ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.arrow_circle_up_rounded,
                                color: AppColors.income, size: 18),
                            const SizedBox(width: 4),
                            Text('수입', style: tt.labelSmall),
                          ]),
                          const SizedBox(height: AppSpacing.xs),
                          AmountDisplay(amount: 4200000, size: AmountSize.small),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.repeat_rounded,
                                color: AppColors.expensePending, size: 18),
                            const SizedBox(width: 4),
                            Text('고정지출', style: tt.labelSmall),
                          ]),
                          const SizedBox(height: AppSpacing.xs),
                          AmountDisplay(amount: -680000, size: AmountSize.small),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

          // ── 최근 거래 헤더 ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text('최근 거래', style: tt.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: Text('전체보기',
                        style: tt.labelMedium?.copyWith(color: AppColors.primary)),
                  ),
                ],
              ).animate(delay: 250.ms).fadeIn(),
            ),
          ),

          // ── 최근 거래 목록 ──────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl,
            ),
            sliver: SliverList.separated(
              itemCount: _recentTransactions.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) => _RecentTransactionTile(
                item: _recentTransactions[i],
              ).animate(delay: (300 + i * 60).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 서브 위젯 ─────────────────────────────────────────────────

class _BudgetProgressBar extends StatelessWidget {
  const _BudgetProgressBar({required this.spent, required this.total});
  final int spent;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = (spent / total).clamp(0.0, 1.0);
    final color = ratio > 0.85
        ? AppColors.expense
        : ratio > 0.65
            ? const Color(0xFFFFAA00)
            : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: AppColors.divider.withValues(alpha: 4.0),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(ratio * 100).toStringAsFixed(0)}% 사용',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _RecentTx {
  const _RecentTx({
    required this.name,
    required this.category,
    required this.amount,
    required this.date,
    required this.icon,
    required this.iconColor,
  });
  final String name, category, date;
  final int amount;
  final IconData icon;
  final Color iconColor;
}

const _recentTransactions = [
  _RecentTx(name: '스타벅스 강남점', category: '카페', amount: -6500,
      date: '오늘 09:32', icon: Icons.local_cafe_rounded, iconColor: Color(0xFF8D6E63)),
  _RecentTx(name: '대중교통', category: '교통', amount: -1450,
      date: '오늘 08:10', icon: Icons.directions_subway_rounded, iconColor: Color(0xFF7C6FF0)),
  _RecentTx(name: '프리랜서 수입', category: '부업', amount: 150000,
      date: '어제', icon: Icons.work_rounded, iconColor: Color(0xFF34C77B)),
  _RecentTx(name: '올리브영', category: '쇼핑', amount: -71000,
      date: '어제', icon: Icons.shopping_bag_rounded, iconColor: Color(0xFFFF6B6B)),
  _RecentTx(name: '점심 식사', category: '식비', amount: -12000,
      date: '2일 전', icon: Icons.restaurant_rounded, iconColor: Color(0xFF5B8DEF)),
];

class _RecentTransactionTile extends StatelessWidget {
  const _RecentTransactionTile({required this.item});
  final _RecentTx item;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isIncome = item.amount > 0;

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 18, color: item.iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                )),
                Text('${item.category} · ${item.date}', style: tt.labelSmall),
              ],
            ),
          ),
          AmountDisplay(
            amount: item.amount,
            size: AmountSize.small,
          ),
        ],
      ),
    );
  }
}
