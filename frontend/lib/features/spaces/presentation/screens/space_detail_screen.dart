import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/collapsible_category_picker.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../domain/space_model.dart';
import '../providers/space_provider.dart';
import '../providers/space_schedule_provider.dart';

/// Space의 고정수입/고정지출을 관리하는 화면.
/// 개인 공간의 고정수입/고정지출 추가 폼과 동일한 반복 유형·날짜/요일 선택·카테고리
/// 선택을 지원하되, 수정 없이 추가/삭제만 가능한 간소화 버전.
class SpaceDetailScreen extends ConsumerWidget {
  const SpaceDetailScreen({super.key, required this.space});
  final SpaceModel space;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final fmt = NumberFormat('#,###');
    final incomesAsync = ref.watch(spaceFixedIncomesProvider(space.id));
    final expensesAsync = ref.watch(spaceFixedExpensesProvider(space.id));

    return GradientBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('${space.name} 관리', style: tt.headlineMedium),
                  ],
                ).animate().fadeIn(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('고정 수입', style: tt.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    incomesAsync.when(
                      data: (items) => _ScheduleCard(
                        items: items
                            .map((i) => _ScheduleRowData(
                                  id: i.id,
                                  name: i.name,
                                  amount: i.expectedAmount,
                                  frequency: i.frequency,
                                  day: i.scheduledDay,
                                  dayOfWeek: i.dayOfWeek,
                                  isIncome: true,
                                ))
                            .toList(),
                        fmt: fmt,
                        emptyIcon: Icons.trending_up_rounded,
                        emptyText: '등록된 고정 수입이 없어요',
                        addLabel: '고정 수입 추가',
                        addColor: AppColors.income,
                        onAdd: () => _showAddIncomeSheet(context, ref),
                        onDelete: (id) async {
                          await ref.read(spaceScheduleRepositoryProvider).deleteIncome(space.id, id);
                          ref.invalidate(spaceFixedIncomesProvider(space.id));
                        },
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Text('오류: $e'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('고정 지출', style: tt.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    expensesAsync.when(
                      data: (items) => _ScheduleCard(
                        items: items
                            .map((e) => _ScheduleRowData(
                                  id: e.id,
                                  name: e.name,
                                  amount: e.amount,
                                  frequency: e.frequency,
                                  day: e.billingDay,
                                  dayOfWeek: e.dayOfWeek,
                                  isIncome: false,
                                ))
                            .toList(),
                        fmt: fmt,
                        emptyIcon: Icons.receipt_long_outlined,
                        emptyText: '등록된 고정 지출이 없어요',
                        addLabel: '고정 지출 추가',
                        addColor: AppColors.expense,
                        onAdd: () => _showAddExpenseSheet(context, ref),
                        onDelete: (id) async {
                          await ref.read(spaceScheduleRepositoryProvider).deleteFixedExpense(space.id, id);
                          ref.invalidate(spaceFixedExpensesProvider(space.id));
                        },
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Text('오류: $e'),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    ));
  }

  Future<void> _showAddIncomeSheet(BuildContext context, WidgetRef ref) async {
    final result = await AppBottomSheet.show<_ScheduleFormResult>(
      context,
      title: '고정 수입 추가',
      child: _ScheduleForm(spaceId: space.id, color: AppColors.income),
    );
    if (result == null) return;
    await ref.read(spaceScheduleRepositoryProvider).createIncome(
          space.id,
          name: result.name,
          amount: result.amount,
          frequency: result.frequency,
          scheduledDay: result.scheduledDay,
          dayOfWeek: result.dayOfWeek,
          categoryId: result.categoryId,
        );
    ref.invalidate(spaceFixedIncomesProvider(space.id));
  }

  Future<void> _showAddExpenseSheet(BuildContext context, WidgetRef ref) async {
    final result = await AppBottomSheet.show<_ScheduleFormResult>(
      context,
      title: '고정 지출 추가',
      child: _ScheduleForm(spaceId: space.id, color: AppColors.expense),
    );
    if (result == null) return;
    await ref.read(spaceScheduleRepositoryProvider).createFixedExpense(
          space.id,
          name: result.name,
          amount: result.amount,
          frequency: result.frequency,
          billingDay: result.scheduledDay,
          dayOfWeek: result.dayOfWeek,
          categoryId: result.categoryId,
        );
    ref.invalidate(spaceFixedExpensesProvider(space.id));
  }
}

class _ScheduleRowData {
  const _ScheduleRowData({
    required this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.day,
    required this.dayOfWeek,
    required this.isIncome,
  });

  final int id;
  final String name;
  final double amount;
  final String frequency;
  final int? day;
  final int? dayOfWeek;
  final bool isIncome;
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.items,
    required this.fmt,
    required this.emptyIcon,
    required this.emptyText,
    required this.addLabel,
    required this.addColor,
    required this.onAdd,
    required this.onDelete,
  });

  final List<_ScheduleRowData> items;
  final NumberFormat fmt;
  final IconData emptyIcon;
  final String emptyText;
  final String addLabel;
  final Color addColor;
  final VoidCallback onAdd;
  final Future<void> Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xxl),
              child: Column(
                children: [
                  Icon(emptyIcon, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: AppSpacing.md),
                  Text(emptyText,
                      style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            )
          else
            ...items.map((item) => Column(
                  children: [
                    _ScheduleRow(
                      item: item,
                      fmt: fmt,
                      onDelete: () => onDelete(item.id),
                    ),
                    if (item != items.last)
                      const Divider(height: 1, indent: 52),
                  ],
                )),
          const Divider(height: 1),
          _AddRow(label: addLabel, color: addColor, onTap: onAdd),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.item,
    required this.fmt,
    required this.onDelete,
  });

  final _ScheduleRowData item;
  final NumberFormat fmt;
  final VoidCallback onDelete;

  static const _dowLabels = ['월', '화', '수', '목', '금', '토', '일'];

  String get _scheduleLabel {
    final dow = item.dayOfWeek;
    final day = item.day;
    return switch (item.frequency) {
      'weekly'   => '매주 ${dow != null ? _dowLabels[dow] : '?'}요일',
      'biweekly' => '격주 ${dow != null ? _dowLabels[dow] : '?'}요일',
      'daily'    => '매일',
      _          => day != null ? (day >= 31 ? '매월 말일' : '매월 $day일') : '매월',
    };
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = item.isIncome ? AppColors.income : AppColors.expense;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.isIncome ? Icons.trending_up_rounded : Icons.repeat_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                Text(_scheduleLabel,
                    style: tt.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '${item.isIncome ? '+' : '-'}${fmt.format(item.amount.round())}원',
            style: tt.bodyMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textSecondary),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow(
      {required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add_rounded, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ScheduleFormResult {
  const _ScheduleFormResult({
    required this.name,
    required this.amount,
    required this.frequency,
    this.scheduledDay,
    this.dayOfWeek,
    this.categoryId,
  });
  final String name;
  final double amount;
  final String frequency;
  final int? scheduledDay;
  final int? dayOfWeek;
  final int? categoryId;
}

class _ScheduleForm extends ConsumerStatefulWidget {
  const _ScheduleForm({required this.spaceId, required this.color});
  final int spaceId;
  final Color color;

  @override
  ConsumerState<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends ConsumerState<_ScheduleForm> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  int _amount = 0;
  String _frequency = 'monthly';
  int? _scheduledDay;
  int? _dayOfWeek;
  int? _categoryId;
  bool _showCategoryPicker = false;
  bool _showDayPicker = false;

  static const _frequencies = [
    ('monthly',  '매월'),
    ('weekly',   '매주'),
    ('biweekly', '격주'),
    ('daily',    '매일'),
  ];

  bool get _canSave {
    if (_nameCtrl.text.trim().isEmpty || _amount <= 0) return false;
    if (_frequency == 'monthly' && _scheduledDay == null) return false;
    if ((_frequency == 'weekly' || _frequency == 'biweekly') && _dayOfWeek == null) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_ScheduleFormResult(
      name: _nameCtrl.text.trim(),
      amount: _amount.toDouble(),
      frequency: _frequency,
      scheduledDay: _scheduledDay,
      dayOfWeek: _dayOfWeek,
      categoryId: _categoryId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = widget.color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(controller: _nameCtrl, label: '이름', hint: '예: 월세, 구독료', autofocus: true),
        const SizedBox(height: AppSpacing.md),
        AmountTextField(
          label: '금액',
          controller: _amountCtrl,
          onChanged: (v) => setState(() => _amount = v),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── 반복 유형 선택 ──
        Text('반복', style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: _frequencies.map((opt) {
            final (val, label) = opt;
            final isSel = _frequency == val;
            final isLast = val == 'daily';
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _frequency = val;
                  if (val == 'monthly') _dayOfWeek = null;
                  if (val != 'monthly') _scheduledDay = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: isLast ? 0 : AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? color.withValues(alpha: 0.1) : const Color(0x0A000000),
                    borderRadius: AppRadius.buttonBorderRadius,
                    border: Border.all(color: isSel ? color : AppColors.divider),
                  ),
                  child: Center(
                    child: Text(label, style: tt.labelMedium?.copyWith(
                      color: isSel ? color : AppColors.textSecondary,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                    )),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── 날짜/요일 피커 ──
        if (_frequency == 'monthly')
          _InlineDayPicker(
            label: '날짜',
            value: _scheduledDay,
            color: color,
            isOpen: _showDayPicker,
            onToggle: () => setState(() {
              _showDayPicker = !_showDayPicker;
              if (_showDayPicker) _showCategoryPicker = false;
            }),
            onChanged: (v) => setState(() => _scheduledDay = v),
          )
        else if (_frequency == 'weekly' || _frequency == 'biweekly')
          _DowPicker(
            label: '요일',
            value: _dayOfWeek,
            color: color,
            onChanged: (v) => setState(() => _dayOfWeek = v),
          ),

        const SizedBox(height: AppSpacing.md),
        ref.watch(spaceCategoryItemsProvider(widget.spaceId)).when(
          data: (items) {
            final selected = items.where((c) => c.id == _categoryId).firstOrNull;
            return CollapsibleCategoryPicker(
              items: items,
              selected: selected,
              expanded: _showCategoryPicker,
              accentColor: color,
              onToggle: () => setState(() {
                _showCategoryPicker = !_showCategoryPicker;
                if (_showCategoryPicker) _showDayPicker = false;
              }),
              onSelected: (c) => setState(() {
                _categoryId = c.id;
                _showCategoryPicker = false;
              }),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: _canSave ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            disabledBackgroundColor: color.withValues(alpha: 0.35),
            disabledForegroundColor: Colors.white70,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
          ),
          child: Text('추가', style: tt.labelLarge),
        ),
      ],
    );
  }
}

// ── 날짜 피커 ──────────────────────────────────────────────────

class _InlineDayPicker extends StatelessWidget {
  const _InlineDayPicker({
    required this.label,
    required this.value,
    required this.color,
    required this.isOpen,
    required this.onToggle,
    required this.onChanged,
  });
  final String label;
  final int? value;
  final Color color;
  final bool isOpen;
  final VoidCallback onToggle;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hasValue = value != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0x0A000000),
        borderRadius: AppRadius.buttonBorderRadius,
        border: Border.all(
            color: isOpen
                ? color
                : hasValue
                    ? color.withValues(alpha: 0.5)
                    : AppColors.divider,
            width: isOpen ? 1.5 : 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    label,
                    style: tt.bodyLarge?.copyWith(
                      color: hasValue
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (hasValue)
                    Text(
                      value == 31 ? '매월 말일' : '매월 ${value}일',
                      style: tt.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
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
                isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: AppSpacing.xs,
                  crossAxisSpacing: AppSpacing.xs,
                  childAspectRatio: 1,
                ),
                itemCount: 31,
                itemBuilder: (_, i) {
                  final day = i + 1;
                  final isSel = day == value;
                  final isLast = day == 31;
                  return GestureDetector(
                    onTap: () {
                      onChanged(day);
                      if (isOpen) onToggle();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSel
                            ? color
                            : color.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isLast ? '말일' : '$day',
                        style: tt.labelSmall?.copyWith(
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                          fontSize: isLast ? 8 : null,
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

// ── 요일 피커 ──────────────────────────────────────────────────

class _DowPicker extends StatelessWidget {
  const _DowPicker({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final Color color;
  final ValueChanged<int?> onChanged;

  static const _labels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: List.generate(7, (i) {
            final isSel = value == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: i < 6 ? AppSpacing.xs : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? color.withValues(alpha: 0.12) : const Color(0x0A000000),
                    borderRadius: AppRadius.buttonBorderRadius,
                    border: Border.all(color: isSel ? color : AppColors.divider),
                  ),
                  child: Center(
                    child: Text(_labels[i], style: tt.labelMedium?.copyWith(
                      color: isSel ? color : AppColors.textSecondary,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                    )),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
