import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../features/transactions/domain/transaction_models.dart' show TransactionType;
import 'app_bottom_sheet.dart';
import 'category_selector.dart';

// UI 전용 거래 모델 (API 응답을 변환해서 사용)
class TransactionItem {
  TransactionItem({
    required this.id,
    required this.name,
    required this.amount,      // 양수=수입, 음수=지출/저축
    TransactionType? type,
    required this.date,
    required this.category,
    this.isPending = false,    // 청구 예정
    this.isFixed = false,      // 고정 지출/수입 여부
    this.memo,
  }) : type = type ?? (amount > 0 ? TransactionType.income : TransactionType.expense);

  final int id;
  final String name;
  final int amount;
  final TransactionType type;
  final DateTime date;
  final CategoryItem category;
  final bool isPending;
  final bool isFixed;
  final String? memo;

  bool get isIncome => type == TransactionType.income;
  bool get isSaving => type == TransactionType.saving;
}

// 날짜별 거래 목록 바텀시트
class DayTransactionSheet extends StatelessWidget {
  const DayTransactionSheet({
    super.key,
    required this.day,
    required this.transactions,
    this.onEdit,
    this.onDelete,
  });

  final DateTime day;
  final List<TransactionItem> transactions;
  final ValueChanged<TransactionItem>? onEdit;
  final ValueChanged<TransactionItem>? onDelete;

  static Future<void> show(
    BuildContext context, {
    required DateTime day,
    required List<TransactionItem> transactions,
    ValueChanged<TransactionItem>? onEdit,
    ValueChanged<TransactionItem>? onDelete,
  }) {
    return AppBottomSheet.show(
      context,
      child: DayTransactionSheet(
        day: day,
        transactions: transactions,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  static final _dateFmt = DateFormat('M월 d일 EEEE', 'ko');
  static final _amtFmt = NumberFormat('#,###');

  int get _totalIncome =>
      transactions.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
  int get _totalExpense => transactions
      .where((t) => !t.isIncome && !t.isSaving)
      .fold(0, (s, t) => s + t.amount.abs());
  int get _totalSaving =>
      transactions.where((t) => t.isSaving).fold(0, (s, t) => s + t.amount.abs());

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 헤더
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dateFmt.format(day), style: tt.titleLarge),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (_totalIncome > 0) ...[
                      Text(
                        '+${_amtFmt.format(_totalIncome)}원',
                        style: tt.labelMedium?.copyWith(
                          color: AppColors.income,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    if (_totalExpense > 0) ...[
                      Text(
                        '-${_amtFmt.format(_totalExpense)}원',
                        style: tt.labelMedium?.copyWith(
                          color: AppColors.expense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    if (_totalSaving > 0)
                      Text(
                        '저축 ${_amtFmt.format(_totalSaving)}원',
                        style: tt.labelMedium?.copyWith(
                          color: AppColors.saving,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${transactions.length}건',
              style: tt.labelSmall,
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        if (transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 40, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('거래 내역이 없어요', style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
            itemBuilder: (_, i) => _TransactionRow(
              item: transactions[i],
              onEdit: onEdit != null ? () => onEdit!(transactions[i]) : null,
              onDelete: onDelete != null ? () => onDelete!(transactions[i]) : null,
            ),
          ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.item,
    this.onEdit,
    this.onDelete,
  });

  final TransactionItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  static final _amtFmt = NumberFormat('#,###');
  static final _timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onEdit,
      onLongPress: onDelete,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            // 카테고리 아이콘
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

            // 이름 + 메모
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isPending)
                        Container(
                          margin: const EdgeInsets.only(left: AppSpacing.xs),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.expensePending.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '예정',
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.expensePending,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.memo != null
                        ? '${item.category.label} · ${item.memo}'
                        : '${item.category.label} · ${_timeFmt.format(item.date)}',
                    style: tt.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // 금액
            Text(
              item.isIncome
                  ? '+${_amtFmt.format(item.amount)}원'
                  : '-${_amtFmt.format(item.amount.abs())}원',
              style: tt.bodyMedium?.copyWith(
                color: item.isPending
                    ? AppColors.expensePending
                    : item.isIncome
                        ? AppColors.income
                        : item.isSaving
                            ? AppColors.saving
                            : AppColors.expense,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
