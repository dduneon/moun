import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/amount_display.dart';
import '../../shared/widgets/app_bottom_sheet.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/category_selector.dart';
import '../../shared/widgets/charts/category_donut_chart.dart';
import '../../shared/widgets/charts/monthly_bar_chart.dart';
import '../../shared/widgets/charts/spending_line_chart.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/glass_floating_navbar.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/moun_calendar.dart';
import '../../shared/widgets/selection_chip.dart';
import '../../shared/widgets/transaction_list.dart';

class DesignShowcaseScreen extends StatefulWidget {
  const DesignShowcaseScreen({super.key});

  @override
  State<DesignShowcaseScreen> createState() => _DesignShowcaseScreenState();
}

class _DesignShowcaseScreenState extends State<DesignShowcaseScreen> {
  int _selectedTab = 0;
  bool _isExpense = true;
  CategoryItem? _selectedCategory;
  Set<String> _selectedPeriod = {'이번 달'};

  // 날짜별 샘플 거래 목록
  Map<DateTime, List<TransactionItem>> _sampleTransactions() {
    final now = DateTime.now();
    final y = now.year;
    final m = now.month;
    return {
      DateTime(y, m, 1): [
        TransactionItem(
          id: 1, name: '월급', amount: 4200000,
          date: DateTime(y, m, 1, 9, 0),
          category: const CategoryItem(id: 101, label: '급여', icon: Icons.account_balance_rounded, color: Color(0xFF34C77B)),
        ),
      ],
      DateTime(y, m, 3): [
        TransactionItem(
          id: 2, name: '스타벅스 강남점', amount: -6500,
          date: DateTime(y, m, 3, 8, 42),
          category: const CategoryItem(id: 7, label: '카페', icon: Icons.local_cafe_rounded, color: Color(0xFF8D6E63)),
          memo: '아메리카노',
        ),
        TransactionItem(
          id: 3, name: '대중교통', amount: -1450,
          date: DateTime(y, m, 3, 9, 10),
          category: const CategoryItem(id: 2, label: '교통', icon: Icons.directions_subway_rounded, color: Color(0xFF7C6FF0)),
        ),
        TransactionItem(
          id: 4, name: '점심 식사', amount: -12000,
          date: DateTime(y, m, 3, 12, 30),
          category: const CategoryItem(id: 1, label: '식비', icon: Icons.restaurant_rounded, color: Color(0xFF5B8DEF)),
        ),
        TransactionItem(
          id: 5, name: '편의점', amount: -4800,
          date: DateTime(y, m, 3, 22, 15),
          category: const CategoryItem(id: 1, label: '식비', icon: Icons.restaurant_rounded, color: Color(0xFF5B8DEF)),
        ),
      ],
      DateTime(y, m, 12): [
        TransactionItem(
          id: 6, name: '넷플릭스', amount: -17000,
          date: DateTime(y, m, 12, 0, 0),
          category: const CategoryItem(id: 9, label: '구독', icon: Icons.subscriptions_rounded, color: Color(0xFFFF6B6B)),
          isPending: true,
        ),
        TransactionItem(
          id: 7, name: '올리브영', amount: -71000,
          date: DateTime(y, m, 12, 15, 20),
          category: const CategoryItem(id: 3, label: '쇼핑', icon: Icons.shopping_bag_rounded, color: Color(0xFFFF6B6B)),
        ),
      ],
      DateTime(y, m, 14): [
        TransactionItem(
          id: 8, name: '프리랜서 수입', amount: 150000,
          date: DateTime(y, m, 14, 14, 0),
          category: const CategoryItem(id: 102, label: '부업', icon: Icons.work_rounded, color: Color(0xFF5B8DEF)),
        ),
        TransactionItem(
          id: 9, name: '저녁 모임', amount: -55000,
          date: DateTime(y, m, 14, 19, 30),
          category: const CategoryItem(id: 1, label: '식비', icon: Icons.restaurant_rounded, color: Color(0xFF5B8DEF)),
          memo: '친구들과 회식',
        ),
      ],
    };
  }

  Map<DateTime, DayData> _sampleCalendarData() {
    final now = DateTime.now();
    final y = now.year;
    final m = now.month;
    return {
      DateTime(y, m, 1): const DayData(income: 4200000),
      DateTime(y, m, 3): const DayData(expense: 65000),
      DateTime(y, m, 5): const DayData(expense: 142000),
      DateTime(y, m, 7): const DayData(expense: 38000),
      DateTime(y, m, 10): const DayData(expense: 220000),
      DateTime(y, m, 12): const DayData(expense: 88000, hasPending: true),
      DateTime(y, m, 14): const DayData(income: 150000, expense: 55000),
      DateTime(y, m, 16): const DayData(hasPending: true),
      DateTime(y, m, 18): const DayData(expense: 310000),
      DateTime(y, m, 20): const DayData(expense: 45000),
      DateTime(y, m, 21): const DayData(income: 4200000),
      DateTime(y, m, 23): const DayData(expense: 120000),
    };
  }

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
                        children: [
                          Expanded(
                            child: LabeledAmount(
                              label: '총 예산',
                              amount: 3000000,
                              size: AmountSize.small,
                              animate: true,
                            ),
                          ),
                          Expanded(
                            child: LabeledAmount(
                              label: '사용 금액',
                              amount: -1250000,
                              size: AmountSize.small,
                              animate: true,
                            ),
                          ),
                          Expanded(
                            child: LabeledAmount(
                              label: '잔여',
                              amount: 1750000,
                              size: AmountSize.small,
                              animate: true,
                            ),
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
                        children: [
                          Expanded(child: AmountDisplay(amount: 500000, size: AmountSize.small, animate: true)),
                          Expanded(child: AmountDisplay(amount: -120000, size: AmountSize.small, animate: true)),
                          Expanded(
                            child: AmountDisplay(
                              amount: -88000,
                              size: AmountSize.small,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.expensePending,
                              ),
                              animate: true,
                            ),
                          ),
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

                // ── Calendar ────────────────────────────────────────────
                _SectionLabel('달력'),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: MounCalendar(
                    data: _sampleCalendarData(),
                    onDayTap: (day) {
                      final txns = _sampleTransactions()[
                        DateTime(day.year, day.month, day.day)
                      ] ?? [];
                      DayTransactionSheet.show(
                        context,
                        day: day,
                        transactions: txns,
                      );
                    },
                  ),
                ).animate(delay: 100.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: AppSpacing.xl),

                // ── Charts ──────────────────────────────────────────────
                _SectionLabel('카테고리 도넛 차트'),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: CategoryDonutChart(
                    centerLabel: '이번 달 지출',
                    items: const [
                      CategoryData(label: '식비', amount: 420000, color: Color(0xFF5B8DEF)),
                      CategoryData(label: '교통', amount: 85000, color: Color(0xFF7C6FF0)),
                      CategoryData(label: '쇼핑', amount: 230000, color: Color(0xFFFF6B6B)),
                      CategoryData(label: '문화', amount: 120000, color: Color(0xFF34C77B)),
                      CategoryData(label: '기타', amount: 65000, color: Color(0xFFB39DFF)),
                    ],
                  ),
                ).animate(delay: 100.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: AppSpacing.xl),

                _SectionLabel('월별 수입/지출 바 차트'),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: MonthlyBarChart(
                    data: const [
                      MonthlyBarData(label: '1월', income: 4200000, expense: 1800000),
                      MonthlyBarData(label: '2월', income: 4200000, expense: 2100000),
                      MonthlyBarData(label: '3월', income: 4500000, expense: 1650000),
                      MonthlyBarData(label: '4월', income: 4200000, expense: 2300000),
                      MonthlyBarData(label: '5월', income: 4200000, expense: 1950000),
                      MonthlyBarData(label: '6월', income: 4700000, expense: 1250000),
                    ],
                  ),
                ).animate(delay: 150.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: AppSpacing.xl),

                _SectionLabel('일별 지출 라인 차트 (예산선 포함)'),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: SpendingLineChart(
                    budgetLimit: 2000000,
                    points: const [
                      SpendingPoint(day: 1, amount: 65000),
                      SpendingPoint(day: 3, amount: 142000),
                      SpendingPoint(day: 5, amount: 280000),
                      SpendingPoint(day: 8, amount: 395000),
                      SpendingPoint(day: 10, amount: 520000),
                      SpendingPoint(day: 13, amount: 710000),
                      SpendingPoint(day: 15, amount: 880000),
                      SpendingPoint(day: 18, amount: 1050000),
                      SpendingPoint(day: 20, amount: 1230000),
                      SpendingPoint(day: 22, amount: 1480000),
                      SpendingPoint(day: 25, amount: 1650000),
                      SpendingPoint(day: 28, amount: 1820000),
                      SpendingPoint(day: 30, amount: 1950000),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: AppSpacing.xl),

                _SectionLabel('이번 달 vs 지난 달 비교'),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: CompareLineChart(
                    series: const [
                      MultiLineData(
                        label: '이번 달',
                        color: AppColors.primary,
                        points: [
                          SpendingPoint(day: 1, amount: 65000),
                          SpendingPoint(day: 5, amount: 280000),
                          SpendingPoint(day: 10, amount: 520000),
                          SpendingPoint(day: 15, amount: 880000),
                          SpendingPoint(day: 20, amount: 1230000),
                          SpendingPoint(day: 25, amount: 1650000),
                          SpendingPoint(day: 30, amount: 1950000),
                        ],
                      ),
                      MultiLineData(
                        label: '지난 달',
                        color: AppColors.textSecondary,
                        points: [
                          SpendingPoint(day: 1, amount: 95000),
                          SpendingPoint(day: 5, amount: 380000),
                          SpendingPoint(day: 10, amount: 720000),
                          SpendingPoint(day: 15, amount: 1100000),
                          SpendingPoint(day: 20, amount: 1580000),
                          SpendingPoint(day: 25, amount: 1920000),
                          SpendingPoint(day: 30, amount: 2100000),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: 250.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: AppSpacing.xl),

                // ── Buttons ─────────────────────────────────────────────
                _SectionLabel('버튼'),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Column(
                    children: [
                      AppButton(label: '저장하기', onPressed: () {}),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(label: '취소', onPressed: () {}, variant: AppButtonVariant.secondary),
                      const SizedBox(height: AppSpacing.sm),
                      Row(children: [
                        Expanded(child: AppButton(label: '닫기', onPressed: () {}, variant: AppButtonVariant.ghost, expanded: false)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: AppButton(label: '삭제', onPressed: () {}, variant: AppButtonVariant.danger, expanded: false)),
                      ]),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(label: '로딩 중...', onPressed: null, loading: true),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Text Fields ─────────────────────────────────────────
                _SectionLabel('입력창'),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Column(
                    children: [
                      const AppTextField(label: '메모', hint: '거래 내용을 입력하세요'),
                      const SizedBox(height: AppSpacing.md),
                      const AmountTextField(label: '금액'),
                      const SizedBox(height: AppSpacing.md),
                      const AppTextField(
                        label: '비밀번호',
                        hint: '비밀번호를 입력하세요',
                        obscureText: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Selection Chips ─────────────────────────────────────
                _SectionLabel('선택 칩'),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('기간 필터', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      SelectionChipGroup<String>(
                        items: const ['이번 달', '지난 달', '3개월', '6개월', '1년'],
                        labelOf: (s) => s,
                        selected: _selectedPeriod,
                        onSelected: (v) => setState(() => _selectedPeriod = v),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('수입/지출 타입', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      TransactionTypeToggle(
                        isExpense: _isExpense,
                        onChanged: (v) => setState(() => _isExpense = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Category Selector ───────────────────────────────────
                _SectionLabel('카테고리 선택'),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('인라인 그리드', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.md),
                      CategoryGrid(
                        items: defaultExpenseCategories,
                        selectedId: _selectedCategory?.id,
                        onSelected: (c) => setState(() => _selectedCategory = c),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('필드 탭 → 바텀시트', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      CategoryPickerField(
                        selected: _selectedCategory,
                        onSelected: (c) => setState(() => _selectedCategory = c),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Bottom Sheet & Dialog ───────────────────────────────
                _SectionLabel('바텀시트 / 다이얼로그'),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Column(
                    children: [
                      AppButton(
                        label: '거래 추가 바텀시트 열기',
                        onPressed: () => AppBottomSheet.show(
                          context,
                          title: '거래 추가',
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TransactionTypeToggle(
                                isExpense: _isExpense,
                                onChanged: (v) => setState(() => _isExpense = v),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const AmountTextField(label: '금액'),
                              const SizedBox(height: AppSpacing.md),
                              CategoryPickerField(
                                selected: _selectedCategory,
                                onSelected: (c) => setState(() => _selectedCategory = c),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const AppTextField(label: '메모', hint: '(선택)'),
                              const SizedBox(height: AppSpacing.xl),
                              AppButton(label: '저장하기', onPressed: () => Navigator.pop(context)),
                            ],
                          ),
                        ),
                        icon: Icons.add_rounded,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: '삭제 확인 다이얼로그',
                        onPressed: () async {
                          final ok = await AppConfirmDialog.show(
                            context,
                            title: '거래 삭제',
                            message: '이 거래를 삭제하면 되돌릴 수 없어요. 계속할까요?',
                            confirmLabel: '삭제',
                            isDestructive: true,
                          );
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('삭제되었습니다')),
                            );
                          }
                        },
                        variant: AppButtonVariant.danger,
                        icon: Icons.delete_outline_rounded,
                      ),
                    ],
                  ),
                ),

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
