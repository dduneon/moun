import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/amount_display.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/charts/category_donut_chart.dart';
import '../../../../shared/widgets/charts/monthly_bar_chart.dart';
import '../../../../shared/widgets/charts/spending_line_chart.dart';
import '../../../budget/domain/budget_models.dart' show AvailableBudget, SpendSummary, CategoryData;
import '../../../budget/presentation/providers/budget_provider.dart';
import '../providers/statistics_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
            ),
            child: Text('통계', style: tt.headlineMedium)
                .animate()
                .fadeIn(duration: 300.ms),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
            ),
            child: TabBar(
              controller: _tabController,
              labelStyle: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: tt.labelLarge,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: AppColors.divider,
              tabs: const [
                Tab(text: '이번 사이클'),
                Tab(text: '사이클 비교'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CurrentCycleTab(),
                _CycleCompareTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: 이번 사이클
// ─────────────────────────────────────────────────────────────────────────────

class _CurrentCycleTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final budgetAsync = ref.watch(availableBudgetProvider);
    final pointsAsync = ref.watch(dailySpendingPointsProvider);
    final cycleAsync = ref.watch(currentCycleProvider);

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: budgetAsync.when(
              data: (b) => Row(
                children: [
                  Expanded(child: _SummaryCard(
                    label: '총 수입',
                    amount: b.expectedIncome.round(),
                    color: AppColors.income,
                    icon: Icons.arrow_circle_up_rounded,
                  )),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _SummaryCard(
                    label: '총 지출',
                    amount: -b.totalSpent.round(),
                    color: AppColors.expense,
                    icon: Icons.arrow_circle_down_rounded,
                  )),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _SummaryCard(
                    label: '순수익',
                    amount: (b.expectedIncome - b.totalSpent).round(),
                    color: AppColors.primary,
                    icon: Icons.savings_rounded,
                  )),
                ],
              ),
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox.shrink(),
            ).animate(delay: 100.ms).fadeIn(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('카테고리별 지출', style: tt.titleLarge),
                  const SizedBox(height: AppSpacing.lg),
                  budgetAsync.when(
                    data: (b) {
                      final items = _buildDonutItems(b.spendSummary);
                      if (items.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xl),
                            child: Text('지출 내역이 없습니다',
                                style: tt.bodySmall?.copyWith(
                                    color: AppColors.textSecondary)),
                          ),
                        );
                      }
                      return CategoryDonutChart(
                        centerLabel: '이번 사이클',
                        items: items,
                      );
                    },
                    loading: () => const SizedBox(height: 200),
                    error: (_, __) => Center(
                      child: Text('데이터 없음',
                          style: tt.bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('지출 추이', style: tt.titleLarge),
                    const Spacer(),
                    if (cycleAsync.value != null)
                      Text(
                        cycleAsync.value!.label,
                        style: tt.labelSmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  pointsAsync.when(
                    data: (points) {
                      if (points.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xl),
                            child: Text('지출 내역이 없습니다',
                                style: tt.bodySmall?.copyWith(
                                    color: AppColors.textSecondary)),
                          ),
                        );
                      }
                      return budgetAsync.when(
                        data: (b) => SpendingLineChart(
                          budgetLimit: b.expectedIncome.round(),
                          points: points,
                        ),
                        loading: () => SpendingLineChart(points: points),
                        error: (_, __) => SpendingLineChart(points: points),
                      );
                    },
                    loading: () => const SizedBox(height: 160),
                    error: (_, __) => const SizedBox(height: 160),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }

  static const _donutColors = [
    Color(0xFF5B8DEF),
    Color(0xFF7C6FF0),
    Color(0xFFFF6B6B),
    Color(0xFF34C77B),
    Color(0xFFB39DFF),
    Color(0xFFFF9F43),
    Color(0xFF54A0FF),
    Color(0xFF8D6E63),
  ];

  List<CategoryData> _buildDonutItems(SpendSummary summary) {
    final expenseItems = summary.byCategory
        .where((c) => c.total < 0)
        .toList()
      ..sort((a, b) => a.total.compareTo(b.total));

    return expenseItems.asMap().entries.map((e) {
      final color = _donutColors[e.key % _donutColors.length];
      return CategoryData(
        label: e.value.categoryName,
        amount: e.value.total.abs().round(),
        color: color,
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: 사이클 비교
// ─────────────────────────────────────────────────────────────────────────────

class _CycleCompareTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final allAsync = ref.watch(allCycleBudgetsProvider);

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('사이클별 수입 / 지출', style: tt.titleLarge),
                  const SizedBox(height: AppSpacing.lg),
                  allAsync.when(
                    data: (budgets) {
                      if (budgets.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xl),
                            child: Text('데이터가 없습니다',
                                style: tt.bodySmall?.copyWith(
                                    color: AppColors.textSecondary)),
                          ),
                        );
                      }
                      final barData = budgets.map((b) => MonthlyBarData(
                            label: b.label,
                            income: b.expectedIncome.round(),
                            expense: b.totalSpent.round(),
                          )).toList();
                      return MonthlyBarChart(data: barData);
                    },
                    loading: () => const SizedBox(height: 220),
                    error: (_, __) => Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xl),
                        child: Text('불러오기 실패',
                            style: tt.bodySmall?.copyWith(
                                color: AppColors.textSecondary)),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

        allAsync.when(
          data: (budgets) => SliverList.separated(
            itemCount: budgets.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _CycleRow(budget: budgets[i]),
              ).animate(delay: (120 + i * 40).ms).fadeIn(duration: 300.ms);
            },
          ),
          loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }
}

class _CycleRow extends StatelessWidget {
  const _CycleRow({required this.budget});
  final AvailableBudget budget;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final net = budget.expectedIncome - budget.totalSpent;
    final netColor = net >= 0 ? AppColors.income : AppColors.expense;

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(budget.label,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '지출 ${_fmtWon(budget.totalSpent.round())}',
                style: tt.labelSmall?.copyWith(color: AppColors.expense),
              ),
              const SizedBox(height: 2),
              Text(
                (net >= 0 ? '+' : '') + _fmtWon(net.round()),
                style: tt.labelSmall?.copyWith(
                    color: netColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtWon(int amount) {
    final abs = amount.abs();
    final prefix = amount < 0 ? '-' : '';
    if (abs >= 10000) return '$prefix${(abs / 10000).toStringAsFixed(0)}만원';
    return '$prefix${abs}원';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 공통 위젯
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });
  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AmountDisplay(amount: amount, size: AmountSize.small),
          ),
        ],
      ),
    );
  }
}
