import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/space_model.dart';
import '../../domain/space_transaction_model.dart';
import '../../../../shared/widgets/category_selector.dart';
import '../../../../shared/widgets/transaction_list.dart';
import 'space_budget_provider.dart';
import 'space_provider.dart';

/// 현재 선택된 Space의 이번 사이클 거래 목록. 개인 공간이 선택된 경우 빈 목록.
final currentSpaceTransactionsProvider = FutureProvider<List<SpaceTransactionModel>>((ref) async {
  final context = await ref.watch(currentSpaceProvider.future);
  if (context is! SpaceSelected) return [];

  final cycle = await ref.watch(currentSpaceCycleProvider.future);
  if (cycle == null) return [];

  return ref.read(spaceTransactionRepositoryProvider).list(
        context.space.id,
        startDate: cycle.startDate,
        endDate: cycle.endDate,
      );
});

final spaceTransactionItemsProvider = FutureProvider<List<TransactionItem>>((ref) async {
  final context = await ref.watch(currentSpaceProvider.future);
  if (context is! SpaceSelected) return [];

  final txns = await ref.watch(currentSpaceTransactionsProvider.future);
  final catMap = await ref.watch(spaceCategoryMapProvider(context.space.id).future);

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
      date: t.transactionDate,
      category: cat,
      memo: t.memo,
      isFixed: t.isFromFixedSchedule,
    );
  }).toList();
});

final spaceTransactionsByDateProvider =
    FutureProvider<Map<DateTime, List<TransactionItem>>>((ref) async {
  final items = await ref.watch(spaceTransactionItemsProvider.future);
  final map = <DateTime, List<TransactionItem>>{};
  for (final item in items) {
    final day = DateTime(item.date.year, item.date.month, item.date.day);
    map.putIfAbsent(day, () => []).add(item);
  }
  return map;
});
