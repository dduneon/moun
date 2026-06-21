import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
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

  // ── 스텝 1: 고정 수입
  final List<_IncomeEntry> _incomes = [];

  // ── 스텝 2: 고정 지출
  final List<_ExpenseEntry> _expenses = [];

  // ── 스텝 3: 예산 기준일
  int _salaryDay = 1;

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
      // 1) 고정 수입 저장
      for (final e in _incomes) {
        await repo.createIncome(
          name: e.name,
          amount: e.amount.toDouble(),
          scheduledDay: e.scheduledDay,
        );
      }

      // 2) 고정 지출 저장
      for (final e in _expenses) {
        await repo.createFixedExpense(
          name: e.name,
          amount: e.amount.toDouble(),
          billingDay: e.billingDay,
          paymentMethod: e.paymentMethod,
        );
      }

      // 3) 예산 기준일 저장
      await repo.updateSalaryDay(_salaryDay);

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
    final steps = ['고정 수입', '고정 지출', '예산 기준일'];

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
                  _Step2(
                    incomes: _incomes,
                    onChanged: () => setState(() {}),
                  ),
                  _Step3(
                    expenses: _expenses,
                    onChanged: () => setState(() {}),
                  ),
                  _Step4(
                    salaryDay: _salaryDay,
                    onChanged: (v) => setState(() => _salaryDay = v),
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

// ── Step 1: 고정 수입 ──────────────────────────────────────

class _IncomeEntry {
  _IncomeEntry({required this.name, required this.amount, required this.scheduledDay});
  String name;
  int amount;
  int scheduledDay;
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
    await AppBottomSheet.show(
      context,
      title: '고정 수입 추가',
      child: _AddIncomeForm(
        onSave: (name, amount, scheduledDay) {
          widget.incomes.add(_IncomeEntry(
            name: name,
            amount: amount,
            scheduledDay: scheduledDay,
          ));
          widget.onChanged();
        },
      ),
    );
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
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.income,
                title: e.name,
                subtitle: null,
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

// ── Step 4: 예산 기준일 ──────────────────────────────────────

class _Step4 extends StatelessWidget {
  const _Step4({required this.salaryDay, required this.onChanged});
  final int salaryDay;
  final ValueChanged<int> onChanged;

  String _cycleRangeLabel(int day) {
    final now = DateTime.now();
    if (day <= 1) {
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      return '${now.month}월 1일 ~ ${now.month}월 ${lastDay}일';
    }
    if (now.day >= day) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      return '${now.month}월 ${day}일 ~ ${nextMonth}월 ${day - 1}일';
    } else {
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      return '${prevMonth}월 ${day}일 ~ ${now.month}월 ${day - 1}일';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final rangeLabel = _cycleRangeLabel(salaryDay);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('예산은 언제부터\n시작할까요?',
              style: tt.headlineMedium?.copyWith(height: 1.3))
              .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppSpacing.sm),
          Text('월급날이나 카드 결제일 등 돈 흐름이\n시작되는 날짜를 기준일로 설정하세요.',
              style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary))
              .animate().fadeIn(delay: 200.ms),

          const SizedBox(height: AppSpacing.xl),

          // 설명 카드
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.calendar_month_rounded,
                  iconColor: AppColors.primary,
                  title: '예산 사이클',
                  desc: '기준일부터 다음 달 기준일 전날까지 한 사이클이에요.',
                ),
                const Divider(height: AppSpacing.lg),
                _InfoRow(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.income,
                  title: '사용 가능 예산',
                  desc: '수입에서 고정 지출·실제 지출을 뺀 금액이에요.',
                ),
                const Divider(height: AppSpacing.lg),
                _InfoRow(
                  icon: Icons.swap_horiz_rounded,
                  iconColor: AppColors.expensePending,
                  title: '언제든 변경 가능',
                  desc: '설정에서 언제든 바꿀 수 있어요.',
                ),
              ],
            ),
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: AppSpacing.lg),

          // 현재 사이클 미리보기
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
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
                  style: tt.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: AppSpacing.md),

          // 날짜 그리드
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: List.generate(28, (i) {
              final day = i + 1;
              final isSelected = day == salaryDay;
              return GestureDetector(
                onTap: () => onChanged(day),
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
                    style: tt.bodySmall?.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(desc,
                  style: tt.bodySmall?.copyWith(
                      color: AppColors.textSecondary, height: 1.4)),
            ],
          ),
        ),
      ],
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

// ── 고정 수입 추가 폼 ─────────────────────────────────────────

class _AddIncomeForm extends StatefulWidget {
  const _AddIncomeForm({required this.onSave});
  final void Function(String name, int amount, int scheduledDay) onSave;

  @override
  State<_AddIncomeForm> createState() => _AddIncomeFormState();
}

class _AddIncomeFormState extends State<_AddIncomeForm> {
  final _nameCtrl = TextEditingController();
  int _amount = 0;
  int? _scheduledDay;

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      _amount > 0 &&
      _scheduledDay != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _nameCtrl,
          label: '이름',
          hint: '월급, 부업, 임대료 등',
          autofocus: true,
        ),
        const SizedBox(height: AppSpacing.md),
        AmountTextField(
          label: '예상 금액',
          onChanged: (v) => setState(() => _amount = v),
        ),
        const SizedBox(height: AppSpacing.md),
        _InlineDayPicker(
          label: '받는 날',
          value: _scheduledDay,
          onChanged: (v) => setState(() => _scheduledDay = v),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: _canSave
              ? () {
                  widget.onSave(
                    _nameCtrl.text.trim(),
                    _amount,
                    _scheduledDay!,
                  );
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.income,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.income.withValues(alpha: 0.35),
            disabledForegroundColor: Colors.white70,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
                borderRadius: AppRadius.buttonBorderRadius),
          ),
          child: Text('추가', style: tt.labelLarge),
        ),
      ],
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
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
  }

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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
          AppSpacing.xl + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
