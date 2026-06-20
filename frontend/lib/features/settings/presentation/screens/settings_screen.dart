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
    final settingAsync = ref.watch(userSettingProvider);

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

          // ── 급여 설정
          SliverToBoxAdapter(child: _SectionHeader('급여')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: settingAsync.when(
                  data: (s) => Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.payments_rounded,
                        iconColor: AppColors.income,
                        label: '월급날',
                        value: s.salaryDay == 0 ? '없음' : '매월 ${s.salaryDay}일',
                        onTap: () async {
                          final repo = ref.read(settingsRepositoryProvider);
                          await AppBottomSheet.show(
                            context,
                            title: '월급날 설정',
                            child: _SalaryDayPicker(
                              initialDay: s.salaryDay,
                              onSave: (day) async {
                                await repo.patchSetting({'salary_day': day});
                                ref.invalidate(userSettingProvider);
                              },
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 52),
                      _SettingsTile(
                        icon: Icons.weekend_rounded,
                        iconColor: AppColors.expensePending,
                        label: '주말/공휴일 지급',
                        value: _paydayLabel(s.paydayAdjustment),
                        onTap: () async {
                          final repo = ref.read(settingsRepositoryProvider);
                          await AppBottomSheet.show(
                            context,
                            title: '주말/공휴일 지급 방식',
                            child: _PaydayAdjustmentPicker(
                              initial: s.paydayAdjustment,
                              onSave: (v) async {
                                await repo.patchSetting({'payday_adjustment': v});
                                ref.invalidate(userSettingProvider);
                              },
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 52),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            const SizedBox(width: 44),
                            const Icon(Icons.info_outline_rounded,
                                size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              '예산 기간은 매월 1일 ~ 말일로 고정돼요',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const _ErrorTile(),
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

  String _paydayLabel(String v) => switch (v) {
        'prev_business' => '이전 영업일',
        'next_business' => '다음 영업일',
        'exact' => '당일 그대로',
        _ => v,
      };
}

// ── 공용 서브 위젯 ─────────────────────────────────────────────

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


class _ErrorTile extends StatelessWidget {
  const _ErrorTile();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text('불러오기 실패',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.expense)),
      );
}

// ── 월급날 피커 ───────────────────────────────────────────────

class _SalaryDayPicker extends StatefulWidget {
  const _SalaryDayPicker({required this.initialDay, required this.onSave});
  final int initialDay;
  final Future<void> Function(int day) onSave;

  @override
  State<_SalaryDayPicker> createState() => _SalaryDayPickerState();
}

class _SalaryDayPickerState extends State<_SalaryDayPicker> {
  late int _selected;
  bool _noSalary = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _noSalary = widget.initialDay == 0;
    _selected = _noSalary ? 21 : widget.initialDay;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 월급 없음 토글
        GestureDetector(
          onTap: () => setState(() => _noSalary = !_noSalary),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: _noSalary
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : const Color(0x0A000000),
              borderRadius: AppRadius.buttonBorderRadius,
              border: Border.all(
                color: _noSalary ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _noSalary
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 20,
                  color: _noSalary ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('월급을 받지 않아요 (프리랜서 / 사업자 등)',
                    style: tt.bodyMedium?.copyWith(
                      color: _noSalary ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: _noSalary ? FontWeight.w600 : FontWeight.w400,
                    )),
              ],
            ),
          ),
        ),

        if (!_noSalary) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('지급일 선택',
              style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1,
            ),
            itemCount: 28,
            itemBuilder: (_, i) {
              final day = i + 1;
              final isSel = day == _selected;
              return GestureDetector(
                onTap: () => setState(() => _selected = day),
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
                      fontWeight:
                          isSel ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    await widget.onSave(_noSalary ? 0 : _selected);
                    if (context.mounted) Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
                    _noSalary ? '월급 없음으로 설정' : '매월 $_selected일로 설정',
                    style: tt.labelLarge,
                  ),
          ),
        ),
      ],
    );
  }
}
// ── 주말 지급 방식 피커 ────────────────────────────────────────

class _PaydayAdjustmentPicker extends StatefulWidget {
  const _PaydayAdjustmentPicker(
      {required this.initial, required this.onSave});
  final String initial;
  final Future<void> Function(String v) onSave;

  @override
  State<_PaydayAdjustmentPicker> createState() =>
      _PaydayAdjustmentPickerState();
}

class _PaydayAdjustmentPickerState extends State<_PaydayAdjustmentPicker> {
  late String _selected;
  bool _saving = false;

  static const _options = [
    ('prev_business', '이전 영업일', '주말/공휴일이면 그 이전 평일에 지급', Icons.arrow_back_rounded),
    ('next_business', '다음 영업일', '주말/공휴일이면 그 다음 평일에 지급', Icons.arrow_forward_rounded),
    ('exact', '당일 그대로', '주말/공휴일에도 해당 날짜 그대로 처리', Icons.remove_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._options.map((opt) {
          final (val, label, desc, icon) = opt;
          final isSel = val == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSel
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : const Color(0x0A000000),
                borderRadius: AppRadius.buttonBorderRadius,
                border: Border.all(
                    color: isSel ? AppColors.primary : AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon,
                        size: 18,
                        color: isSel
                            ? AppColors.primary
                            : AppColors.textSecondary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSel ? AppColors.primary : null,
                            )),
                        Text(desc,
                            style: tt.labelSmall?.copyWith(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (isSel)
                    const Icon(Icons.check_rounded,
                        size: 18, color: AppColors.primary),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    await widget.onSave(_selected);
                    if (context.mounted) Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
                : Text('저장', style: tt.labelLarge),
          ),
        ),
      ],
    );
  }
}

