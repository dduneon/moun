import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction_models.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../../shared/widgets/category_selector.dart';
import '../../../../shared/widgets/transaction_list.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.read(dioProvider));
});

/// 현재 사이클의 거래 목록 (날짜 범위 기반)
final currentCycleTransactionsProvider =
    FutureProvider<List<TransactionModel>>((ref) async {
  final cycle = await ref.watch(currentCycleProvider.future);
  return ref.read(transactionRepositoryProvider).list(
        startDate: cycle.startDate,
        endDate: cycle.endDate,
      );
});

final transactionItemsProvider =
    FutureProvider<List<TransactionItem>>((ref) async {
  final txns = await ref.watch(currentCycleTransactionsProvider.future);
  final catMap = await ref.watch(categoryMapProvider.future);

  return txns.map((t) {
    final cat = catMap[t.categoryId] ??
        const CategoryItem(
          id: 0,
          label: '기타',
          icon: Icons.more_horiz_rounded,
          color: Color(0xFF9E9E9E),
        );
    return TransactionItem(
      id: t.id,
      name: t.name ?? cat.label,
      amount: t.amount.round(),
      type: t.type,
      date: t.transactionDate,
      category: cat,
      memo: t.memo,
      isFixed: t.isFromFixedSchedule,
    );
  }).toList();
});

final transactionsByDateProvider =
    FutureProvider<Map<DateTime, List<TransactionItem>>>((ref) async {
  final items = await ref.watch(transactionItemsProvider.future);
  final map = <DateTime, List<TransactionItem>>{};
  for (final item in items) {
    final day = DateTime(item.date.year, item.date.month, item.date.day);
    map.putIfAbsent(day, () => []).add(item);
  }
  return map;
});
