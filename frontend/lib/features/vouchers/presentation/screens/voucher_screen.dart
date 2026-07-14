import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/selection_chip.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../domain/voucher_model.dart';
import '../providers/voucher_provider.dart';

const _voucherColor = Color(0xFFB39DFF); // expensePending 계열 — 선불 자산 성격

class VoucherScreen extends ConsumerWidget {
  const VoucherScreen({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(vouchersProvider);
    ref.invalidate(availableBudgetProvider);
    ref.invalidate(currentCycleTransactionsProvider);
  }

  Future<void> _addVoucher(BuildContext context, WidgetRef ref) async {
    await AppBottomSheet.show<void>(
      context,
      title: '상품권 추가',
      child: _NameForm(
        hint: '예: 온누리상품권, 지역화폐',
        onSave: (name) async {
          await ref.read(voucherRepositoryProvider).create(name: name);
          _refresh(ref);
        },
      ),
    );
  }

  Future<void> _showActions(
      BuildContext context, WidgetRef ref, VoucherModel v) async {
    await AppBottomSheet.show<void>(
      context,
      title: v.name,
      child: _ActionSheet(
        voucher: v,
        onCharge: () async {
          await AppBottomSheet.show<void>(
            context,
            title: '${v.name} 충전',
            child: _ChargeForm(
              onSave: (paid, face, method) async {
                await ref.read(voucherRepositoryProvider).charge(
                      v.id,
                      paidAmount: paid,
                      faceAmount: face,
                      transactionDate: DateTime.now(),
                      paymentMethod: method,
                    );
                _refresh(ref);
              },
            ),
          );
        },
        onRename: () async {
          await AppBottomSheet.show<void>(
            context,
            title: '이름 수정',
            child: _NameForm(
              initial: v.name,
              onSave: (name) async {
                await ref.read(voucherRepositoryProvider).patch(v.id, name: name);
                _refresh(ref);
              },
            ),
          );
        },
        onToggleActive: () async {
          await ref
              .read(voucherRepositoryProvider)
              .patch(v.id, isActive: !v.isActive);
          _refresh(ref);
        },
        onDelete: () async {
          final ok = await AppConfirmDialog.show(
            context,
            title: '상품권 삭제',
            message: '‘${v.name}’을(를) 삭제할까요?\n연결된 충전·사용 내역도 함께 사라집니다.',
            confirmLabel: '삭제',
            isDestructive: true,
          );
          if (ok) {
            await ref.read(voucherRepositoryProvider).delete(v.id);
            _refresh(ref);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final fmt = NumberFormat('#,###');
    final async = ref.watch(vouchersProvider);

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
                        onTap: () => context.pop(),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.arrow_back_rounded,
                              size: 18, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text('상품권', style: tt.headlineMedium),
                    ],
                  ).animate().fadeIn(),
                ),
              ),

              // 안내 문구
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: Text(
                    '충전 시 지불한 금액만큼 예산에서 빠지고, 상품권으로 결제하면 소비 통계에만 반영돼요.',
                    style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: async.when(
                    data: (items) => GlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          if (items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xxl),
                              child: Column(
                                children: [
                                  const Icon(Icons.card_giftcard_rounded,
                                      size: 48, color: AppColors.textSecondary),
                                  const SizedBox(height: AppSpacing.md),
                                  Text('등록된 상품권이 없어요',
                                      textAlign: TextAlign.center,
                                      style: tt.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            )
                          else
                            ...items.map((v) => Column(
                                  children: [
                                    _VoucherRow(
                                      voucher: v,
                                      fmt: fmt,
                                      onTap: () => _showActions(context, ref, v),
                                    ),
                                    if (v != items.last)
                                      const Divider(height: 1, indent: 52),
                                  ],
                                )),
                          const Divider(height: 1),
                          _AddRow(
                            label: '상품권 추가',
                            onTap: () => _addVoucher(context, ref),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Center(child: Text('오류: $e')),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 상품권 행 ─────────────────────────────────────────────────

class _VoucherRow extends StatelessWidget {
  const _VoucherRow({
    required this.voucher,
    required this.fmt,
    required this.onTap,
  });

  final VoucherModel voucher;
  final NumberFormat fmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final active = voucher.isActive;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _voucherColor.withValues(alpha: active ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.card_giftcard_rounded,
                  size: 18,
                  color: active
                      ? _voucherColor
                      : AppColors.textSecondary.withValues(alpha: 0.6)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(voucher.name,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: active ? null : AppColors.textSecondary,
                        )),
                  ),
                  if (!active) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('비활성',
                          style: tt.labelSmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${fmt.format(voucher.balance.round())}원',
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: active ? _voucherColor : AppColors.textSecondary,
                    )),
                Text('잔액',
                    style: tt.labelSmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _voucherColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded,
                  size: 18, color: _voucherColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(label,
                style: tt.bodyMedium?.copyWith(
                    color: _voucherColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── 액션 시트 ─────────────────────────────────────────────────

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({
    required this.voucher,
    required this.onCharge,
    required this.onRename,
    required this.onToggleActive,
    required this.onDelete,
  });

  final VoucherModel voucher;
  final VoidCallback onCharge;
  final VoidCallback onRename;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionTile(
          icon: Icons.add_card_rounded,
          color: _voucherColor,
          label: '충전하기',
          onTap: () {
            Navigator.pop(context);
            onCharge();
          },
        ),
        _ActionTile(
          icon: Icons.edit_rounded,
          color: AppColors.primary,
          label: '이름 수정',
          onTap: () {
            Navigator.pop(context);
            onRename();
          },
        ),
        _ActionTile(
          icon: voucher.isActive
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded,
          color: AppColors.textSecondary,
          label: voucher.isActive ? '비활성화' : '활성화',
          onTap: () {
            Navigator.pop(context);
            onToggleActive();
          },
        ),
        _ActionTile(
          icon: Icons.delete_outline_rounded,
          color: AppColors.expense,
          label: '삭제',
          onTap: () {
            Navigator.pop(context);
            onDelete();
          },
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardBorderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.md),
            Text(label,
                style: tt.bodyMedium?.copyWith(
                    color: color == AppColors.expense ? color : null,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── 이름 입력 폼 (생성/수정 공용) ──────────────────────────────

class _NameForm extends StatefulWidget {
  const _NameForm({this.initial, this.hint, required this.onSave});
  final String? initial;
  final String? hint;
  final Future<void> Function(String name) onSave;

  @override
  State<_NameForm> createState() => _NameFormState();
}

class _NameFormState extends State<_NameForm> {
  late final TextEditingController _ctrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    try {
      await widget.onSave(name);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppConfirmDialog.show(context,
            title: '오류', message: e.toString(), confirmLabel: '확인', cancelLabel: '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _ctrl,
          label: '상품권 이름',
          hint: widget.hint,
          autofocus: true,
        ),
        const SizedBox(height: AppSpacing.xl),
        _SubmitButton(label: '저장', loading: _loading, onPressed: _save),
      ],
    );
  }
}

// ── 충전 폼 ───────────────────────────────────────────────────

class _ChargeForm extends StatefulWidget {
  const _ChargeForm({required this.onSave});
  final Future<void> Function(int paid, int? face, String method) onSave;

  @override
  State<_ChargeForm> createState() => _ChargeFormState();
}

class _ChargeFormState extends State<_ChargeForm> {
  final _paidCtrl = TextEditingController();
  final _faceCtrl = TextEditingController();
  int _paid = 0;
  int _face = 0;
  String _method = 'account';
  bool _loading = false;

  @override
  void dispose() {
    _paidCtrl.dispose();
    _faceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_paid <= 0) {
      _err('지불 금액을 입력해 주세요.');
      return;
    }
    final face = _face > 0 ? _face : null; // 미입력 시 백엔드가 paid와 동일 처리
    setState(() => _loading = true);
    try {
      await widget.onSave(_paid, face, _method);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _err(e.toString());
      }
    }
  }

  void _err(String msg) => AppConfirmDialog.show(context,
      title: '오류', message: msg, confirmLabel: '확인', cancelLabel: '');

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final discount = _face > 0 && _paid > 0 && _face > _paid ? _face - _paid : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AmountTextField(
          label: '지불 금액 (실제 나간 돈)',
          controller: _paidCtrl,
          onChanged: (v) => setState(() => _paid = v),
        ),
        const SizedBox(height: AppSpacing.lg),
        AmountTextField(
          label: '충전 액면가 (할인 시, 선택)',
          controller: _faceCtrl,
          onChanged: (v) => setState(() => _face = v),
        ),
        if (discount > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text('할인 혜택 ${NumberFormat('#,###').format(discount)}원',
                style: tt.labelMedium?.copyWith(
                    color: AppColors.income, fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: AppSpacing.lg),

        Text('결제 수단',
            style: tt.labelMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        SelectionChipGroup<String>(
          items: const ['account', 'cash'],
          labelOf: (m) => m == 'account' ? '계좌' : '현금',
          selected: {_method},
          onSelected: (s) => setState(() => _method = s.first),
        ),
        const SizedBox(height: AppSpacing.xl),

        _SubmitButton(
            label: '충전', loading: _loading, color: _voucherColor, onPressed: _save),
      ],
    );
  }
}

// ── 저장 버튼 ─────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.color = AppColors.primary,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape:
            RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label, style: tt.labelLarge?.copyWith(color: Colors.white)),
    );
  }
}
