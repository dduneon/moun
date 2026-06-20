import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/domain/auth_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/budget/domain/budget_models.dart';
import '../../../../features/budget/presentation/providers/budget_provider.dart';
import '../../../../features/transactions/presentation/providers/transaction_provider.dart';
import '../../../../shared/widgets/amount_display.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/transaction_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthStateAuthenticated ? authState.user : null;
    final tt = Theme.of(context).textTheme;

    final cycleAsync = ref.watch(currentCycleProvider);
    final budgetAsync = ref.watch(availableBudgetProvider);
    final txnsAsync = ref.watch(transactionItemsProvider);

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
                      cycleAsync.when(
                        data: (c) => Text(
                          '${c.label} 예산 현황',
                          style: tt.bodyMedium?.copyWith(
                              color: AppColors.textSecondary),
                        ),
                        loading: () => Text('불러오는 중...',
                            style: tt.bodyMedium?.copyWith(
                                color: AppColors.textSecondary)),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
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
              child: budgetAsync.when(
                data: (budget) => _BudgetCard(budget: budget, cycle: cycleAsync.value),
                loading: () => const _BudgetCardSkeleton(),
                error: (e, st) {
                  debugPrint('[budget error] $e\n$st');
                  return GlassCard(
                    child: Text('예산 정보를 불러올 수 없어요\n$e',
                        style: tt.bodyMedium?.copyWith(
                            color: AppColors.textSecondary)),
                  );
                },
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // ── 수입 / 고정지출 카드 ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: budgetAsync.when(
                data: (budget) => Row(
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
                            AmountDisplay(
                              amount: (budget.salary + budget.extraIncome).round(),
                              size: AmountSize.small,
                            ),
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
                            AmountDisplay(
                              amount: -budget.fixedExpense.round(),
                              size: AmountSize.small,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox(height: 76),
                error: (_, __) => const SizedBox.shrink(),
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
                    onPressed: () => context.go('/transactions'),
                    child: Text('전체보기',
                        style: tt.labelMedium
                            ?.copyWith(color: AppColors.primary)),
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
            sliver: txnsAsync.when(
              data: (items) {
                final recent = items.take(5).toList();
                if (recent.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Text('거래 내역이 없어요',
                            style: tt.bodyMedium?.copyWith(
                                color: AppColors.textSecondary)),
                      ),
                    ),
                  );
                }
                return SliverList.separated(
                  itemCount: recent.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _RecentTransactionTile(
                    item: recent[i],
                  ).animate(
                      delay: (300 + i * 60).ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.05, end: 0),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SliverToBoxAdapter(
                child: SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 서브 위젯 ─────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget, this.cycle});
  final AvailableBudget budget;
  final BudgetCycle? cycle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final fmt = DateFormat('M/d');
    final dateLabel = cycle != null
        ? '${fmt.format(cycle!.startDate)} ~ ${fmt.format(cycle!.endDate)}'
        : '';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('사용 가능 예산',
                  style: tt.labelMedium
                      ?.copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              if (dateLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(dateLabel,
                      style: tt.labelSmall
                          ?.copyWith(color: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AmountDisplay(
            amount: budget.available.round(),
            size: AmountSize.large,
            animate: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          _BudgetProgressBar(
            spent: budget.totalSpent.round(),
            total: (budget.salary + budget.extraIncome).round(),
          ),
        ],
      ),
    );
  }
}

class _BudgetCardSkeleton extends StatelessWidget {
  const _BudgetCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 14, width: 80,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              )),
          const SizedBox(height: AppSpacing.sm),
          Container(height: 36, width: 180,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              )),
          const SizedBox(height: AppSpacing.lg),
          Container(height: 6, width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              )),
        ],
      ),
    );
  }
}

class _BudgetProgressBar extends StatelessWidget {
  const _BudgetProgressBar({required this.spent, required this.total});
  final int spent;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
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
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _RecentTransactionTile extends StatelessWidget {
  const _RecentTransactionTile({required this.item});
  final TransactionItem item;

  static final _amtFmt = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.category.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.category.icon, size: 18, color: item.category.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                Text('${item.category.label} · ${_timeLabel(item.date)}',
                    style: tt.labelSmall),
              ],
            ),
          ),
          Text(
            item.isIncome
                ? '+${_amtFmt.format(item.amount)}원'
                : '-${_amtFmt.format(item.amount.abs())}원',
            style: tt.bodyMedium?.copyWith(
              color: item.isIncome ? AppColors.income : AppColors.expense,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime date) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (diff == 0) return '오늘';
    if (diff == 1) return '어제';
    return '${diff}일 전';
  }
}
