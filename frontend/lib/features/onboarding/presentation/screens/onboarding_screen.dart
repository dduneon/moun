import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // ── 스텝 1: 예산 시작일
  int _salaryDay = 21;
  bool _noSalary = false;
  String _paydayAdjustment = 'prev_business';

  // ── 스텝 2: 고정 수입
  final List<_IncomeEntry> _incomes = [];

  // ── 스텝 3: 고정 지출
  final List<_ExpenseEntry> _expenses = [];

  bool _saving = false;

  void _next() {
    if (_page < 2) {
      _pageCtrl.animateToPage(_page + 1,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() => _page++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final repo = ref.read(settingsRepositoryProvider);
    try {
      // 1) 설정 저장
      await repo.patchSetting({
        'salary_day': _noSalary ? 0 : _salaryDay,
        'payday_adjustment': _paydayAdjustment,
      });

      // 2) 고정 수입 저장
      for (final e in _incomes) {
        await repo.createIncome(
          name: e.name,
          amount: e.amount.toDouble(),
          type: e.type,
          scheduledDay: e.day,
        );
      }

      // 3) 고정 지출 저장
      for (final e in _expenses) {
        await repo.createFixedExpense(
          name: e.name,
          amount: e.amount.toDouble(),
          billingDay: e.billingDay,
          paymentMethod: e.paymentMethod,
        );
      }

      ref.read(authProvider.notifier).completeOnboarding();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('저장 중 오류: $e')));
      }
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final steps = ['예산 시작일', '고정 수입', '고정 지출'];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 진행 표시
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      steps.length,
                      (i) => Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 3,
                          margin: EdgeInsets.only(
                              right: i < steps.length - 1 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: i <= _page
                                ? AppColors.primary
                                : AppColors.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('${_page + 1} / ${steps.length}  ·  ${steps[_page]}',
                      style: tt.labelMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),

            // ── 페이지 콘텐츠
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1(
                    salaryDay: _salaryDay,
                    noSalary: _noSalary,
                    paydayAdjustment: _paydayAdjustment,
                    onDayChanged: (d) => setState(() => _salaryDay = d),
                    onNoSalaryChanged: (v) => setState(() => _noSalary = v),
                    onAdjustmentChanged: (v) =>
                        setState(() => _paydayAdjustment = v),
                  ),
                  _Step2(
                    incomes: _incomes,
                    onChanged: () => setState(() {}),
                  ),
                  _Step3(
                    expenses: _expenses,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
            ),

            // ── 하단 버튼
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  if (_page > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: OutlinedButton(
                        onPressed: () {
                          _pageCtrl.animateToPage(_page - 1,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut);
                          setState(() => _page--);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.buttonBorderRadius),
                          side: const BorderSide(color: AppColors.divider),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            size: 20, color: AppColors.textSecondary),
                      ),
                    ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.buttonBorderRadius),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _page < 2 ? '다음' : '시작하기',
                              style: tt.labelLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                    ),
                  ),
                  if (_page < 2) ...[
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      onPressed: _saving ? null : _next,
                      child: Text('건너뛰기',
                          style: tt.labelMedium?.copyWith(
                              color: AppColors.textSecondary)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 1: 월급날 설정 ──────────────────────────────────────

class _Step1 extends StatelessWidget {
  const _Step1({
    required this.salaryDay,
    required this.noSalary,
    required this.paydayAdjustment,
    required this.onDayChanged,
    required this.onNoSalaryChanged,
    required this.onAdjustmentChanged,
  });

  final int salaryDay;
  final bool noSalary;
  final String paydayAdjustment;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<bool> onNoSalaryChanged;
  final ValueChanged<String> onAdjustmentChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('월급날이 언제예요?',
              style: tt.headlineMedium?.copyWith(height: 1.3))
              .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppSpacing.sm),
          Text('예산 기간은 매월 1일~말일로 자동 계산돼요.',
              style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary))
              .animate().fadeIn(delay: 200.ms),

          const SizedBox(height: AppSpacing.lg),

          // 예산 기간 안내 배너
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: AppRadius.buttonBorderRadius,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '예산 기간: 매월 1일 ~ 말일 (고정)',
                  style: tt.labelMedium?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 220.ms),

          const SizedBox(height: AppSpacing.xl),

          // 월급 없음 옵션
          GestureDetector(
            onTap: () => onNoSalaryChanged(!noSalary),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: noSalary
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : const Color(0x08000000),
                borderRadius: AppRadius.buttonBorderRadius,
                border: Border.all(
                    color: noSalary ? AppColors.primary : AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(
                    noSalary ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 20,
                    color: noSalary ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('정해진 월급날이 없어요',
                            style: tt.bodyMedium?.copyWith(
                              color: noSalary ? AppColors.primary : null,
                              fontWeight: noSalary ? FontWeight.w600 : FontWeight.w400,
                            )),
                        Text('프리랜서, 사업자, 학생 등',
                            style: tt.labelSmall?.copyWith(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 250.ms),

          if (!noSalary) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('월급 수령일',
                style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1,
              ),
              itemCount: 28,
              itemBuilder: (_, i) {
                final day = i + 1;
                final isSel = day == salaryDay;
                return GestureDetector(
                  onTap: () => onDayChanged(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: tt.bodyMedium?.copyWith(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: AppSpacing.lg),
            Text('주말/공휴일 지급',
                style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            ...[
              ('prev_business', '이전 영업일', '주말이면 금요일에 먼저 지급'),
              ('next_business', '다음 영업일', '주말이면 월요일에 지급'),
              ('exact', '당일 그대로', '날짜 변경 없이 처리'),
            ].map((opt) {
              final (val, label, desc) = opt;
              final isSel = paydayAdjustment == val;
              return GestureDetector(
                onTap: () => onAdjustmentChanged(val),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: isSel
                        ? AppColors.primary.withValues(alpha: 0.07)
                        : const Color(0x07000000),
                    borderRadius: AppRadius.buttonBorderRadius,
                    border: Border.all(
                        color: isSel ? AppColors.primary : AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label,
                                style: tt.bodyMedium?.copyWith(
                                  color: isSel ? AppColors.primary : null,
                                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                                )),
                            Text(desc,
                                style: tt.labelSmall?.copyWith(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      if (isSel)
                        const Icon(Icons.check_rounded,
                            size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ── Step 2: 고정 수입 ──────────────────────────────────────

class _IncomeEntry {
  _IncomeEntry({
    required this.name,
    required this.amount,
    required this.type,
    this.day,
  });
  String name;
  int amount;
  String type; // 'salary' | 'extra'
  int? day;
}

class _Step2 extends StatefulWidget {
  const _Step2({required this.incomes, required this.onChanged});
  final List<_IncomeEntry> incomes;
  final VoidCallback onChanged;

  @override
  State<_Step2> createState() => _Step2State();
}

class _Step2State extends State<_Step2> {
  final fmt = NumberFormat('#,###');

  void _add() async {
    final result = await showModalBottomSheet<_IncomeEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddIncomeSheet(),
    );
    if (result != null) {
      widget.incomes.add(result);
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('매달 들어오는\n고정 수입이 있나요?',
              style: tt.headlineMedium?.copyWith(height: 1.3))
              .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppSpacing.sm),
          Text('급여, 월세 수입 등을 등록해 두면\n예산을 더 정확하게 계산해요.',
              style: tt.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary))
              .animate().fadeIn(delay: 200.ms),

          const SizedBox(height: AppSpacing.xl),

          if (widget.incomes.isEmpty)
            GlassCard(
              child: Column(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 40, color: AppColors.textSecondary),
                  const SizedBox(height: AppSpacing.sm),
                  Text('등록된 고정 수입이 없어요',
                      style: tt.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                  Text('없으면 건너뛰어도 됩니다.',
                      style: tt.labelSmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms)
          else ...[
            ...widget.incomes.asMap().entries.map((entry) {
              final e = entry.value;
              return _EntryCard(
                icon: e.type == 'salary'
                    ? Icons.account_balance_rounded
                    : Icons.work_rounded,
                iconColor: AppColors.income,
                title: e.name,
                subtitle: e.day != null ? '매월 ${e.day}일' : null,
                value: '+${fmt.format(e.amount)}원',
                valueColor: AppColors.income,
                onDelete: () {
                  widget.incomes.removeAt(entry.key);
                  widget.onChanged();
                },
              ).animate().fadeIn();
            }),
          ],

          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('고정 수입 추가'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.income,
                side: BorderSide(
                    color: AppColors.income.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.buttonBorderRadius),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

// ── Step 3: 고정 지출 ──────────────────────────────────────

class _ExpenseEntry {
  _ExpenseEntry({
    required this.name,
    required this.amount,
    required this.billingDay,
    required this.paymentMethod,
  });
  String name;
  int amount;
  int billingDay;
  String paymentMethod;
}

class _Step3 extends StatefulWidget {
  const _Step3({required this.expenses, required this.onChanged});
  final List<_ExpenseEntry> expenses;
  final VoidCallback onChanged;

  @override
  State<_Step3> createState() => _Step3State();
}

class _Step3State extends State<_Step3> {
  final fmt = NumberFormat('#,###');

  void _add() async {
    final result = await showModalBottomSheet<_ExpenseEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddExpenseSheet(),
    );
    if (result != null) {
      widget.expenses.add(result);
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('매달 나가는\n고정 지출이 있나요?',
              style: tt.headlineMedium?.copyWith(height: 1.3))
              .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppSpacing.sm),
          Text('구독, 월세, 보험료 등을 등록하면\n남은 예산을 정확히 파악할 수 있어요.',
              style: tt.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary))
              .animate().fadeIn(delay: 200.ms),

          const SizedBox(height: AppSpacing.xl),

          if (widget.expenses.isEmpty)
            GlassCard(
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 40, color: AppColors.textSecondary),
                  const SizedBox(height: AppSpacing.sm),
                  Text('등록된 고정 지출이 없어요',
                      style: tt.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                  Text('없으면 건너뛰어도 됩니다.',
                      style: tt.labelSmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms)
          else ...[
            ...widget.expenses.asMap().entries.map((entry) {
              final e = entry.value;
              final pmLabel = switch (e.paymentMethod) {
                'card' => '카드',
                'cash' => '현금',
                _ => '계좌이체',
              };
              return _EntryCard(
                icon: Icons.repeat_rounded,
                iconColor: AppColors.expense,
                title: e.name,
                subtitle: '매월 ${e.billingDay}일 · $pmLabel',
                value: '-${fmt.format(e.amount)}원',
                valueColor: AppColors.expense,
                onDelete: () {
                  widget.expenses.removeAt(entry.key);
                  widget.onChanged();
                },
              ).animate().fadeIn();
            }),
          ],

          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('고정 지출 추가'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.expense,
                side: BorderSide(
                    color: AppColors.expense.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.buttonBorderRadius),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

// ── 공용 카드 ──────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.valueColor,
    required this.onDelete,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String value;
  final Color valueColor;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0x08000000),
        borderRadius: AppRadius.buttonBorderRadius,
        border: Border.all(color: AppColors.divider),
      ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: tt.labelSmall
                          ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(value,
              style: tt.bodyMedium?.copyWith(
                  color: valueColor, fontWeight: FontWeight.w600)),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── 고정 수입 추가 시트 ───────────────────────────────────────

class _AddIncomeSheet extends StatefulWidget {
  const _AddIncomeSheet();

  @override
  State<_AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends State<_AddIncomeSheet> {
  final _nameCtrl = TextEditingController();
  int _amount = 0;
  String _type = 'salary';
  int? _day;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
          AppSpacing.lg + mq.viewInsets.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 핸들
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('고정 수입 추가', style: tt.titleLarge),
          const SizedBox(height: AppSpacing.lg),

          // 타입
          Row(
            children: [
              ('salary', '급여', Icons.account_balance_rounded),
              ('extra', '부가 수입', Icons.work_rounded),
            ].map((opt) {
              final (val, label, icon) = opt;
              final isSel = _type == val;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(
                        right: val == 'salary' ? AppSpacing.sm : 0),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm + 2),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.income.withValues(alpha: 0.1)
                          : const Color(0x0A000000),
                      borderRadius: AppRadius.buttonBorderRadius,
                      border: Border.all(
                          color: isSel
                              ? AppColors.income
                              : AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon,
                            size: 14,
                            color: isSel
                                ? AppColors.income
                                : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(label,
                            style: tt.labelMedium?.copyWith(
                              color: isSel
                                  ? AppColors.income
                                  : AppColors.textSecondary,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          AppTextField(
            controller: _nameCtrl,
            label: '이름',
            hint: _type == 'salary' ? '회사명 또는 급여' : '부업, 임대료 등',
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AmountTextField(
            label: '예상 금액',
            onChanged: (v) => _amount = v,
          ),
          const SizedBox(height: AppSpacing.md),

          // 지급일 (간단한 드롭다운식)
          _InlineDayPicker(
            label: '지급일 (선택)',
            value: _day,
            onChanged: (v) => setState(() => _day = v),
          ),

          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: _nameCtrl.text.trim().isEmpty || _amount <= 0
                ? null
                : () {
                    Navigator.pop(
                        context,
                        _IncomeEntry(
                          name: _nameCtrl.text.trim(),
                          amount: _amount,
                          type: _type,
                          day: _day,
                        ));
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.income,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.buttonBorderRadius),
            ),
            child: Text('추가', style: tt.labelLarge),
          ),
        ],
      ),
    );
  }
}

// ── 고정 지출 추가 시트 ───────────────────────────────────────

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _nameCtrl = TextEditingController();
  int _amount = 0;
  int _billingDay = 1;
  String _method = 'account';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  static const _methods = [
    ('account', '계좌이체'),
    ('card', '카드'),
    ('cash', '현금'),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
          AppSpacing.lg + mq.viewInsets.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('고정 지출 추가', style: tt.titleLarge),
          const SizedBox(height: AppSpacing.lg),

          AppTextField(
            controller: _nameCtrl,
            label: '이름',
            hint: '넷플릭스, 월세, 보험료 등',
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AmountTextField(
            label: '금액',
            onChanged: (v) => _amount = v,
          ),
          const SizedBox(height: AppSpacing.md),

          _InlineDayPicker(
            label: '청구일',
            value: _billingDay,
            onChanged: (v) => setState(() => _billingDay = v ?? 1),
          ),
          const SizedBox(height: AppSpacing.md),

          Text('결제 수단',
              style: tt.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: _methods.map((opt) {
              final (val, label) = opt;
              final isSel = _method == val;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _method = val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(
                        right: val != 'cash' ? AppSpacing.sm : 0),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : const Color(0x0A000000),
                      borderRadius: AppRadius.buttonBorderRadius,
                      border: Border.all(
                          color: isSel
                              ? AppColors.primary
                              : AppColors.divider),
                    ),
                    child: Center(
                      child: Text(label,
                          style: tt.labelMedium?.copyWith(
                            color: isSel
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSel
                                ? FontWeight.w600
                                : FontWeight.w400,
                          )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: _nameCtrl.text.trim().isEmpty || _amount <= 0
                ? null
                : () {
                    Navigator.pop(
                        context,
                        _ExpenseEntry(
                          name: _nameCtrl.text.trim(),
                          amount: _amount,
                          billingDay: _billingDay,
                          paymentMethod: _method,
                        ));
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.buttonBorderRadius),
            ),
            child: Text('추가', style: tt.labelLarge),
          ),
        ],
      ),
    );
  }
}

// ── 인라인 날짜 피커 (공용) ────────────────────────────────────

class _InlineDayPicker extends StatefulWidget {
  const _InlineDayPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  State<_InlineDayPicker> createState() => _InlineDayPickerState();
}

class _InlineDayPickerState extends State<_InlineDayPicker> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0x0A000000),
        borderRadius: AppRadius.buttonBorderRadius,
        border: Border.all(
            color: _open ? AppColors.primary : AppColors.divider,
            width: _open ? 1.5 : 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Text(widget.label,
                      style: tt.bodyLarge?.copyWith(
                        color: widget.value != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      )),
                  const Spacer(),
                  if (widget.value != null)
                    Text('매월 ${widget.value}일',
                        style: tt.bodyMedium
                            ?.copyWith(color: AppColors.primary)),
                  const SizedBox(width: AppSpacing.xs),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: AppSpacing.xs,
                  crossAxisSpacing: AppSpacing.xs,
                  childAspectRatio: 1,
                ),
                itemCount: 28,
                itemBuilder: (_, i) {
                  final day = i + 1;
                  final isSel = day == widget.value;
                  return GestureDetector(
                    onTap: () {
                      widget.onChanged(day);
                      setState(() => _open = false);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: tt.labelSmall?.copyWith(
                          color: isSel
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: isSel
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
