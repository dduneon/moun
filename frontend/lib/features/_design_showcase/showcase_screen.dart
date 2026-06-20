import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/amount_display.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/glass_floating_navbar.dart';
import '../../shared/widgets/gradient_background.dart';

class DesignShowcaseScreen extends StatefulWidget {
  const DesignShowcaseScreen({super.key});

  @override
  State<DesignShowcaseScreen> createState() => _DesignShowcaseScreenState();
}

class _DesignShowcaseScreenState extends State<DesignShowcaseScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              120, // room for floating navbar
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text('모운 디자인 시스템', style: tt.headlineLarge)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.2, end: 0),
                const SizedBox(height: AppSpacing.xs),
                Text('Design Showcase', style: tt.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ))
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: AppSpacing.xl),

                // ── Colors ──────────────────────────────────────────────
                _SectionLabel('컬러 팔레트'),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: const [
                    _ColorChip('primary', AppColors.primary),
                    _ColorChip('gradient end', AppColors.primaryGradientEnd),
                    _ColorChip('income', AppColors.income),
                    _ColorChip('expense', AppColors.expense),
                    _ColorChip('pending', AppColors.expensePending),
                    _ColorChip('text primary', AppColors.textPrimary),
                    _ColorChip('text secondary', AppColors.textSecondary),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Typography ───────────────────────────────────────────
                _SectionLabel('타이포그래피'),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Display Large — 큰 금액 표시', style: tt.displayLarge?.copyWith(fontSize: 28)),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Headline Medium — 섹션 타이틀', style: tt.headlineMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Body Large — 본문 텍스트', style: tt.bodyLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Body Medium — 보조 텍스트', style: tt.bodyMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Label Small — 캡션 / 보조 라벨', style: tt.labelSmall),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── GlassCard ────────────────────────────────────────────
                _SectionLabel('GlassCard'),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('이번 달 예산 현황', style: tt.titleLarge),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          LabeledAmount(
                            label: '총 예산',
                            amount: 3000000,
                            size: AmountSize.medium,
                            animate: true,
                          ),
                          LabeledAmount(
                            label: '사용 금액',
                            amount: -1250000,
                            size: AmountSize.medium,
                            animate: true,
                          ),
                          LabeledAmount(
                            label: '잔여',
                            amount: 1750000,
                            size: AmountSize.medium,
                            animate: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: AppSpacing.md),

                // Nested glass cards
                Row(
                  children: [
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_upward_rounded,
                                color: AppColors.income, size: 20),
                            const SizedBox(height: AppSpacing.xs),
                            Text('수입', style: tt.labelSmall),
                            AmountDisplay(
                              amount: 4200000,
                              size: AmountSize.small,
                              animate: true,
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
                            const Icon(Icons.arrow_downward_rounded,
                                color: AppColors.expense, size: 20),
                            const SizedBox(height: AppSpacing.xs),
                            Text('지출', style: tt.labelSmall),
                            AmountDisplay(
                              amount: -1250000,
                              size: AmountSize.small,
                              animate: true,
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
                            const Icon(Icons.schedule_rounded,
                                color: AppColors.expensePending, size: 20),
                            const SizedBox(height: AppSpacing.xs),
                            Text('청구 예정', style: tt.labelSmall),
                            AmountDisplay(
                              amount: -320000,
                              size: AmountSize.small,
                              animate: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── AmountDisplay ────────────────────────────────────────
                _SectionLabel('AmountDisplay'),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Column(
                    children: [
                      AmountDisplay(
                        amount: 3200000,
                        size: AmountSize.large,
                        animate: true,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          AmountDisplay(amount: 500000, size: AmountSize.medium, showSign: true, animate: true),
                          AmountDisplay(amount: -120000, size: AmountSize.medium, showSign: true, animate: true),
                          AmountDisplay(amount: -88000, size: AmountSize.medium, style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.expensePending,
                          ), animate: true),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Transaction List Sample ──────────────────────────────
                _SectionLabel('거래 내역 (샘플)'),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: const [
                      _TransactionItem(
                        icon: Icons.restaurant_rounded,
                        category: '식비',
                        name: '스타벅스 강남점',
                        date: '오늘 09:32',
                        amount: -6500,
                      ),
                      _TransactionItem(
                        icon: Icons.directions_subway_rounded,
                        category: '교통',
                        name: '대중교통',
                        date: '오늘 08:10',
                        amount: -1500,
                        isLast: false,
                      ),
                      _TransactionItem(
                        icon: Icons.account_balance_rounded,
                        category: '급여',
                        name: '월급',
                        date: '어제',
                        amount: 4200000,
                        isLast: true,
                      ),
                    ],
                  ),
                ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: AppSpacing.xl),

                // ── Gradient Background Info ─────────────────────────────
                _SectionLabel('GradientBackground'),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('#F7F8FC → #FFFFFF', style: Theme.of(context).textTheme.bodyMedium),
                          Text('앱 전체 배경 그라데이션', style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: GlassFloatingNavbar(
          currentIndex: _selectedTab,
          onTap: (i) => setState(() => _selectedTab = i),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.primaryGradientEnd],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.icon,
    required this.category,
    required this.name,
    required this.date,
    required this.amount,
    this.isLast = false,
  });

  final IconData icon;
  final String category;
  final String name;
  final String date;
  final int amount;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isIncome = amount > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isIncome ? AppColors.income : AppColors.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isIncome ? AppColors.income : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: tt.bodyMedium),
                    Text(
                      '$category · $date',
                      style: tt.labelSmall,
                    ),
                  ],
                ),
              ),
              AmountDisplay(
                amount: amount,
                size: AmountSize.small,
                showSign: false,
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: AppSpacing.lg + 40 + AppSpacing.md,
            endIndent: AppSpacing.lg,
          ),
      ],
    );
  }
}
